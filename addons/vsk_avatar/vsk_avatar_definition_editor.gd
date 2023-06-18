# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_avatar_definition_editor.gd
# SPDX-License-Identifier: MIT

@tool
extends Control

const vsk_types_const = preload("res://addons/vsk_importer_exporter/vsk_types.gd")
const avatar_callback_const = preload("avatar_callback.gd")

const hand_pose_exporter_const = preload("hand_pose_extractor.gd")

var editor_plugin: EditorPlugin = null

var node: Node = null
var err_dialog: AcceptDialog = null

var save_dialog: FileDialog = null

var bone_icon: Texture = null
var clear_icon: Texture = null

const OUTPUT_SCENE_EXTENSION = "scn"
const OUTPUT_HAND_RESOURCE_EXTENSION = "tres"

enum {
	MENU_OPTION_UPLOAD_AVATAR,
	MENU_OPTION_EXPORT_AVATAR,
	MENU_OPTION_EXPORT_LEFT_HAND_POSE,
	MENU_OPTION_EXPORT_RIGHT_HAND_POSE,
}

enum {
	SAVE_OPTION_AVATAR,
	SAVE_OPTION_LEFT_HAND_POSE,
	SAVE_OPTION_RIGHT_HAND_POSE,
}

var save_option: int = SAVE_OPTION_AVATAR

#	var queue : Array
#	queue.push_back(p_root)
#	var string_builder : Array
#	while not queue.is_empty():
#		var front = queue.front()
#		var node = front
#		if node is Skeleton3D:
#			bone_direction_const.fix_skeleton(p_root, node, p_humanoid_data, p_undo_redo)
#		var child_count : int = node.get_child_count()
#		for i in child_count:
#			queue.push_back(node.get_child(i))
#		queue.pop_front()
#	return p_root


func export_avatar_local() -> void:
	save_option = SAVE_OPTION_AVATAR

	assert(save_dialog)
	save_dialog.add_filter("*.%s;%s" % [OUTPUT_SCENE_EXTENSION, OUTPUT_SCENE_EXTENSION.to_upper()])

	save_dialog.popup_centered_ratio()
	save_dialog.set_title("Save Avatar As...")


func get_export_data() -> Dictionary:
	return {
		"root": editor_plugin.get_editor_interface().get_edited_scene_root(),
		"node": node,
	}


func export_avatar_upload() -> void:
	if node and node is Node:
		var vsk_editor = $"/root/VSKEditor"
		if vsk_editor:
			vsk_editor.show_upload_panel(self.get_export_data, vsk_types_const.UserContentType.Avatar)
		else:
			printerr("Could not load VSKEditor!")
	else:
		printerr("Node is not valid!")


func export_hand_pose(p_is_right_hand: bool) -> void:
	if node and node is Node:
		if p_is_right_hand:
			save_option = SAVE_OPTION_RIGHT_HAND_POSE
		else:
			save_option = SAVE_OPTION_LEFT_HAND_POSE

		assert(save_dialog)
		save_dialog.add_filter("*.%s;%s" % [OUTPUT_HAND_RESOURCE_EXTENSION, OUTPUT_HAND_RESOURCE_EXTENSION.to_upper()])

		save_dialog.popup_centered_ratio()
		save_dialog.set_title("Save Hand Pose As...")


func edit(p_node: Node) -> void:
	node = p_node


func error_callback(p_err: int) -> void:
	if p_err != avatar_callback_const.AVATAR_OK:
		var error_str: String = avatar_callback_const.get_error_str(p_err)

		printerr(error_str)
		if err_dialog:
			err_dialog.set_text(error_str)
			err_dialog.popup_centered_clamped()


func check_if_avatar_is_valid() -> bool:
	if !node:
		return false

	return true


func menu_option(p_id: int) -> void:
	var err: int = avatar_callback_const.AVATAR_OK
	match p_id:
		MENU_OPTION_EXPORT_AVATAR:
			if check_if_avatar_is_valid():
				export_avatar_local()
			else:
				err = avatar_callback_const.ROOT_IS_NULL
		MENU_OPTION_UPLOAD_AVATAR:
			if check_if_avatar_is_valid():
				export_avatar_upload()
			else:
				err = avatar_callback_const.ROOT_IS_NULL
		MENU_OPTION_EXPORT_LEFT_HAND_POSE:
			if check_if_avatar_is_valid():
				export_hand_pose(false)
			else:
				err = avatar_callback_const.ROOT_IS_NULL
		MENU_OPTION_EXPORT_RIGHT_HAND_POSE:
			if check_if_avatar_is_valid():
				export_hand_pose(true)
			else:
				err = avatar_callback_const.ROOT_IS_NULL

	error_callback(err)


static func _refresh_skeleton(p_skeleton: Skeleton3D):
	p_skeleton.visible = not p_skeleton.visible
	p_skeleton.visible = not p_skeleton.visible


func _save_file_at_path(p_path: String) -> void:
	var vsk_exporter: Node = get_node_or_null("/root/VSKExporter")

	var err: int = avatar_callback_const.AVATAR_FAILED

	if save_option == SAVE_OPTION_AVATAR:
		if vsk_exporter:
			err = (vsk_exporter.export_avatar(editor_plugin.get_editor_interface().get_edited_scene_root(), node, p_path))
		else:
			err = avatar_callback_const.AVATAR_FAILED

	elif save_option == SAVE_OPTION_LEFT_HAND_POSE or save_option == SAVE_OPTION_RIGHT_HAND_POSE:
		err = avatar_callback_const.AVATAR_COULD_NOT_EXPORT_HANDS
		if node:
			var skeleton: Skeleton3D = node._skeleton_node
			if skeleton:
				var hand_pose: Animation = hand_pose_exporter_const.generate_hand_pose_from_skeleton(skeleton, true if save_option == SAVE_OPTION_RIGHT_HAND_POSE else false)

				if hand_pose:
					if (ResourceSaver.save(hand_pose, p_path, ResourceSaver.FLAG_RELATIVE_PATHS) & 0xffffffff) == OK:
						err = avatar_callback_const.AVATAR_OK

	error_callback(err)


func setup_dialogs() -> void:
	err_dialog = AcceptDialog.new()
	editor_plugin.get_editor_interface().get_base_control().add_child(err_dialog)

	save_dialog = FileDialog.new()
	save_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	save_dialog.access = FileDialog.ACCESS_FILESYSTEM
	save_dialog.exclusive = true
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


func _init(p_editor_plugin: EditorPlugin, p_clear_icon: Texture, p_bone_icon: Texture):
	editor_plugin = p_editor_plugin

	bone_icon = p_bone_icon
	clear_icon = p_clear_icon
