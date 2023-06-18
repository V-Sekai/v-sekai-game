# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# math_util_plugin.gd
# SPDX-License-Identifier: MIT

@tool
extends EditorPlugin


func _init():
	print("Initialising MathUtil plugin")
	name = &"MathUtil"


func _notification(p_notification: int) -> void:
	match p_notification:
		NOTIFICATION_PREDELETE:
			print("Destroying MathUtil plugin")


func _enter_tree() -> void:
	add_autoload_singleton("GodotMathExtension", "res://addons/math_util/math_funcs.gd")


func _exit_tree() -> void:
	remove_autoload_singleton("GodotMathExtension")
