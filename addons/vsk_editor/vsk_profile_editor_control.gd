# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_profile_editor_control.gd
# SPDX-License-Identifier: MIT

@tool
extends Control

var vsk_editor: Node = null

const MARGIN_SIZE = 32

@export var profile_container: NodePath = NodePath()

@export var tab_container: NodePath = NodePath()
@export var profile_tab: NodePath = NodePath()
@export var avatars_tab: NodePath = NodePath()
@export var maps_tab: NodePath = NodePath()
@export var avatars_grid: NodePath = NodePath()
@export var maps_grid: NodePath = NodePath()

var avatar_dictionary: Dictionary = {}
var map_dictionary: Dictionary = {}

signal session_deletion_successful

var vbox_container: VBoxContainer = null
var info_label: Label = null
var sign_out_button: Button = null


func _session_deletion_complete(p_code: int, _message: String) -> void:
	if p_code == GodotUro.godot_uro_helper_const.RequesterCode.OK:
		session_deletion_successful.emit()

	sign_out_button.disabled = false


func _sign_out_button_pressed() -> void:
	sign_out_button.disabled = true
	vsk_editor.sign_out()


func _ready():
	vbox_container = get_node(profile_container)

	info_label = Label.new()
	info_label.set_text("Signed in as: {display_name}".format({"display_name": VSKAccountManager.account_display_name}))
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	sign_out_button = Button.new()
	sign_out_button.set_text("Log out")
	if sign_out_button.pressed.connect(self._sign_out_button_pressed) != OK:
		printerr("Could not connect signal 'pressed'")

	vbox_container.add_child(info_label, true)
	vbox_container.add_child(sign_out_button, true)

	vbox_container.set_anchors_and_offsets_preset(PRESET_FULL_RECT, PRESET_MODE_MINSIZE, 0)
	vbox_container.offset_top = 0
	vbox_container.offset_left = MARGIN_SIZE
	vbox_container.offset_bottom = -MARGIN_SIZE
	vbox_container.offset_right = -MARGIN_SIZE

	assert(vsk_editor)
	if vsk_editor.session_deletion_complete.connect(self._session_deletion_complete) != OK:
		printerr("Could not connect signal 'session_deletion_complete'")

	var avatars_grid_node: Control = get_node_or_null(avatars_grid)
	if avatars_grid_node:
		if avatars_grid_node.vsk_content_button_pressed.connect(self._avatar_selected) != OK:
			printerr("Could not connect signal 'vsk_content_button_pressed'")

	var maps_grid_node: Control = get_node_or_null(maps_grid)
	if maps_grid_node:
		if maps_grid_node.vsk_content_button_pressed.connect(self._map_selected) != OK:
			printerr("Could not connect signal 'vsk_content_button_pressed'")


func _avatar_selected(p_id: String) -> void:
	if avatar_dictionary.has(p_id):
		DisplayServer.clipboard_set(p_id)
	else:
		printerr("Could not select avatar %s" % p_id)


func _map_selected(p_id: String) -> void:
	if map_dictionary.has(p_id):
		DisplayServer.clipboard_set(p_id)
	else:
		printerr("Could not select map %s" % p_id)


func _reload_avatars() -> void:
	get_node(avatars_grid).clear_all()

	var async_result = await GodotUro.godot_uro_api.dashboard_get_avatars_async()
	if GodotUro.godot_uro_helper_const.requester_result_is_ok(async_result):
		var avatar_list = async_result["output"]["data"]["avatars"]
		avatar_dictionary = {}

		for avatar in avatar_list:
			var id: String = avatar["id"]

			avatar_dictionary[id] = {"name": avatar["name"], "description": avatar["description"], "user_content_preview_url": GodotUro.get_base_url() + avatar["user_content_preview"], "user_content_data_url": GodotUro.get_base_url() + avatar["user_content_data"]}

			get_node(avatars_grid).add_item(id, avatar["name"], GodotUro.get_base_url() + avatar["user_content_preview"])
	else:
		printerr("Dashboard avatars returned with error %s" % GodotUro.godot_uro_helper_const.get_full_requester_error_string(async_result))


func _reload_maps() -> void:
	get_node(maps_grid).clear_all()

	var async_result = await GodotUro.godot_uro_api.dashboard_get_maps_async()
	if GodotUro.godot_uro_helper_const.requester_result_is_ok(async_result):
		var map_list = async_result["output"]["data"]["maps"]
		map_dictionary = {}

		for map in map_list:
			var id: String = map["id"]

			map_dictionary[id] = {"name": map["name"], "description": map["description"], "user_content_preview_url": GodotUro.get_base_url() + map["user_content_preview"], "user_content_data_url": GodotUro.get_base_url() + map["user_content_data"]}

			get_node(maps_grid).add_item(id, map["name"], GodotUro.get_base_url() + map["user_content_preview"])
	else:
		printerr("Dashboard maps returned with error %s" % GodotUro.godot_uro_helper_const.get_full_requester_error_string(async_result))


func _on_tab_changed(tab):
	var tab_child: Control = get_node(tab_container).get_child(tab)
	if tab_child == get_node(profile_tab):
		pass
	elif tab_child == get_node(avatars_tab):
		await _reload_avatars()
	elif tab_child == get_node(maps_tab):
		await _reload_maps()


func set_vsk_editor(p_vsk_editor: Node) -> void:
	vsk_editor = p_vsk_editor
