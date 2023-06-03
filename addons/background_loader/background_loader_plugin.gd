# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# background_loader_plugin.gd
# SPDX-License-Identifier: MIT

@tool
extends EditorPlugin

var editor_interface: EditorInterface = null


func _init():
	print("Initialising BackgroundLoader plugin")


func _enter_tree():
	editor_interface = get_editor_interface()

	add_autoload_singleton("BackgroundLoader", "res://addons/background_loader/background_loader.gd")


func _notification(p_notification: int):
	match p_notification:
		NOTIFICATION_PREDELETE:
			print("Destroying BackgroundLoader plugin")


func _get_plugin_name() -> String:
	return "BackgroundLoader"


func _exit_tree() -> void:
	remove_autoload_singleton("BackgroundLoader")
