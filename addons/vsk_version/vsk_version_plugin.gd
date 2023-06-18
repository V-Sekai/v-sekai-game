# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_version_plugin.gd
# SPDX-License-Identifier: MIT

@tool
extends EditorPlugin

var editor_interface: EditorInterface = null


func _init():
	print("Initialising VSKVersion plugin")


func _notification(p_notification: int):
	match p_notification:
		NOTIFICATION_PREDELETE:
			print("Destroying VSKVersion plugin")


func _get_plugin_name() -> String:
	return "VSKVersion"


func _enter_tree() -> void:
	editor_interface = get_editor_interface()
	add_autoload_singleton("VSKVersion", "res://addons/vsk_version/vsk_version.gd")


func _exit_tree() -> void:
	remove_autoload_singleton("VSKVersion")
