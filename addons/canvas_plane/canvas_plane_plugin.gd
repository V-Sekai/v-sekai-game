# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# canvas_plane_plugin.gd
# SPDX-License-Identifier: MIT

@tool
extends EditorPlugin

var editor_interface = null


func _init():
	print("Initialising CanvasPlane plugin")


func _notification(p_notification: int):
	match p_notification:
		NOTIFICATION_PREDELETE:
			print("Destroying CanvasPlane plugin")


func _get_plugin_name():
	return "CanvasPlane"
