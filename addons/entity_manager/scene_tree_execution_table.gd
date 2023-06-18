# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# scene_tree_execution_table.gd
# SPDX-License-Identifier: MIT

@tool
extends RefCounted

const runtime_entity_const = preload("res://addons/entity_manager/runtime_entity.gd")
const mutex_lock_const = preload("res://addons/gd_util/mutex_lock.gd")

#
const ADD_ENTITY = 0
const REMOVE_ENTITY = 1

var scene_tree_execution_table: Array = []
var _scene_tree_table_mutex: Mutex = Mutex.new()

var root_node: Node = null


# Adds an entity to the tree. Called exclusively in the main thread
func _add_entity_instance_unsafe(p_instance: Node) -> void:
	p_instance._entity_about_to_add()

	NetworkLogger.printl("Adding entity: %s" % p_instance.get_name())
	if p_instance.is_inside_tree():
		NetworkLogger.error("Entity is already inside tree!")
	else:
		var pending_entity_parent_ref: EntityRef = p_instance.hierarchy_component_node.pending_entity_parent_ref if p_instance.hierarchy_component_node else null

		if pending_entity_parent_ref:
			var entity: RuntimeEntity = pending_entity_parent_ref._entity
			var attachment_node: Node = entity.get_attachment_node(p_instance.pending_attachment_id)
			attachment_node.add_child(p_instance, true)
		else:
			root_node.add_child(p_instance, true)


# Deletes an entity to the tree. Called exclusively in the main thread
func _remove_entity_instance_unsafe(p_instance: Node) -> void:
	NetworkLogger.printl("Removing entity: %s" % p_instance.get_name())
	EntityManager._delete_entity_unsafe(p_instance)


func copy_and_clear_scene_tree_execution_table() -> Array:
	var _mutex_lock = mutex_lock_const.new(_scene_tree_table_mutex)
	var table: Array = []
	if scene_tree_execution_table.size():
		table = scene_tree_execution_table.duplicate()

	scene_tree_execution_table = []

	return table


# Executes all the add/delete commands. Called exclusively in the main thread
func _execute_scene_tree_execution_table_unsafe():
	var table: Array = copy_and_clear_scene_tree_execution_table()
	for entry in table:
		match entry.command:
			ADD_ENTITY:
				_add_entity_instance_unsafe(entry.instantiate)
			REMOVE_ENTITY:
				_remove_entity_instance_unsafe(entry.instantiate)


# Clears the scene tree execution table. Add entities marked
# scheduled to be added will be queued to be freed
func cancel_scene_tree_execution_table():
	var _mutex_lock = mutex_lock_const.new(_scene_tree_table_mutex)

	for entry in scene_tree_execution_table:
		match entry.command:
			ADD_ENTITY:
				entry.instantiate.queue_free()

	scene_tree_execution_table = []


# Adds a command to add or remove an entity from the scene.
# The commands will later be executed on the scene tree
func scene_tree_execution_command(p_command: int, p_entity_instance: Node):
	var _mutex_lock = mutex_lock_const.new(_scene_tree_table_mutex)

	match p_command:
		ADD_ENTITY:
			NetworkLogger.printl("Scene Tree: Add Entity Command...%s" % p_entity_instance.get_name())
			scene_tree_execution_table.push_front({"command": ADD_ENTITY, "instantiate": p_entity_instance})
		REMOVE_ENTITY:
			NetworkLogger.printl("Scene Tree: Remove Entity Command...%s" % p_entity_instance.get_name())
			(
				scene_tree_execution_table
				. push_front(
					{
						"command": REMOVE_ENTITY,
						"instantiate": p_entity_instance,
					}
				)
			)
