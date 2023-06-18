# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# actor_controller.gd
# SPDX-License-Identifier: MIT

@tool
extends "res://addons/actor/movement_controller.gd"  # movement_controller.gd

const state_machine_const = preload("res://addons/actor/actor_state_machine.gd")

@export var _state_machine_path: NodePath = NodePath()
var _state_machine: Node = null  # state_machine_const

# Render
@export var _third_person_render_node_path: NodePath = NodePath()
var _third_person_render_node: Node = null

# Vector fed into the kinematic movement
var velocity: Vector3 = Vector3():
	set = set_velocity,
	get = get_velocity


func set_velocity(p_velocity: Vector3) -> void:
	velocity = p_velocity


func get_velocity() -> Vector3:
	return velocity


@export var sprint_speed: float = 10.0:
	set = set_sprint_speed,
	get = get_sprint_speed

@export var walk_speed: float = 5.0:
	set = set_walk_speed,
	get = get_walk_speed

@export var fly_speed: float = 10.0:
	set = set_fly_speed,
	get = get_fly_speed


func set_sprint_speed(p_speed: float) -> void:
	sprint_speed = p_speed


func get_sprint_speed() -> float:
	return sprint_speed


func set_walk_speed(p_speed: float) -> void:
	walk_speed = p_speed


func get_walk_speed() -> float:
	return walk_speed


func set_fly_speed(p_speed: float) -> void:
	fly_speed = p_speed


func get_fly_speed() -> float:
	return fly_speed


@export var _render_node_path: NodePath = NodePath()
var _render_node: Node3D = null


func cache_nodes() -> void:
	super.cache_nodes()

	_render_node = get_node_or_null(_render_node_path)
	if _render_node == self or not _render_node is Node3D:
		_render_node = null

	_state_machine = get_node_or_null(_state_machine_path)
	if _state_machine == self:
		_state_machine = null


func _entity_ready() -> void:
	super._entity_ready()

	_third_person_render_node = get_node_or_null(_third_person_render_node_path)
	_third_person_render_node.show()


func _on_transform_changed() -> void:
	super._on_transform_changed()
