@tool
extends SarPlayerSimulationPlayspaceComponent3D
class_name SarPlayerSimulationFPSTPSXRHybridPlayspaceComponent3D
 
## This class inherits SarPlayerSimulationPlayspaceComponent3D
## with the intention of supporting a hybrid playspace
## which can operate in both first and third-person, as well as
## both XR and non-XR modes.

# The position of the camera base stored from
# the previous physics frame.
var _previous_base_position: Vector3 = Vector3()
# The full transform of the pivot stored from the previous frame.
var _previous_pivot_transform: Transform3D = Transform3D()

# This method will modify parameters in the scene depending on wheter or
# not we are in XR mode and whether we are in first-person mode or third-person
# mode.
func _update_scene_for_current_xr_mode_and_point_of_view() -> void:
	if xr_origin:
		xr_origin.transform = Transform3D()
	
	camera.transform = Transform3D()
	
	if is_xr_enabled():
		XRServer.center_on_hmd(XRServer.RESET_FULL_ROTATION, true)
	else:
		camera_base.transform.origin.y = _get_camera_height()

# Returns an offset to raise the camera by. In non-XR mode, we can derive
# the totality of this from the desired player's eye height, whereas in XR,
# we want this set to the ground so height can be represented by the player's
# physical height.
func _get_camera_height() -> float:
	if is_xr_enabled():
		return 0.0
	else:
		return default_height

func _update_possession_xr_origin_current_status() -> void:
	if simulation.is_possessed():
		xr_origin.current = true
		_update_scene_for_current_xr_mode_and_point_of_view()
	else:
		xr_origin.current = false
			
func _on_vessel_possession_changed(p_soul: SarSoul) -> void:
	super._on_vessel_possession_changed(p_soul)
	_update_possession_xr_origin_current_status()

func _set_default_position_and_rotation() -> void:
	camera_base.global_position = global_position
	
	# Set the default pivot from the entity position.
	camera_pivot_reference_node.global_rotation.y = simulation.get_game_entity_interface().get_game_entity().global_rotation.y - PI
	camera_pivot.global_transform = camera_pivot_reference_node.global_transform
	
	camera_base.transform.origin.y = _get_camera_height()
	
	# Store the previous base and pivot transform data.
	_previous_base_position = camera_base.global_position
	_previous_pivot_transform = camera_pivot.transform
	
# Called when the XR camera has calculated a relative head offset
# from the previous frame.
func _on_internal_camera_offset_calculated(p_vec: Vector3) -> void:
	internal_camera_offset_calculated.emit(p_vec)
	
func _on_teleported() -> void:
	if not Engine.is_editor_hint():
		_set_default_position_and_rotation()
		_update_possession_xr_origin_current_status()
		
		reset_physics_interpolation()
		
	teleport.emit()

# Only processed on multiplayer authority.
func _physics_process(p_delta: float) -> void:
	if camera.current:
		camera_pivot_reference_node.rotate_y(-turn_velocity.x * view_sensitivity.x * p_delta)
		
		if is_xr_enabled():
			# Disable pitch when in XR
			turn_velocity.y = 0.0
			camera_pivot_reference_node.rotation.x = 0.0
		else:
			# Optionally clamp the pitch in flat mode.
			camera_pivot_reference_node.rotation.x = clamp(camera_pivot_reference_node.rotation.x + (-turn_velocity.y * view_sensitivity.y * p_delta), deg_to_rad(minimum_pitch), deg_to_rad(maximum_pitch))
			camera_pivot.transform = camera_pivot_reference_node.transform
			
		# Store the base position so we can manually interpolate
		# over the next frames. Built-in interpolation does not
		# currently work well in XR.
		_previous_base_position = global_position
		# Same with the pivot transform.
		_previous_pivot_transform = camera_pivot.transform


