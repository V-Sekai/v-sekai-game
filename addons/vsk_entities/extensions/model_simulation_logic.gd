# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# model_simulation_logic.gd
# SPDX-License-Identifier: MIT

@tool
extends "res://addons/entity_manager/node_3d_simulation_logic.gd"

# Render
@export var _render_node_path: NodePath = NodePath():
	set = set_render_node_path

var _render_node: Node3D = null

@export var model_scene: PackedScene = null:
	set = set_packed_scene

var model_scene_requires_update: bool = false

var visual_nodes: Array = []
var physics_nodes: Array = []

var visual_node_root: Node3D = null

signal model_loaded


func get_model_path() -> String:
	return VSKResourceManager.get_path_for_entity_resource(model_scene)


func set_model_from_path(p_path: String) -> void:
	if p_path.is_empty():
		return
	model_scene = VSKResourceManager.get_entity_resource_for_path(p_path)
	schedule_model_update()


func update_gizmos(p_node: Node3D) -> void:
	var cur_entity_node: Node = get_entity_node()
	if cur_entity_node:
		if cur_entity_node.owner == null:
			cur_entity_node = null

	p_node.set_owner(cur_entity_node)
	for child in p_node.get_children():
		update_gizmos(child)


func set_render_node_path(p_node_path: NodePath) -> void:
	if _render_node_path != p_node_path:
		_render_node_path = p_node_path
		schedule_model_update()


func set_packed_scene(p_model_scene: PackedScene) -> void:
	if p_model_scene != model_scene:
		model_scene = p_model_scene
		schedule_model_update()


func _delete_previous_model_nodes() -> void:
	if visual_node_root:
		visual_node_root.queue_free()
		if visual_node_root.is_inside_tree():
			visual_node_root.get_parent().remove_child(visual_node_root)
	visual_node_root = null

	for node in visual_nodes:
		node.queue_free()

	for node in physics_nodes:
		node.queue_free()


func _instantiate_scene() -> void:
	if model_scene:
		var instantiate: Node3D = model_scene.instantiate()
		if instantiate == null:
			instantiate = Node3D.new()
			instantiate.set_name("Dummy")

		var model_dictionary: Dictionary = $/root/ModelFormat.build_model_trees(instantiate)

		visual_nodes = model_dictionary.visual
		physics_nodes = model_dictionary.physics

		visual_node_root = Node3D.new()
		visual_node_root.set_name("Visual")

		if _render_node:
			_render_node.add_child(visual_node_root, true)
			for visual_node in visual_nodes:
				visual_node.set_layer_mask(1 << 2)
				visual_node_root.add_child(visual_node, true)
				visual_node.set_owner(visual_node_root)

		if Engine.is_editor_hint():
			update_gizmos(visual_node_root)


func _setup_render_node() -> void:
	if has_node(_render_node_path):
		_render_node = get_node_or_null(_render_node_path)
		if _render_node == self or not _render_node is Node3D:
			_render_node = null


func _setup_model_nodes() -> void:
	if nodes_are_cached() and model_scene_requires_update:
		_setup_render_node()
		_delete_previous_model_nodes()
		_instantiate_scene()

		model_scene_requires_update = false
		model_loaded.emit()


func schedule_model_update() -> void:
	if !model_scene_requires_update:
		model_scene_requires_update = true
		call_deferred("_setup_model_nodes")


func _entity_ready() -> void:
	super._entity_ready()
	if !Engine.is_editor_hint():
		if model_scene_requires_update:
			_setup_model_nodes()


func _ready() -> void:
	if Engine.is_editor_hint():
		cache_nodes()
		_setup_model_nodes()


func _threaded_instance_setup(p_instance_id: int, p_network_reader: RefCounted) -> void:
	super._threaded_instance_setup(p_instance_id, p_network_reader)
	if model_scene_requires_update:
		_setup_model_nodes()
