# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# godot_uro_plugin.gd
# SPDX-License-Identifier: MIT

## The GodotUro plugin provides an interface for interacting with instances
## of the Uro web API from Godot.

@tool
extends EditorPlugin
class_name GodotUroPlugin

func _init():
	print("Initialising GodotUro plugin")


func _notification(p_notification: int):
	match p_notification:
		NOTIFICATION_PREDELETE:
			print("Destroying GodotUro plugin")


func _get_plugin_name() -> String:
	return "GodotUro"
