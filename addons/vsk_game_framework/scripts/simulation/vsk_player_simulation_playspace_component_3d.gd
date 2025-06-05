@tool
extends SarPlayerSimulationFPSTPSXRHybridPlayspaceComponent3D
class_name VSKPlayerSimulationPlayspaceComponent3D

## This class inherits
## SarPlayerSimulationFPSTPSXRHybridPlayspaceComponent3D
## with features specific to calculating a camera height
## based on an avatar assigned by the simulation space.

# The avatar we have assigned.
var _avatar: VSKAvatar3D = null

# We overload the _get_camera_height function so that we can derive
# baseline flat mode height from the avatar.
# TODO: For XR, this more involved, with us having to offset based on the 
# calculation between height and wristspan, as well as seated mode,
# custom avatar scale, ect.
func _get_camera_height() -> float:
	if _avatar:
		if is_xr_enabled():
			# TODO: calculate a leg offset based on armspan
			# calculation in conjunction with the eye height.
			return super._get_camera_height()
		else:
			return _avatar.calculate_height_to_head_base()
	else:
		return super._get_camera_height()

func _on_model_changed(p_new_model: SarModel3D) -> void:
	if p_new_model is VSKAvatar3D:
		_avatar = p_new_model
		
	camera_base.transform.origin.y = _get_camera_height()
	
	# Check if the avatar has a unique LookOffset node which
	# we can then use to apply to the camera space's look offset.
	camera_offset.transform.origin = Vector3()
	if _avatar and not is_xr_enabled():
		var look_offset: Node3D = _avatar.get_node_or_null("%LookOffset")
		if look_offset:
			camera_offset.transform.origin.y = look_offset.transform.origin.y

func _ready() -> void:
	super._ready()
	
	if not Engine.is_editor_hint():
		if simulation:
			_avatar = simulation.game_entity_interface.model_component.get_model_node()
