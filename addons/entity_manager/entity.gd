# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# entity.gd
# SPDX-License-Identifier: MIT

@tool
extends "res://addons/entity_manager/runtime_entity.gd"  # runtime_entity.gd
class_name Entity

const runtime_entity_const = preload("runtime_entity.gd")


func is_root_entity() -> bool:
	var networked_scenes: Array = []

	if ProjectSettings.has_setting("network/config/networked_scenes"):
		networked_scenes = ProjectSettings.get_setting("network/config/networked_scenes")

	if get_owner() == null and networked_scenes.find(get_scene_file_path()) != -1:
		return true

	return false


func is_subnode_property_valid() -> bool:
	if !Engine.is_editor_hint():
		return true
	else:
		return not scene_file_path.is_empty() or (is_inside_tree() and get_tree().edited_scene_root and get_tree().edited_scene_root == self)


static func sub_property_path(p_property: String, p_sub_node_name: String) -> String:
	var split_property: PackedStringArray = p_property.split("/", -1)
	var property: String = ""
	if split_property.size() > 1 and split_property[0] == p_sub_node_name:
		for i in range(1, split_property.size()):
			property += split_property[i]
			if i != (split_property.size() - 1):
				property += "/"

	return property


func _get_property_list() -> Array:
	if Engine.is_editor_hint():
		var properties: Array = []
		if simulation_logic_node_path:
			var node: Node = get_node_or_null(simulation_logic_node_path)
			if node and node != self:
				if is_subnode_property_valid():
					var logic_node_properties: Array = runtime_entity_const.get_custom_logic_node_properties(node)
					for property in logic_node_properties:
						property["name"] = "simulation_logic_node/%s" % property["name"]
						properties.push_back(property)

		return properties
	else:
		return super._get_property_list()


func get_sub_property(p_path: NodePath, p_property: String, p_sub_node_name: String):
	var variant: Variant = null
	var node = get_node_or_null(p_path)
	if node and node != self:
		var property: String = Entity.sub_property_path(p_property, p_sub_node_name)
		if property.substr(0, 1) != "_":
			variant = node.get(property)
			if typeof(variant) == TYPE_NODE_PATH:
				var var_np: NodePath = variant
				if var_np != NodePath():
					var sub_node: Node = node.get_node_or_null(var_np)
					if sub_node:
						var_np = node.get_path_to(sub_node)
					else:
						var_np = NodePath()
				else:
					var_np = NodePath()
				variant = var_np
	return variant


func set_sub_property(p_path: NodePath, p_property: String, p_value, p_sub_node_name: String) -> bool:
	var node = get_node_or_null(p_path)
	if node != null and node != self:
		var property: String = Entity.sub_property_path(p_property, p_sub_node_name)
		if property.substr(0, 1) != "_":
			var variant = p_value
			if typeof(variant) == TYPE_NODE_PATH:
				if variant != NodePath():
					var sub_node = get_node_or_null(variant)
					if sub_node:
						node.set(property, node.get_path_to(sub_node))
						return false  # NO IDEA
					else:
						node.set(property, NodePath())
						return false  # NO IDEA
				else:
					node.set(property, NodePath())
					return false  # NO IDEA
			node.set(property, variant)
			return false  # NO IDEA
	return false


func _get(p_property: StringName):
	if Engine.is_editor_hint():
		var variant = null
		if simulation_logic_node_path != NodePath() and is_subnode_property_valid():
			variant = get_sub_property(simulation_logic_node_path, p_property, "simulation_logic_node")
		return variant
	else:
		return super._get(p_property)


func _set(p_property: StringName, p_value) -> bool:
	if Engine.is_editor_hint():
		var return_val: bool = false
		if simulation_logic_node_path != NodePath() and is_subnode_property_valid():
			return_val = set_sub_property(simulation_logic_node_path, p_property, p_value, "simulation_logic_node")

		return return_val
	else:
		return super._set(p_property, p_value)
