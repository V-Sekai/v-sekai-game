# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# godot_uro_plugin.gd
# SPDX-License-Identifier: MIT

@tool
extends EditorPlugin

var editor_interface: EditorInterface = null
var button: Button = null


func _init():
	print("Initialising GodotUro plugin")


func _notification(p_notification: int):
	match p_notification:
		NOTIFICATION_PREDELETE:
			print("Destroying GodotUro plugin")


func _get_plugin_name() -> String:
	return "GodotUro"


func _enter_tree() -> void:
	editor_interface = get_editor_interface()

	add_autoload_singleton("GodotUroData", "res://addons/godot_uro/godot_uro_data.gd")
	add_autoload_singleton("GodotUro", "res://addons/godot_uro/godot_uro.gd")


func _exit_tree() -> void:
	remove_autoload_singleton("GodotUro")
	remove_autoload_singleton("GodotUroData")
