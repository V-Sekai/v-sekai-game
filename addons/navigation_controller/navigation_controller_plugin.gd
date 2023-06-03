# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# navigation_controller_plugin.gd
# SPDX-License-Identifier: MIT

@tool
extends EditorPlugin

const navigation_controller_const = preload("res://addons/navigation_controller/navigation_controller.gd")
const view_controller_const = preload("res://addons/navigation_controller/view_controller.gd")


func _init():
	print("Initialising NavigationController plugin")


func _notification(p_notification: int):
	match p_notification:
		NOTIFICATION_PREDELETE:
			print("Destroying NavigationController plugin")


func _get_plugin_name() -> String:
	return "NavigationController"
