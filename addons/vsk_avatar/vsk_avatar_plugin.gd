# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_avatar_plugin.gd
# SPDX-License-Identifier: MIT

@tool
extends EditorPlugin

const avatar_definition_editor_const = preload("vsk_avatar_definition_editor.gd")
const avatar_definition_const = preload("vsk_avatar_definition.gd")

var editor_interface: EditorInterface = null
var avatar_definition_editor: Control = null

var option_button: MenuButton = null


func _init():
	print("Initialising VSKAvatar plugin")


func _notification(p_notification: int):
	match p_notification:
		NOTIFICATION_PREDELETE:
			print("Destroying VSKAvatar plugin")


func _get_plugin_name() -> String:
	return "VSKAvatar"


func _menu_option(p_id: int) -> void:
	if avatar_definition_editor:
		avatar_definition_editor.menu_option(p_id)


func update_menu_options() -> void:
	if option_button:
		option_button.get_popup().clear()
		# The order must match the enum in res://addons/vsk_avatar/vsk_avatar_definition_editor.gd
		option_button.get_popup().add_item("Upload Avatar", avatar_definition_editor_const.MENU_OPTION_UPLOAD_AVATAR)
		option_button.get_popup().add_item("Export Avatar Definition Locally", avatar_definition_editor_const.MENU_OPTION_EXPORT_AVATAR)
		option_button.get_popup().add_item("Save Left Hand Pose (Debug)", avatar_definition_editor_const.MENU_OPTION_EXPORT_LEFT_HAND_POSE)
		option_button.get_popup().add_item("Save Right Hand Pose (Debug)", avatar_definition_editor_const.MENU_OPTION_EXPORT_RIGHT_HAND_POSE)


func _enter_tree() -> void:
	editor_interface = get_editor_interface()

	var clear_icon: Texture = editor_interface.get_base_control().get_theme_icon("Clear", "EditorIcons")
	var bone_icon: Texture = editor_interface.get_base_control().get_theme_icon("BoneAttachment", "EditorIcons")

	avatar_definition_editor = avatar_definition_editor_const.new(self, clear_icon, bone_icon)
	editor_interface.get_viewport().call_deferred("add_child", avatar_definition_editor)

	option_button = MenuButton.new()
	option_button.set_switch_on_hover(true)
	option_button.set_text("Avatar Definition")

	option_button.get_popup().id_pressed.connect(self._menu_option)
	option_button.hide()

	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, option_button)


func _exit_tree() -> void:
	if option_button:
		remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, option_button)
		if option_button.is_inside_tree():
			option_button.get_parent().remove_child(option_button)
		option_button.queue_free()

	if avatar_definition_editor:
		if avatar_definition_editor.is_inside_tree():
			avatar_definition_editor.get_parent().remove_child(avatar_definition_editor)
		avatar_definition_editor.queue_free()


func _edit(p_object: Object) -> void:
	if avatar_definition_editor:
		if p_object is Node and typeof(p_object.get("skeleton_path")) == TYPE_NODE_PATH:
			avatar_definition_editor.edit(p_object)
			update_menu_options()


func _handles(p_object: Object) -> bool:
	if p_object != null and p_object.get_script() == avatar_definition_const:
		return true
	else:
		return false


func _make_visible(p_visible: bool) -> void:
	if avatar_definition_editor:
		if p_visible:
			if option_button:
				option_button.show()
		else:
			if option_button:
				option_button.hide()
			avatar_definition_editor.edit(null)
