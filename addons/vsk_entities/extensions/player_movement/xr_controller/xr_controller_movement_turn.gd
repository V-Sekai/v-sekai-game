extends "xr_controller_movement_provider.gd"

## Input action for movement direction
@export var input_action : String = "primary"

@export var turn_movement_node: Node

# Perform jump movement
func _process(_delta: float) -> void:
	if !_controller.get_is_active():
		return

	turn_movement_node.input -= _controller.get_vector2(input_action).x
