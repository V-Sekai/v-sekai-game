extends Node
class_name SarXRComponentHandRotation

const DEADZONE: float = 0.2
var previous_rotate: Vector2 = Vector2()

func _process(_delta: float) -> void:
	var rotate: Vector2 = Vector2()
	
	var controller: XRController3D = get_parent()
	if controller:
		if controller.get_is_active():
			rotate = controller.get_vector2("rotate")
	
	if rotate.x > DEADZONE:
		var right_event = InputEventAction.new()
		right_event.action = "rotate_camera_right"
		right_event.strength = abs(rotate.x)
		right_event.pressed = true
		Input.parse_input_event(right_event)
	else:
		if previous_rotate.x > DEADZONE:
			var right_event = InputEventAction.new()
			right_event.action = "rotate_camera_right"
			right_event.pressed = false
			Input.parse_input_event(right_event)
			
	if rotate.x < -DEADZONE:
		var left_event = InputEventAction.new()
		left_event.action = "rotate_camera_left"
		left_event.strength = abs(rotate.x)
		left_event.pressed = true
		Input.parse_input_event(left_event)
	else:
		if previous_rotate.x < -DEADZONE:
			var left_event = InputEventAction.new()
			left_event.action = "rotate_camera_left"
			left_event.pressed = false
			Input.parse_input_event(left_event)
		
	previous_rotate = rotate
