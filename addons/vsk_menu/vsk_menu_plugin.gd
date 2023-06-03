# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_menu_plugin.gd
# SPDX-License-Identifier: MIT

@tool
extends EditorPlugin


func _init():
	print("Initialising VSKMenu plugin")


func _notification(p_notification: int):
	match p_notification:
		NOTIFICATION_PREDELETE:
			print("Destroying VSKMenu plugin")


func _get_plugin_name() -> String:
	return "VSKMenu"
