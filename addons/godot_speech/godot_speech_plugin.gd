# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# godot_speech_plugin.gd
# SPDX-License-Identifier: MIT

@tool
extends EditorPlugin

var editor_interface: EditorInterface = null


func _init():
	print("Initialising GodotSpeech plugin")


func _notification(p_notification: int):
	match p_notification:
		NOTIFICATION_PREDELETE:
			print("Destroying GodotSpeech plugin")


func _get_plugin_name() -> String:
	return "GodotSpeech"


func _enter_tree() -> void:
	editor_interface = get_editor_interface()

	add_autoload_singleton("GodotSpeech", "res://addons/godot_speech/godot_speech.gd")


func _exit_tree() -> void:
	remove_autoload_singleton("GodotSpeech")
