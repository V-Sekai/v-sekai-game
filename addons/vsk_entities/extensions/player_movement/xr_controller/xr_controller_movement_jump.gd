extends "xr_controller_movement_provider.gd"

const player_movement_jump_const = preload("../player_movement_jump.gd")

var _movement_jump_node: Node

func _button_pressed(p_action: String) -> void:
	#if p_action != "trigger_click" and p_action != "trigger_touch" and p_action != "by_button" and p_action != "by_touch" and p_action != "ax_button" and p_action != "ax_touch":
	if p_action == "jump":
		_movement_jump_node.request_jump()

# Perform jump movement
func _ready():
	super._ready()
	
	assert(_controller.button_pressed.connect(_button_pressed) == OK)
	assert(_player_movement_controller)
	for child in _player_movement_controller.get_children():
		if child is player_movement_jump_const:
			_movement_jump_node = child
