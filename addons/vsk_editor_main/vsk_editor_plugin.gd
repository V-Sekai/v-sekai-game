# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_editor_main_plugin.gd
# SPDX-License-Identifier: MIT

@tool
extends EditorPlugin

var uro_logo_png = load("res://addons/vsk_editor/uro_logo.png")
var editor_interface: EditorInterface = null
var undo_redo: EditorUndoRedoManager = null
var uro_button: Button = null


func _init():
	print("Initialising VSKEditor plugin")


func _notification(p_notification: int):
	match p_notification:
		NOTIFICATION_PREDELETE:
			print("Destroying VSKEditor plugin")


func _get_plugin_name() -> String:
	return "VSKEditor"


func setup_vskeditor(viewport: Viewport, button: Button, editor_interface: EditorInterface, undo_redo: EditorUndoRedoManager) -> void:
	var vsk_editor: Node = get_node_or_null("/root/VSKEditor")
	assert(vsk_editor)

	vsk_editor.setup_editor(editor_interface.get_editor_main_screen(), uro_button, editor_interface)

var plugin_control

func _enter_tree():
	plugin_control = Panel.new()
	var label = Label.new()
	label.text = "Placeholder for the new Uro Editor main screen plugin."
	plugin_control.add_child(label)
	EditorInterface.get_editor_main_screen().add_child(plugin_control)


func _exit_tree() -> void:
	plugin_control.queue_free()


func _has_main_screen():
	return true


func _get_plugin_icon():
	return uro_logo_png

