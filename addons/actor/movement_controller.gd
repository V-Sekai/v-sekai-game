# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# movement_controller.gd
# SPDX-License-Identifier: MIT

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
	return abs(ProjectSettings.get_setting("physics/3d/default_gravity")) * 3.0


func get_gravity_direction() -> Vector3:
	return ProjectSettings.get_setting("physics/3d/default_gravity_vector")


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
