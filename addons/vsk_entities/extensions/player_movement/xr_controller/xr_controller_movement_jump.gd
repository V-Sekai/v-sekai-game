extends "xr_controller_movement_provider.gd"

@export var jump_node: Node

func _button_pressed(p_action: String) -> void:
	if p_action == "jump":
		jump_node.request_jump()

# Perform jump movement
func _ready():
	assert(_controller.button_pressed.connect(_button_pressed) == OK)
