# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_user_content_selector.gd
# SPDX-License-Identifier: MIT

extends Control

@export var sub_selectors: Array = []
@export var local_files_button_path: NodePath = NodePath()
@export var load_content_on_creation: bool = false

enum ContentType { CONTENT_AVATARS, CONTENT_MAPS }

@export_enum("Avatars", "Maps") var content_type: int = ContentType.CONTENT_AVATARS

signal uro_id_selected(p_id)
signal refreshed


func _on_uro_id_selected(p_id):
	uro_id_selected.emit(p_id)


func _on_refresh_button_pressed() -> void:
	refreshed.emit()


func _reload_content():
	pass


func _ready():
	if VSKDebugManager.developer_mode:
		get_node(local_files_button_path).show()
	else:
		get_node(local_files_button_path).hide()

	for sub_selector in sub_selectors:
		if typeof(sub_selector) == TYPE_NODE_PATH:
			var node: Node = get_node_or_null(sub_selector)
			if node:
				node.content_type = content_type
				node.load_content_on_creation = load_content_on_creation