func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		assert(camera_base.top_level)
		
		if is_xr_enabled():
			# If we're in XR mode, disable the interpolation on the camera base.
			physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF 
			if xr_use_physics_interpolation:
				# Instead, manually interpolate the position since built-in
				# interpolation does not currently work well with XR and mirrors.
				camera_base.global_position = _previous_base_position.lerp(global_position, Engine.get_physics_interpolation_fraction())
				camera_pivot.transform = _previous_pivot_transform.interpolate_with(camera_pivot_reference_node.transform, Engine.get_physics_interpolation_fraction())
			else:
				# If we have physics interpolation disabled, just copy the
				# position and transform directly.
				camera_base.global_position = global_position
				camera_pivot.transform = camera_pivot_reference_node.transform
		else:
			# If we're not in XR mode, we can just fall back to engine interpolation since
			# it will be more performant anyway (not needing to perform the expensive
			# pivot anchor calculations between physics frames for example).
			physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_INHERIT
			camera_base.global_position = global_position
			
		camera_base.global_position.y += _get_camera_height()
	
func _ready() -> void:
	super._ready()
	
	if not Engine.is_editor_hint():
		_set_default_position_and_rotation()
		_update_possession_xr_origin_current_status()
	else:
		# Remove the top-level behaviour if we're not editing.
		if camera_base:
			if not camera_base.is_part_of_edited_scene():
				camera_base.top_level = false
				camera_base.transform = Transform3D()
				
		set_physics_process(false)

###

## Emitted when an XROrigin offset relative to the previous frame
## is calculated.
signal internal_camera_offset_calculated(p_vec: Vector3)

## Emitted when the container has received an offset calculated
## from the physics integration step.
signal external_camera_offset_received(p_vec: Vector3)

## Emitted when the container has received a request to teleport the
## player entity.
signal teleport()

## Cached project setting for whether we should use custom physics interpolation
## when operating in XR mode. The reason we need our own physics interpolation
## is that while we want to interpolate movement derived from controller input,
## movement derived from headset offset should NOT be interpolated. It should
## be immediate or you will have the perception of strange drift.
@onready var xr_use_physics_interpolation: bool = ProjectSettings.get("physics/common/physics_interpolation")

## The XROrigin node associated with this container.
@export var xr_origin: SarPlayerSimulationXROrigin3D = null

## The camera base node associated with this playspace.
## It should be top-level and will follow the global position of
## this playspace.
@export var camera_base: Node3D = null
## The pivot node responsible for handling rotation received from
## the input system.
@export var camera_pivot: SarAnchorPivot3D = null
## The node responsible for applying an offset the XROrigin
## playspace.
@export var camera_offset: Node3D = null

## The node that pivot node should use as a target for the
## actual pivot node which will be used for interpolation.
## The interpolation will be calculated via local transform,
## so it should be placed as a sibling of the actual pivot node.
@export var camera_pivot_reference_node: Node3D = null

## The default player height.
@export var default_height: float = 0.0

@export_category("Pitch")
## The maximum pitch (in degrees) which the camera is permitted to rotate.
@export_range(0.0, 90.0, 1.0, "degrees") var maximum_pitch: float = 90.0
## The minimum pitch (in degrees) which the camera is permitted to rotate.
@export_range(-90.0, 0.0, 1.0, "degrees") var minimum_pitch: float = -90.0

@export_category("Input")
## The turn sensitivity for the camera on the X and Y axis.
## Set negative values to provide inverted look direction.
@export var view_sensitivity: Vector2 = Vector2(10.0, 10.0)
## The input velocity that we should turn the camera by.
@export var turn_velocity: Vector2 = Vector2()

## Returns [true] if we're running in XR mode.
func is_xr_enabled() -> bool:
	return XRServer.primary_interface != null

## Returns the yaw rotation derived from a combination of the camera's yaw and
## the reference pivot's yaw.
func get_yaw_rotation() -> float:
	return super.get_yaw_rotation() + camera_pivot_reference_node.rotation.y - PI

## This method is called when the additional entity offset is calculated
## from the simulation space. The offset is intended to be positional
## delta calculated from the velocity pass which was calculated
## by comparing the xz position of the players head in XR space.
func apply_external_camera_offset(p_offset: Vector3) -> void:
	# Apply the offset to the base position from the previous frame
	# since delta acquired from the head offset is something we
	# definitely DON'T want to interpolate.
	_previous_base_position += p_offset
	
	# Now emit the signal so the offset node can handle repositioning
	# the XR space to compensate for the offset.
	external_camera_offset_received.emit(p_offset)
