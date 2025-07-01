# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_importer_exporter_plugin.gd
# SPDX-License-Identifier: MIT

@tool
extends EditorPlugin
class_name VSKImporterExporterPlugin

var editor_interface = null # EditorInterface


func _init():
	print("Initialising VSKImporterExporter plugin")


func _notification(p_notification: int):
	match p_notification:
		NOTIFICATION_PREDELETE:
			print("Destroying VSKImporterExporter plugin")


func _get_plugin_name() -> String:
	return "VSKImporterExporter"


func _enter_tree() -> void:
	editor_interface = get_editor_interface()

	#add_autoload_singleton("VSKExporterSingleton", "res://addons/vsk_importer_exporter/vsk_exporter.gd")
	#add_autoload_singleton("VSKImporterSingleton", "res://addons/vsk_importer_exporter/vsk_importer.gd")


func _exit_tree() -> void:
	pass
#	remove_autoload_singleton("VSKImporterSingleton")
#	remove_autoload_singleton("VSKExporterSingleton")
