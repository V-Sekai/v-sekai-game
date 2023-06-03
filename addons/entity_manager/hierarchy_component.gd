# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# hierarchy_component.gd
# SPDX-License-Identifier: MIT

extends ComponentNode

signal entity_parent_changed

var parent_entity_is_valid: bool = true

var pending_entity_parent_ref: EntityRef = null
var pending_attachment_id: int = 0
var cached_entity_parent: Node = null
var cached_entity_attachment_id: int = 0
var cached_entity_children: Array = []


func get_entity_parent() -> Node:
	return cached_entity_parent


func _cache_entity_parent() -> void:
	var parent: Node = get_entity_node().get_parent()
	if parent and parent.has_method("get_entity"):
		cached_entity_parent = parent.get_entity()
		cached_entity_attachment_id = pending_attachment_id
	else:
		cached_entity_parent = null


func set_pending_parent_entity(p_entity_parent_ref: EntityRef, p_attachment_id: int) -> bool:
	if p_entity_parent_ref != pending_entity_parent_ref or p_attachment_id != pending_attachment_id:
		pending_entity_parent_ref = p_entity_parent_ref
		pending_attachment_id = p_attachment_id

		return true
	else:
		return false


func request_reparent_entity(p_entity_parent_ref: EntityRef, p_attachment_id: int) -> void:
	if set_pending_parent_entity(p_entity_parent_ref, p_attachment_id):
		if is_inside_tree():
			if !EntityManager.reparent_pending.has(entity_node):
				EntityManager.reparent_pending.push_back(entity_node)


func _ready():
	if !Engine.is_editor_hint():
		cache_nodes()

		_cache_entity_parent()
		var entity_parent: Node = get_entity_parent()
		if entity_parent:
			var current_entity_node: Entity = get_entity_node()
			pending_entity_parent_ref = entity_parent.get_entity_ref()
			entity_parent.hierarchy_component_node.cached_entity_children.push_back(current_entity_node)

		entity_parent_changed.emit()


func _enter_tree():
	request_ready()


func _exit_tree() -> void:
	if !Engine.is_editor_hint():
		var entity_parent: Node = get_entity_parent()
		if entity_parent:
			var current_entity_node: Entity = get_entity_node()
			entity_parent.hierarchy_component_node.cached_entity_children.erase(current_entity_node)
