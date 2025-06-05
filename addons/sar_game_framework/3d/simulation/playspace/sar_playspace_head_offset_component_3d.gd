@tool
class_name SarPlayspaceHeadOffsetComponent3D
extends Node

## Helper node designed to live inside a camera container and translate
## horizontal motion from an XRCamera into physical motion for the player
## entity and resolve any difference by shifting the XROrigin around to
## compensate.
##
## This node will calculate the horizontal
## difference of an xr_camera relative to the previous frame
## and storing this as error in _offset_accumulation variable.
## It will then emit a signal containing the accumulated offset
## which can then be passed upwards to the physics integration
## of the entity.
## Once this error has attempted to have been resolved,
## _external_offset_received will then be called with travel calculation
## of the integration phase and removed from the accumulation, repositioning
## the xr_origin to compensate.
## Originally, if all of the offset is removed from the
## accumulator, we then call center_on_hmd on the XRServer to fully
## clear any remaining drift which might have occured. However,
## this has been disabled for now since it causes issues with
## meshes parented to hand controllers.

# Note to self: interpolation in the rotational pivot seems to be making
# the XROrigin offset to accumulate WAY more error from the HeadOffset
# component. I'm not sure why, but it seems to be mostly dealt with by making
# to use the real pivot as the rotational reference rather than the
# target pivot it interpolates towards.

# This appears to solve most of the error, but small amounts of
# deviation still appear, which may be caused by basic floating
# point inprecision in the pivot anchor rotation code.
# This remaining error can seemingly be cleared about by exploiting
# the center_on_hmd API function, which introduced its own issues surrounding
# mesh instances attached to XR nodes.

# The accumulated amount of unresolved error
# between camera and game entity's physics body.
var _offset_accumulation: Vector3 = Vector3()

# The horizontal position of the camera from the previous
# frame.
var _previous_camera_position: Vector2 = Vector2()

# Will edit the _previous_camera_position for external functions
# which modify the XROrigin position.
func _translate_previous_camera_position(p_vec: Vector2) -> void:
	_previous_camera_position -= p_vec

# Returns the X and Z coordinates of the XRCamera
# as a Vector2
func _get_camera_position_2d() -> Vector2:
	return Vector2(
		xr_camera.transform.origin.x,
		xr_camera.transform.origin.z
	)
	
# Calculates the horizontal offset of the camera
# relative to the previous form and emits offset_calculated
# containing the overall accumulated offset.
func _calculate_offset() -> void:
	var camera_position: Vector2 = _get_camera_position_2d()
	var camera_offset: Vector2 = (camera_position - _previous_camera_position).rotated(-pivot.rotation.y)
	
	_offset_accumulation += Vector3(
		camera_offset.x,
		0.0,
		camera_offset.y)

	offset_calculated.emit(_offset_accumulation)
	_previous_camera_position = camera_position

# Called to clear the XROrigin accumulated offset entirely and reset
# the HMD space.
func _reset_space() -> void:
	_offset_accumulation = Vector3()
	
	# Additional check to make sure the XROrigin is current in case we
	# end up in situation where this node is being used by a different soul. 
	# This shouldn't happen, but just to be safe...
	if xr_origin.current:
		xr_origin.transform.origin = Vector3()
		xr_origin.center_on_hmd(XRServer.DONT_RESET_ROTATION, true)
		_previous_camera_position = Vector2()
	
# Callback for when the physics integration has finish
# calculating the integration meant to resolve the offset.
func _external_offset_received(p_vec: Vector3) -> void:
	_offset_accumulation -= p_vec
	xr_origin.translate((-p_vec).rotated(Vector3.UP, -pivot.rotation.y))

	# If we have no offset accumulation left, perform
	# a call to center_on_hmd which should hopefully resolve
	# any precision or drift issues.
	if is_zero_approx(_offset_accumulation.length()):
		_reset_space()

func _physics_process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		if not Engine.is_editor_hint():
			_calculate_offset()
		
func _ready() -> void:
	if not Engine.is_editor_hint():
		_reset_space()

###

## Emitted when the camera offset from the previous
## frame has been calculated.
signal offset_calculated(p_vec: Vector3)

## The pivot node which the playspace is relative to.
@export var pivot: Node3D = null

## The XR camera used to calculate the offset.
@export var xr_camera: XRCamera3D = null

## The XR origin which the xr_camera is a child of.
@export var xr_origin: SarPlayerSimulationXROrigin3D = null
