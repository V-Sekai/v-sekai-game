# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_vrm_avatar_converter_editor.gd
# SPDX-License-Identifier: MIT

@tool
extends Node

const vrm_toplevel_const = preload("res://addons/vrm/vrm_toplevel.gd")

const vsk_vrm_avatar_functions_const = preload("vsk_vrm_avatar_functions.gd")
const vsk_vrm_callback_const = preload("vsk_vrm_callback.gd")

enum { MENU_OPTION_CONVERT_TO_VSK_AVATAR }

const VRM_EXTENSION = "vrm"

var node: Node = null
var editor_plugin: EditorPlugin = null
var err_dialog: AcceptDialog = null
var save_dialog: FileDialog = null


func error_callback(p_err: int, p_extra_code: int) -> void:
	if p_err != vsk_vrm_callback_const.VRM_OK:
		var error_str: String = vsk_vrm_callback_const.get_error_string(p_err)

		printerr(error_str + ("code: %s" % str(p_extra_code)))
		err_dialog.set_text(error_str)
		err_dialog.popup_centered_clamped()


func menu_option(p_id: int) -> void:
	match p_id:
		MENU_OPTION_CONVERT_TO_VSK_AVATAR:
			save_vrm_selection_dialog()
			return

	error_callback(vsk_vrm_callback_const.VRM_INVALID_MENU_OPTION, -1)


func set_owner_rec(node: Node, owner: Node):
	node.owner = owner
	for n in node.get_children():
		set_owner_rec(n, owner)


func convert_vrm(p_save_path: String) -> void:
	var err: int = -1
	if not editor_plugin:
		error_callback(vsk_vrm_callback_const.VRM_NO_EDITOR_PLUGIN, err)
	var instance: Node3D = node.duplicate()
	instance.scene_file_path = node.scene_file_path
	if not (instance and typeof(instance.get(&"vrm_meta")) != TYPE_NIL):
		error_callback(vsk_vrm_callback_const.VRM_INVALID_NODE, err)
	instance.vrm_meta.texture = null
	var avatar_root: Node3D = vsk_vrm_avatar_functions_const.convert_vrm_instance(instance)
	if not avatar_root:
		error_callback(vsk_vrm_callback_const.VRM_FAILED, err)
	avatar_root.set_owner(null)
	for n in avatar_root.get_children():
		set_owner_rec(n, avatar_root)
	if !instance.scene_file_path.is_empty():
		for n in instance.get_children():
			set_owner_rec(n, instance)
	var packed_scene: PackedScene = PackedScene.new()
	err = packed_scene.pack(avatar_root)
	avatar_root.queue_free()
	if err & 0xffffffff != OK:
		error_callback(vsk_vrm_callback_const.VRM_COULD_NOT_PACK, err)
	err = ResourceSaver.save(packed_scene, p_save_path)
	var editor_filesystem = EditorPlugin.new().get_editor_interface().get_resource_filesystem()
	editor_filesystem.scan()
	if err & 0xffffffff != OK:
		error_callback(vsk_vrm_callback_const.VRM_COULD_NOT_SAVE, err)


func _save_file_at_path(p_path: String) -> void:
	convert_vrm(p_path)


func _is_valid_vrm_file(p_path: String) -> bool:
	if p_path.get_extension().to_lower() == VRM_EXTENSION:
		return true

	return false


func save_vrm_selection_dialog() -> void:
	if save_dialog:
		save_dialog.current_file = str(node.name) + ".scn"
		save_dialog.popup_centered_ratio()


func edit(p_node: Node) -> void:
	node = p_node


func setup_dialogs() -> void:
	err_dialog = AcceptDialog.new()
	editor_plugin.get_editor_interface().get_base_control().add_child(err_dialog)

	save_dialog = FileDialog.new()
	save_dialog.set_title("Save Avatar As...")
	save_dialog.add_filter("*.scn; Scenes")
	save_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	save_dialog.access = FileDialog.ACCESS_FILESYSTEM
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
