# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# simulation_logic.gd
# SPDX-License-Identifier: MIT

@tool
class_name SimulationLogic extends "res://addons/entity_manager/component_node.gd"  # component_node.gd

# Static value, do not edit at runtimes
@export var _entity_type: String


func get_entity_type() -> String:
	if not _entity_type.is_empty():
		return _entity_type
	else:
		return "Unknown Entity Type"


func _enter_tree() -> void:
	if !Engine.is_editor_hint():
		add_to_group("entity_managed")


func _exit_tree() -> void:
	if !Engine.is_editor_hint():
		remove_from_group("entity_managed")


func _transform_changed() -> void:
	pass


func cache_node(p_node_path: NodePath) -> Node:
	return get_node_or_null(p_node_path)


func get_attachment_id(_attachment_string: String) -> int:
	return -1


func get_attachment_node(_attachment_id: int) -> Node:
	return get_entity_node()


func _entity_parent_changed() -> void:
	pass


##############
# Networking #
##############


func is_entity_master() -> bool:
	if get_tree() and not get_tree().get_multiplayer().has_multiplayer_peer():
		return true
	if is_inside_tree() and is_multiplayer_authority():
		return true
	return false


func _entity_representation_process(_delta: float) -> void:
	pass


func _entity_physics_pre_process(_delta: float) -> void:
	pass


func _entity_physics_process(_delta: float) -> void:
	pass


func _entity_physics_post_process(_delta: float) -> void:
	pass


func _entity_ready() -> void:
	pass


func entity_child_pre_remove(_entity_child: Node) -> void:
	pass


func can_request_master_from_peer(_id: int) -> bool:
	return false


func can_transfer_master_from_session_master(_id: int) -> bool:
	return false
