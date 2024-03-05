# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# player_movement_head_offset.gd
# SPDX-License-Identifier: MIT

extends "player_movement_provider.gd"

@export var _velocity_accumulation = Vector3()
var _previous_camera_position = Vector2()

@export var update_rate: float = 0.1
	
func get_velocity_accumulation() -> Vector3:
	return _velocity_accumulation
	
func get_camera_position_2d(p_movement_controller: Node) -> Vector2:
	var camera_position_2d = Vector2(
		get_xr_camera(p_movement_controller).transform.origin.x,
		get_xr_camera(p_movement_controller).transform.origin.z
	)

	return camera_position_2d

func execute(p_movement_controller: Node, p_delta: float) -> bool:
	if !super.execute(p_movement_controller, p_delta):
		return false
	
	if !get_character_body(p_movement_controller) or !get_xr_origin(p_movement_controller) or !get_xr_camera(p_movement_controller):
		return false
		
	# Store the character body velocity
	var previous_velocity: Vector3 = get_character_body(p_movement_controller).velocity
	
	# Get the xz offset between the camera and character controller
	var camera_position: Vector2 = get_camera_position_2d(p_movement_controller)
	var camera_offset: Vector2 = (
		camera_position - _previous_camera_position).rotated(
			-get_xr_origin(p_movement_controller).basis.get_euler().y)
	
	# The velocity is the inverse of character_camera_offset multipled by physics FPS
	_velocity_accumulation += Vector3(
		camera_offset.x,
		0.0,
		camera_offset.y) * Engine.physics_ticks_per_second

	get_character_body(p_movement_controller).velocity = _velocity_accumulation
	
	var _did_collide: bool = get_character_body(p_movement_controller).move_and_slide()
	var distance_travelled: Vector3 = get_character_body(p_movement_controller).get_position_delta()
	
	# Apply the inverse to the origin
	get_xr_origin(p_movement_controller).transform.origin -= Vector3(
		distance_travelled.x, 0.0, distance_travelled.z)
	_velocity_accumulation -= Vector3(distance_travelled.x, 0.0, distance_travelled.z) * Engine.physics_ticks_per_second
	
	# Save camera position
	_previous_camera_position = camera_position

	# Reset the previous velocity
	get_character_body(p_movement_controller).velocity = previous_velocity
	
	return true
