extends Node
class_name SarXRComponentAction

## This XR component will take an XR input action and
## translate it into a native Godot input action.

## The name of the XR action.
@export var xr_input_action: String = ""
## The name of the native Godot action.
@export var godot_input_action: String = ""

func _button_pressed(p_button: String):
	if p_button == xr_input_action:
		var action_event = InputEventAction.new()
		action_event.action = godot_input_action
		action_event.strength = 1.0
		action_event.pressed = true
		Input.parse_input_event(action_event)
		
func _button_released(p_button: String):
	if p_button == xr_input_action:
		var action_event = InputEventAction.new()
		action_event.action = godot_input_action
		action_event.strength = 1.0
		action_event.pressed = false
		Input.parse_input_event(action_event)
		
func _ready() -> void:
	var controller: XRController3D = get_parent()
	if controller:
		assert(controller.button_pressed.connect(_button_pressed) == OK)
		assert(controller.button_released.connect(_button_released) == OK)
