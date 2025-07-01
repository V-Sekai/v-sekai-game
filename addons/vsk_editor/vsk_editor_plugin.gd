# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_editor_plugin.gd
# SPDX-License-Identifier: MIT

@tool
extends EditorPlugin
class_name VSKEditorPlugin

const URO_LOGO = preload("./icon.svg")

var _uro_toolbar: VSKEditorUroToolbarContainer = null

var _editor_interface = null # EditorInterface

func _init():
	print("Initialising VSKEditor plugin")


func _notification(p_notification: int):
	match p_notification:
		NOTIFICATION_PREDELETE:
			print("Destroying VSKEditor plugin")


func _get_plugin_name() -> String:
	return "VSKEditor"

func _clear_uro_toolbar() -> void:
	if _uro_toolbar:
		if _uro_toolbar.is_inside_tree():
			_uro_toolbar.get_parent().remove_child(_uro_toolbar)
		_uro_toolbar.queue_free()

func _enter_tree() -> void:
	add_autoload_singleton("VSKEditorSingleton", "./vsk_editor.gd")
	var vsk_editor: VSKEditor = get_node_or_null("/root/VSKEditorSingleton")
	if not vsk_editor:
		printerr("Could not setup VSKEditorSingleton.")
		
	_clear_uro_toolbar()
		
	_uro_toolbar = preload("vsk_editor_uro_toolbar_container.tscn").instantiate()
	add_control_to_container(CONTAINER_TOOLBAR, _uro_toolbar)

	_editor_interface = Engine.get_singleton("EditorInterface")
	if not _editor_interface:
		push_error("EditorInterface singleton is not available")
		return
	vsk_editor.setup_editor(
		_editor_interface.get_editor_main_screen(), _uro_toolbar
	)

func _exit_tree() -> void:
	remove_control_from_container(CONTAINER_TOOLBAR, _uro_toolbar)
	remove_autoload_singleton("VSKEditorSingleton")

	_clear_uro_toolbar()
