# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_validator.gd
# SPDX-License-Identifier: MIT

@tool
extends RefCounted


static func check_basic_node_3d_value_targets(p_subnames: String) -> bool:
	match p_subnames:
		"position":
			return true
		"rotation":
			return true
		"scale":
			return true
		"transform":
			return true
		"visibility":
			return true

	return false


static func is_editor_only(p_node: Node) -> bool:
	if p_node is Light3D:
		if p_node.editor_only:
			return true

	return false


func is_scene_valid_for_root(p_script: Script) -> bool:
	if p_script == null:
		return true
	else:
		return false


func is_script_valid_for_root(p_script: Script, _p_node_class: String) -> bool:
	if p_script == null:
		return true
	else:
		return false


func is_script_valid_for_children(p_script: Script, _p_node_class: String) -> bool:
	if p_script == null:
		return true
	else:
		return false


func is_script_valid_for_resource(p_script: Script) -> bool:
	if p_script == null:
		return true
	else:
		return false


func is_node_type_valid(_node: Node, _child_of_canvas: bool) -> bool:
	return false


func is_node_type_string_valid(_class_str: String, _child_of_canvas: bool) -> bool:
	return false


func is_resource_type_valid(_resource: Resource) -> bool:
	return false


func is_path_an_entity(_packed_scene_path: String) -> bool:
	return false


func is_valid_entity_script(_script: Script) -> bool:
	return false


func is_valid_canvas_3d(_script: Script, _node_class: String) -> bool:
	return false


func is_valid_canvas_3d_anchor(_script: Script, _node_class: String) -> bool:
	return false


func validate_value_track(_subnames: String, _node_class: String):
	return false


func sanitise_node(p_node: Node) -> Node:
	var node_name: String = p_node.get_name()
	var new_node: Node = null
	if p_node is Node3D:
		new_node = Node3D.new()
	else:
		new_node = Node.new()

	new_node.set_name(node_name)
	p_node.replace_by(new_node)
	p_node = new_node

	return p_node


func get_name() -> String:
	return "UnknownValidator"
