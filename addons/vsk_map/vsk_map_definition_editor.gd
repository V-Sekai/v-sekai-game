# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_map_definition_editor.gd
# SPDX-License-Identifier: MIT

@tool
extends Control

const vsk_map_definition_const = preload("res://addons/vsk_map/vsk_map_definition.gd")
const vsk_map_definition_runtime_const = preload("res://addons/vsk_map/vsk_map_definition_runtime.gd")

const vsk_types_const = preload("res://addons/vsk_importer_exporter/vsk_types.gd")
const map_callback_const = preload("res://addons/vsk_map/map_callback.gd")

var node: Node = null
var err_dialog: AcceptDialog = null

var save_dialog: FileDialog = null

const OUTPUT_SCENE_EXTENSION = "scn"

enum { MENU_OPTION_EXPORT_MAP, MENU_OPTION_UPLOAD_MAP, MENU_OPTION_INIT_MAP }

var editor_plugin: EditorPlugin = null


func export_map_local() -> void:
	save_dialog.add_filter("*.%s;%s" % [OUTPUT_SCENE_EXTENSION, OUTPUT_SCENE_EXTENSION.to_upper()])
	save_dialog.current_file = String(node.name).to_snake_case() + ".scn"
	save_dialog.popup_centered_ratio(0.7)
	save_dialog.set_title("Save Map As...")


func get_export_data() -> Dictionary:
	return {"root": editor_plugin.get_editor_interface().get_edited_scene_root(), "node": node}


func export_map_upload() -> void:
	if node and node is Node:
		var vsk_editor: Node = get_node_or_null("/root/VSKEditor")
		if vsk_editor:
			vsk_editor.show_upload_panel(self.get_export_data, vsk_types_const.UserContentType.Map)
		else:
			printerr("Could not load VSKEditor!")
	else:
		printerr("Node is not valid!")


func edit(p_node: Node) -> void:
	node = p_node


func error_callback(p_err: int) -> void:
	if p_err != map_callback_const.MAP_OK:
		var error_str: String = map_callback_const.get_error_string(p_err)

		printerr(error_str)
		err_dialog.set_text(error_str)
		err_dialog.popup_centered_clamped()


func check_if_map_is_valid() -> bool:
	if !node:
		return false

	return true


func _menu_option(p_id: int) -> void:
	var err: int = map_callback_const.MAP_OK

	var node_3d: Node3D = node
	if node_3d:
		match p_id:
			MENU_OPTION_INIT_MAP:
				if check_if_map_is_valid():
					node_3d.set_script(vsk_map_definition_const)
				else:
					map_callback_const.ROOT_IS_NULL
			MENU_OPTION_EXPORT_MAP:
				if check_if_map_is_valid():
					export_map_local()
				else:
					map_callback_const.ROOT_IS_NULL
			MENU_OPTION_UPLOAD_MAP:
				if check_if_map_is_valid():
					export_map_upload()
				else:
					map_callback_const.ROOT_IS_NULL

	error_callback(err)


func _save_file_at_path(p_string: String) -> void:
	var vsk_exporter: Node = get_node_or_null("/root/VSKExporter")

	var err: int = map_callback_const.EXPORTER_NODE_LOADED
	if vsk_exporter:
		err = vsk_exporter.export_map(editor_plugin.get_editor_interface().get_edited_scene_root(), node, p_string)

	error_callback(err)


func setup_dialogs() -> void:
	err_dialog = AcceptDialog.new()
	editor_plugin.get_editor_interface().get_base_control().add_child(err_dialog)

	save_dialog = FileDialog.new()
	save_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	save_dialog.access = FileDialog.ACCESS_FILESYSTEM
	save_dialog.exclusive = true
	save_dialog.popup_centered_ratio(0.7)
	save_dialog.file_selected.connect(self._save_file_at_path)
	editor_plugin.get_editor_interface().get_base_control().add_child(save_dialog)


func teardown_dialogs() -> void:
	if err_dialog:
		if err_dialog.is_inside_tree():
			err_dialog.get_parent().remove_child(err_dialog)
		err_dialog.queue_free()

	if save_dialog:
		if save_dialog.is_inside_tree():
			save_dialog.get_parent().remove_child(err_dialog)
		save_dialog.queue_free()


func _enter_tree():
	setup_dialogs()


func _exit_tree():
	teardown_dialogs()


func _init(p_editor_plugin: EditorPlugin):
	editor_plugin = p_editor_plugin
