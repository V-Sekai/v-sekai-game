# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_prop_definition_runtime.gd
# SPDX-License-Identifier: MIT

@tool
extends Node3D

@export var prop_resources: Array = []
@export var entity_instance_list: Array = []
@export var entity_instance_properties_list: Array = []

@export_enum("VSK_PREVIEW_CAMERA", "VSK_PREVIEW_TEXTURE") var vskeditor_preview_type: int

@export var vskeditor_preview_texture: Texture2D
@export_node_path("Camera3D") var vskeditor_preview_camera_path
@export var vskeditor_pipeline_paths: Array[NodePath]


func _ready():
	if !Engine.is_editor_hint():
		pass
