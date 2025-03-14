# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# xr_controller_movement_jump.gd
# SPDX-License-Identifier: MIT

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

	if _controller.button_pressed.connect(_button_pressed) != OK:
		push_error(
			"Could not connect signal '_controller.button_pressed' at xr_controller_movement_jump"
		)
		return
	if not _player_movement_controller:
		push_error("Could not find '_player_movement_controller' at xr_controller_movement_jump")
		return
	for child in _player_movement_controller.get_children():
		if child is player_movement_jump_const:
			_movement_jump_node = child
