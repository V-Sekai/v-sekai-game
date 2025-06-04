# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_prop_plugin.gd
# SPDX-License-Identifier: MIT

@tool
extends EditorPlugin

const vsk_prop_definition_editor_const = preload(
	"res://addons/vsk_prop/vsk_prop_definition_editor.gd"
)

var editor_interface: EditorInterface = null
var prop_definition_editor: Control = null

var option_button: MenuButton = null

var current_edited_object: Object = null


func _init():
	print("Initialising VSKProp plugin")


func _notification(p_notification: int):
	match p_notification:
		NOTIFICATION_PREDELETE:
			print("Destroying VSKProp plugin")


func _get_plugin_name() -> String:
	return "VSKProp"


func _menu_option(p_id: int) -> void:
	if prop_definition_editor:
		prop_definition_editor._menu_option(p_id)


func update_menu_options(p_current_node: Node3D) -> void:
	if option_button:
		option_button.get_popup().clear()
		# If we have a valid node, add the define button
		if p_current_node:
			# If we have a valid script, and the export and upload buttons
			var current_script: Script = p_current_node.get_script()
			if (
				current_script == vsk_prop_definition_editor_const.vsk_prop_definition_const
				or (
					current_script
					== vsk_prop_definition_editor_const.vsk_prop_definition_runtime_const
				)
			):
				option_button.get_popup().add_item(
					"Export Prop", vsk_prop_definition_editor_const.MENU_OPTION_EXPORT_PROP
				)
				option_button.get_popup().add_item(
					"Upload Prop", vsk_prop_definition_editor_const.MENU_OPTION_UPLOAD_PROP
				)
			elif current_script == null:
				option_button.get_popup().add_item(
					"Define Prop", vsk_prop_definition_editor_const.MENU_OPTION_INIT_PROP
				)


func _enter_tree() -> void:
	editor_interface = get_editor_interface()
	prop_definition_editor = vsk_prop_definition_editor_const.new(self)

	option_button = MenuButton.new()
	option_button.set_switch_on_hover(true)

	option_button.set_text("Prop Definition")

	option_button.get_popup().id_pressed.connect(self._menu_option)
	option_button.hide()

	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, prop_definition_editor)
	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, option_button)


func _exit_tree() -> void:
	if option_button:
		remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, option_button)
		if option_button.is_inside_tree():
			option_button.get_parent().remove_child(option_button)
		option_button.queue_free()

	if prop_definition_editor:
		if prop_definition_editor.is_inside_tree():
			prop_definition_editor.get_parent().remove_child(prop_definition_editor)
		prop_definition_editor.queue_free()


func refresh_edited_object() -> void:
	if is_instance_valid(current_edited_object):
		var node: Node = current_edited_object
		if node and node.is_inside_tree():
			get_editor_interface().edit_node(current_edited_object)


func _edit(p_object: Object) -> void:
	current_edited_object = p_object

	if not current_edited_object:
		return

	if !current_edited_object.is_connected(
		"script_changed", Callable(self, "refresh_edited_object")
	):
		var connection_result = current_edited_object.connect(
			"script_changed", Callable(self, "refresh_edited_object"), CONNECT_DEFERRED
		)
		if connection_result != OK:
			push_error("Error: Failed to connect 'script_changed' signal.")
			return

	prop_definition_editor.edit(current_edited_object)
	update_menu_options(current_edited_object)


func _handles(p_object: Object) -> bool:
	if p_object != null and p_object != current_edited_object:
		if current_edited_object and is_instance_valid(current_edited_object):
			if current_edited_object.is_connected("script_changed", refresh_edited_object):
				current_edited_object.disconnect("script_changed", refresh_edited_object)
		current_edited_object = null

	if not p_object is Node3D:
		return false

	var current_script: Script = p_object.get_script()
	if (
		current_script == vsk_prop_definition_editor_const.vsk_prop_definition_const
		or current_script == vsk_prop_definition_editor_const.vsk_prop_definition_runtime_const
		or current_script == null
	):
		return true

	return false


func _make_visible(p_visible: bool) -> void:
	if not prop_definition_editor:
		return
	if p_visible:
		if option_button:
			print("Show vsk_prop_menu.")
			option_button.show()
	else:
		if option_button:
			option_button.hide()
		prop_definition_editor.edit(null)
