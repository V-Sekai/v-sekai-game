# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# entity_manager_plugin.gd
# SPDX-License-Identifier: MIT

@tool
extends EditorPlugin

var editor_interface: EditorInterface = null
const entity_const = preload("res://addons/entity_manager/entity.gd")


func _init():
	print("Initialising EntityManager plugin")


func _notification(p_notification: int):
	match p_notification:
		NOTIFICATION_PREDELETE:
			print("Destroying EntityManager plugin")


func _get_plugin_name() -> String:
	return "EntityManager"


func _enter_tree() -> void:
	editor_interface = get_editor_interface()

	add_autoload_singleton("EntityManager", "res://addons/entity_manager/entity_manager.gd")

	add_custom_type("Node3DEntity", "Node3D", entity_const, editor_interface.get_base_control().get_theme_icon("Node3D", "EditorIcons"))
	add_custom_type("Node2DEntity", "Node2D", entity_const, editor_interface.get_base_control().get_theme_icon("Node2D", "EditorIcons"))


func _exit_tree() -> void:
	remove_custom_type("SpatialEntity")
	remove_custom_type("Node2DEntity")

	remove_autoload_singleton("EntityManager")
