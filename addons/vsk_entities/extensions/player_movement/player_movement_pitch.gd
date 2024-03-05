# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# player_movement_pitch.gd
# SPDX-License-Identifier: MIT

extends "player_movement_provider.gd"

@export var mouse_sensitivity = 1.0

var _camera_tilt: float = 0.0
var _vertical_input: float = 0.0

func execute(p_movement_controller: Node, p_delta: float) -> bool:
	if !super.execute(p_movement_controller, p_delta):
		return false
		
	if not get_viewport().is_using_xr():
		var v_rot_offset: float = _vertical_input * p_delta
	
		_camera_tilt += v_rot_offset
		_camera_tilt = clamp(_camera_tilt, deg_to_rad(-90), deg_to_rad(90))
		
		get_xr_camera(p_movement_controller).basis = Basis().rotated(Vector3.RIGHT, _camera_tilt)

	# Reset the input
	_vertical_input = 0.0
	
	return true
	
func _input(p_event: InputEvent) -> void:
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if p_event is InputEventMouseMotion:
			_vertical_input -= p_event.relative.y * mouse_sensitivity
