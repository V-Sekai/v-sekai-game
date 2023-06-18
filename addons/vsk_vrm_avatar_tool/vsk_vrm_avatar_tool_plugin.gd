# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_vrm_avatar_tool_plugin.gd
# SPDX-License-Identifier: MIT

@tool
extends EditorPlugin

var option_button: MenuButton = null

const vrm_logo = null  #preload("vrm_v_logo_16.png")
const vrm_toplevel_const = preload("res://addons/vrm/vrm_toplevel.gd")

const vsk_vrm_avatar_converter_editor_const = preload("./vsk_vrm_avatar_converter_editor.gd")
var vsk_vrm_avatar_converter_editor: Node = null


func _init():
	print("Initialising VSKVRMAvatarTool plugin")


func _notification(p_notification: int):
	match p_notification:
		NOTIFICATION_PREDELETE:
			print("Destroying VSKVRMAvatarTool plugin")


func _get_plugin_name() -> String:
	return "VSKVRMAvatarTool"


func _menu_option(p_id: int) -> void:
	if vsk_vrm_avatar_converter_editor:
		vsk_vrm_avatar_converter_editor.menu_option(p_id)


func _enter_tree() -> void:
	vsk_vrm_avatar_converter_editor = vsk_vrm_avatar_converter_editor_const.new(self)

	call_deferred("add_child", vsk_vrm_avatar_converter_editor, true)

	option_button = MenuButton.new()
	option_button.set_switch_on_hover(true)

	add_control_to_container(CONTAINER_SPATIAL_EDITOR_MENU, option_button)
	option_button.set_text("VRM")
	option_button.set_button_icon(vrm_logo)
	option_button.get_popup().add_item("Convert to VSK Avatar", vsk_vrm_avatar_converter_editor_const.MENU_OPTION_CONVERT_TO_VSK_AVATAR)

	option_button.get_popup().id_pressed.connect(self._menu_option)
	option_button.hide()


func _exit_tree() -> void:
	if option_button:
		remove_control_from_container(CONTAINER_SPATIAL_EDITOR_MENU, option_button)
		if option_button.is_inside_tree():
			option_button.get_parent().remove_child(option_button)
		option_button.queue_free()

	if vsk_vrm_avatar_converter_editor:
		if vsk_vrm_avatar_converter_editor.is_inside_tree():
			vsk_vrm_avatar_converter_editor.get_parent().remove_child(vsk_vrm_avatar_converter_editor)
		vsk_vrm_avatar_converter_editor.queue_free()


func _edit(p_object: Object) -> void:
	if p_object is Node and typeof(p_object.get("vrm_meta")) != TYPE_NIL:
		if vsk_vrm_avatar_converter_editor:
			vsk_vrm_avatar_converter_editor.edit(p_object)


func _handles(p_object: Object) -> bool:
	if p_object != null and p_object.get_script() == vrm_toplevel_const:
		return true
	else:
		return false


func _make_visible(p_visible: bool) -> void:
	if p_visible:
		if option_button:
			option_button.show()
	else:
		if option_button:
			option_button.hide()
		if vsk_vrm_avatar_converter_editor:
			vsk_vrm_avatar_converter_editor.edit(null)
