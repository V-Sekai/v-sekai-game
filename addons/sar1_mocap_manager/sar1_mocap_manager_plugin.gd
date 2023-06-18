# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# sar1_mocap_manager_plugin.gd
# SPDX-License-Identifier: MIT

@tool
extends EditorPlugin
class_name MocapManagerPlugin

var editor_interface: EditorInterface = null

const mcp_importer_const = preload("sar1_mcp_importer.gd")

var mcp_importer = null

var singleton_table = [
#{"singleton_name":"MocapManager", "singleton_path":"res://addons/sar1_mocap_manager/sar1_mocap_manager.gd"},
]


func _init():
	print("Initialising MocapManager plugin")


func _notification(p_notification: int):
	match p_notification:
		NOTIFICATION_PREDELETE:
			print("Destroying MocapManager plugin")


func _get_plugin_name() -> String:
	return "Sar1MocapManager"


func _enter_tree() -> void:
	editor_interface = get_editor_interface()

	for singleton in singleton_table:
		add_autoload_singleton(singleton["singleton_name"], singleton["singleton_path"])
	if Engine.is_editor_hint():
		mcp_importer = mcp_importer_const.new()
		add_import_plugin(mcp_importer)


func _exit_tree() -> void:
	if Engine.is_editor_hint():
		remove_import_plugin(mcp_importer)
		mcp_importer = null
	var sr: Array = singleton_table.duplicate()
	sr.reverse()
	for singleton in sr:
		remove_autoload_singleton(singleton["singleton_name"])
