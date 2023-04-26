# res://addons/actor/movement_controller.gd
# This file is part of the V-Sekai Game.
# https://github.com/V-Sekai/actor
#
# Copyright (c) 2018-2022 SaracenOne
# Copyright (c) 2019-2022 K. S. Ernest (iFire) Lee (fire)
# Copyright (c) 2020-2022 Lyuma
# Copyright (c) 2020-2022 MMMaellon
# Copyright (c) 2022 V-Sekai Contributors
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

@tool
extends "res://addons/entity_manager/node_3d_simulation_logic.gd"

const MAX_SLIDE_ATTEMPTS = 4

const controller_helpers_const = preload("res://addons/actor/controller_helpers.gd")

@export var _character_body_path: NodePath = NodePath()
var _character_body: CharacterBody3D = null:
	set = set_character_body,
	get = get_character_body

var motion_vector: Vector3 = Vector3()
var movement_vector: Vector3 = Vector3()  # Movement for this frame


func set_global_origin(p_origin: Vector3, _p_update_physics: bool = false) -> void:
	super.set_global_origin(p_origin, _p_update_physics)
	if _p_update_physics:
		if _character_body and _character_body.is_inside_tree():
			_character_body.global_translate(get_global_origin())


func set_global_transform(p_global_transform: Transform3D, _p_update_physics: bool = false) -> void:
	super.set_global_transform(p_global_transform, _p_update_physics)
	if _p_update_physics:
		if _character_body and _character_body.is_inside_tree():
			_character_body.global_translate(get_global_origin())


func set_character_body(p_character_body: CharacterBody3D) -> void:
	_character_body = p_character_body


func get_character_body() -> CharacterBody3D:
	return _character_body


func set_direction_normal(p_normal: Vector3) -> void:
	if p_normal == Vector3():
		return
	set_global_transform(get_global_transform().looking_at(get_global_origin() + p_normal, Vector3(0, 1, 0)))


func get_direction_normal() -> Vector3:
	return get_global_transform().basis.z


func move(p_target_velocity: Vector3) -> void:
	if _character_body:
		if p_target_velocity.length() > 0.0:
			if _character_body:
				_character_body.velocity = p_target_velocity
				_character_body.move_and_slide()
				motion_vector = _character_body.velocity
			set_global_transform(Transform3D(get_global_transform().basis, _character_body.global_transform.origin))


func set_movement_vector(p_target_velocity: Vector3) -> void:
	movement_vector = p_target_velocity


func is_grounded() -> bool:
	if _character_body:
		return _character_body.is_on_floor()
	else:
		return false


func get_gravity_speed() -> float:
	return 9.8 * 3


func get_gravity_direction() -> Vector3:
	return Vector3(0.0, -1.0, 0.0)


func cache_nodes() -> void:
	super.cache_nodes()

	if has_node(_character_body_path):
		_character_body = get_node_or_null(_character_body_path)

		if _character_body == self or not _character_body is CharacterBody3D:
			_character_body = null


func _entity_ready() -> void:
	super._entity_ready()

	if _character_body:
		_character_body.set_as_top_level(true)
		_character_body.global_transform = Transform3D(Basis(), get_global_transform().origin)
