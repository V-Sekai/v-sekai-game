# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_map_definition.gd
# SPDX-License-Identifier: MIT

@tool
extends "res://addons/vsk_map/vsk_map_definition_runtime.gd"

const vsk_user_content_definition_helper_const = preload("res://addons/vsk_importer_exporter/vsk_user_content_definition_helper.gd")


func add_pipeline(p_node: Node) -> void:
	vskeditor_pipeline_paths.push_back(get_path_to(p_node))


func remove_pipeline(p_node: Node) -> void:
	vskeditor_pipeline_paths.erase(get_path_to(p_node))


func _get(p_property):
	return vsk_user_content_definition_helper_const.common_get(self, p_property)


func _set(p_property, p_value) -> bool:
	return vsk_user_content_definition_helper_const.common_set(self, p_property, p_value)
