# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_avatar_definition.gd
# SPDX-License-Identifier: MIT

@tool
extends "res://addons/vsk_avatar/vsk_avatar_definition_runtime.gd"

const vsk_user_content_definition_helper_conest = preload("res://addons/vsk_importer_exporter/vsk_user_content_definition_helper.gd")

@export_enum("VSK_PREVIEW_CAMERA", "VSK_PREVIEW_TEXTURE") var vskeditor_preview_type: int
@export var vskeditor_preview_texture: Texture2D
@export_node_path("Camera3D") var vskeditor_preview_camera_path
@export var vskeditor_pipeline_paths: Array[NodePath]


func add_pipeline(p_node: Node) -> void:
	vskeditor_pipeline_paths.push_back(get_path_to(p_node))


func remove_pipeline(p_node: Node) -> void:
	vskeditor_pipeline_paths.erase(get_path_to(p_node))


func _get(p_property):
	return vsk_user_content_definition_helper_conest.common_get(self, p_property)


func _set(p_property, p_value) -> bool:
	return vsk_user_content_definition_helper_conest.common_set(self, p_property, p_value)
