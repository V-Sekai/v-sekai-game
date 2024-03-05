# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# xr_controller_movement_direct.gd
# SPDX-License-Identifier: MIT

extends "xr_controller_movement_provider.gd"

const player_movement_direct_const = preload("../player_movement_direct.gd")

##
## Input action for movement direction
##
@export var input_action : String = "primary"

var _direct_movement_node: Node = null

func _process(_delta: float) -> void:
	if !_controller.get_is_active():
		return
		
	var overall_rotation: float = _origin.transform.basis.get_euler().y + _origin.xr_camera.transform.basis.get_euler().y
	var input: Vector2 = Vector2()
	
	input.y =- _controller.get_vector2(input_action).y
	input.x = _controller.get_vector2(input_action).x

	input = input.normalized()
	
	var rotated_input = Vector2(
	input.y * sin(overall_rotation) + input.x * cos(overall_rotation),
	input.y * cos(overall_rotation) + input.x * -sin(overall_rotation))

	_direct_movement_node.input = rotated_input

func _ready():
	super._ready()
	
	assert(_player_movement_controller)

	for child in _player_movement_controller.get_children():
		if child is player_movement_direct_const:
			_direct_movement_node = child
