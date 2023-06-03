# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# graphics_manager_plugin.gd
# SPDX-License-Identifier: MIT

@tool
extends EditorPlugin

var editor_interface = null


func _init():
	print("Initialising GraphicsManager plugin")


func _notification(p_notification: int):
	match p_notification:
		NOTIFICATION_PREDELETE:
			print("Destroying GraphicsManager plugin")


func _get_plugin_name() -> String:
	return "GraphicsManager"


func _enter_tree() -> void:
	editor_interface = get_editor_interface()
	add_autoload_singleton("GraphicsManager", "res://addons/sar1_graphics_manager/graphics_manager.gd")


func _exit_tree() -> void:
	remove_autoload_singleton("GraphicsManager")
