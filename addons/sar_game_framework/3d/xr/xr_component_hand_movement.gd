extends Node
class_name SarXRComponentHandMovement

const DEADZONE: float = 0.2
var previous_movement: Vector2 = Vector2()

func _process(_delta: float) -> void:
	var movement: Vector2 = Vector2()
	
	var controller: XRController3D = get_parent()
	if controller:
		if controller.get_is_active():
			movement = controller.get_vector2("move")

	if movement.y > DEADZONE:
		var forward_event = InputEventAction.new()
		forward_event.action = "move_forwards"
		forward_event.strength = abs(movement.y)
		forward_event.pressed = true
		Input.parse_input_event(forward_event)
	else:
		if previous_movement.y > DEADZONE:
			var forwards_event = InputEventAction.new()
			forwards_event.action = "move_forwards"
			forwards_event.pressed = false
			Input.parse_input_event(forwards_event)
			
	if movement.y < -DEADZONE:
		var backwards_events = InputEventAction.new()
		backwards_events.action = "move_backwards"
		backwards_events.strength = abs(movement.y)
		backwards_events.pressed = true
		Input.parse_input_event(backwards_events)
	else:
		if previous_movement.y < -DEADZONE:
			var backwards_event = InputEventAction.new()
			backwards_event.action = "move_backwards"
			backwards_event.pressed = false
			Input.parse_input_event(backwards_event)
			
	if movement.x > DEADZONE:
		var right_event = InputEventAction.new()
		right_event.action = "move_right"
		right_event.strength = abs(movement.x)
		right_event.pressed = true
		Input.parse_input_event(right_event)
	else:
		if previous_movement.x > DEADZONE:
			var right_event = InputEventAction.new()
			right_event.action = "move_right"
			right_event.pressed = false
			Input.parse_input_event(right_event)
			
	if movement.x < -DEADZONE:
		var left_event = InputEventAction.new()
		left_event.action = "move_left"
		left_event.strength = abs(movement.x)
		left_event.pressed = true
		Input.parse_input_event(left_event)
	else:
		if previous_movement.x < -DEADZONE:
			var left_event = InputEventAction.new()
			left_event.action = "move_left"
			left_event.pressed = false
			Input.parse_input_event(left_event)
			
	previous_movement = movement
