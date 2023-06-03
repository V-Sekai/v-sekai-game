# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vr_manager_plugin.gd
# SPDX-License-Identifier: MIT

@tool
extends EditorPlugin

var editor_interface = null


func _init():
	print("Initialising Sar1VRManager plugin")


func _notification(p_notification: int):
	match p_notification:
		NOTIFICATION_PREDELETE:
			print("Destroying Sar1VRManager plugin")


func _get_plugin_name() -> String:
	return "Sar1VRManager"


func _enter_tree() -> void:
	editor_interface = get_editor_interface()
	add_autoload_singleton(
		"SnappingSingleton", "res://addons/sar1_vr_manager/components/lasso_snapping/snapping_singleton.gd"
	)
	add_autoload_singleton("VRManager", "res://addons/sar1_vr_manager/vr_manager.gd")


func _exit_tree() -> void:
	remove_autoload_singleton("VRManager")
	remove_autoload_singleton("SnappingSingleton")
