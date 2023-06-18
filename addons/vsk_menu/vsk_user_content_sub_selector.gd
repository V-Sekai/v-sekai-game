# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_user_content_sub_selector.gd
# SPDX-License-Identifier: MIT

extends Control

const vsk_user_content_selector_const = preload("./vsk_user_content_selector.gd")

const SIGN_IN_REQUIRED_MESSAGE = "Please sign in to view your uploaded content..."
const REQUEST_PENDING_MESSAGE = "Loading..."
const INVALID_DATA_MESSAGE = "Data received from server was not valid!"
const INVALID_CONTENT_TYPE_MESSAGE = "Invalid content type!"

const INVALID_NAME = "MISSING_NAME"
const INVALID_DESCRIPTION = "MISSING_DESC"

@export var grid_path: NodePath = NodePath()
@export var message_path: NodePath = NodePath()

@export var load_content_on_creation: bool = false

signal uro_id_selected(p_id)

var content_dictionary: Dictionary = {}

@export var public_content: bool = true
@export_enum("Avatars", "Maps") var content_type: int = vsk_user_content_selector_const.ContentType.CONTENT_AVATARS


func refresh() -> void:
	await _reload_content()


func _get_result_data(p_result: Dictionary) -> Dictionary:
	var return_dict = {"error": FAILED, "data": null}

	if p_result.has("output"):
		if p_result["output"].has("data"):
			return_dict["error"] = OK
			return_dict["data"] = p_result["output"]["data"]

	return return_dict


func _update_message(p_string: String) -> void:
	get_node(grid_path).hide()

	get_node(message_path).set_text(p_string)
	get_node(message_path).show()


func _update_grid() -> void:
	get_node(grid_path).show()

	get_node(message_path).set_text("")
	get_node(message_path).hide()


func _parse_avatars_result(p_result: Dictionary) -> Dictionary:
	var return_dict: Dictionary = {"error": OK, "message": ""}

	# Parse the data
	var dict: Dictionary = _get_result_data(p_result)
	if dict["error"] != OK:
		return_dict["error"] = dict["error"]
		return_dict["message"] = INVALID_DATA_MESSAGE
		return return_dict

	var avatar_list = null
	if dict["data"].has("avatars"):
		avatar_list = dict["data"]["avatars"]

	if typeof(avatar_list) != TYPE_ARRAY:
		return_dict["error"] = dict["error"]
		return_dict["message"] = INVALID_DATA_MESSAGE
		return return_dict

	# Start populating the grid
	_update_grid()

	content_dictionary = {}
	for avatar in avatar_list:
		var id: String = avatar["id"]

		var item_name: String = str(avatar.get("name", INVALID_NAME))
		var item_description: String = str(avatar.get("description", INVALID_DESCRIPTION))
		var item_preview_url: String = ""
		var item_data_url: String = ""

		if avatar.has("user_content_preview"):
			item_preview_url = GodotUro.get_base_url() + avatar["user_content_preview"]
		if avatar.has("user_content_data"):
			item_data_url = GodotUro.get_base_url() + avatar["user_content_data"]

		content_dictionary[id] = {"name": item_name, "description": item_description, "user_content_preview_url": item_data_url, "user_content_data_url": item_preview_url}

		get_node(grid_path).add_item(id, item_name, item_preview_url)

	return return_dict


func _parse_maps_result(p_result: Dictionary) -> Dictionary:
	var return_dict: Dictionary = {"error": OK, "message": ""}

	# Parse the data
	var dict: Dictionary = _get_result_data(p_result)
	if dict["error"] != OK:
		return_dict["error"] = dict["error"]
		return_dict["message"] = INVALID_DATA_MESSAGE
		return return_dict

	var map_list = null
	if dict["data"].has("maps"):
		map_list = dict["data"]["maps"]
	elif dict["data"].has("avatars"):  # TEMPORARY WORKAROUND FOR API BUG
		map_list = dict["data"]["avatars"]

	if typeof(map_list) != TYPE_ARRAY:
		return_dict["error"] = dict["error"]
		return_dict["message"] = INVALID_DATA_MESSAGE
		return return_dict

	# Start populating the grid
	_update_grid()

	for map in map_list:
		var id: String = map["id"]

		var item_name: String = str(map.get("name", INVALID_NAME))
		var item_description: String = str(map.get("description", INVALID_DESCRIPTION))
		var item_preview_url: String = ""
		var item_data_url: String = ""
		if map.has("user_content_preview"):
			item_preview_url = GodotUro.get_base_url() + map["user_content_preview"]
		if map.has("user_content_data"):
			item_data_url = GodotUro.get_base_url() + map["user_content_data"]

		content_dictionary[id] = {"name": item_name, "description": item_description, "user_content_preview_url": item_data_url, "user_content_data_url": item_preview_url}

		get_node(grid_path).add_item(id, item_name, item_preview_url)

	return return_dict


func _reload_public_avatars() -> Dictionary:
	var return_dict: Dictionary = {"error": OK, "message": ""}

	var async_result = await GodotUro.godot_uro_api.get_avatars_async()
	if GodotUro.godot_uro_helper_const.requester_result_is_ok(async_result):
		return_dict = _parse_avatars_result(async_result)
	else:
		return_dict["error"] = FAILED
		return_dict["message"] = GodotUro.godot_uro_helper_const.get_full_requester_error_string(async_result)

	return return_dict


func _reload_public_maps() -> Dictionary:
	var return_dict: Dictionary = {"error": OK, "message": ""}

	var async_result = await GodotUro.godot_uro_api.get_maps_async()
	if GodotUro.godot_uro_helper_const.requester_result_is_ok(async_result):
		return_dict = _parse_maps_result(async_result)
	else:
		return_dict["error"] = FAILED
		return_dict["message"] = GodotUro.godot_uro_helper_const.get_full_requester_error_string(async_result)

	return return_dict


func _reload_dashboard_avatars() -> Dictionary:
	var return_dict: Dictionary = {"error": OK, "message": ""}

	if !VSKAccountManager.is_signed_in():
		return_dict["error"] = FAILED
		return_dict["message"] = SIGN_IN_REQUIRED_MESSAGE
		return return_dict

	var async_result = await GodotUro.godot_uro_api.dashboard_get_avatars_async()
	if GodotUro.godot_uro_helper_const.requester_result_is_ok(async_result):
		return_dict = _parse_avatars_result(async_result)
	else:
		return_dict["error"] = FAILED
		return_dict["message"] = GodotUro.godot_uro_helper_const.get_full_requester_error_string(async_result)

	return return_dict


func _reload_dashboard_maps() -> Dictionary:
	var return_dict: Dictionary = {"error": OK, "message": ""}

	if !VSKAccountManager.is_signed_in():
		return_dict["error"] = FAILED
		return_dict["message"] = SIGN_IN_REQUIRED_MESSAGE
		return return_dict

	var async_result = await GodotUro.godot_uro_api.dashboard_get_maps_async()
	if GodotUro.godot_uro_helper_const.requester_result_is_ok(async_result):
		return_dict = _parse_maps_result(async_result)
	else:
		return_dict["error"] = FAILED
		return_dict["message"] = GodotUro.godot_uro_helper_const.get_full_requester_error_string(async_result)

	return return_dict


func _reload_content() -> void:
	get_node(grid_path).clear_all()

	get_node(grid_path).hide()
	get_node(message_path).show()

	get_node(message_path).set_text(REQUEST_PENDING_MESSAGE)

	var result: Dictionary = {"error": OK, "message": ""}

	match content_type:
		vsk_user_content_selector_const.ContentType.CONTENT_AVATARS:
			if public_content:
				result = await _reload_public_avatars()
			else:
				result = await _reload_dashboard_avatars()
		vsk_user_content_selector_const.ContentType.CONTENT_MAPS:
			if public_content:
				result = await _reload_public_maps()
			else:
				result = await _reload_dashboard_maps()
		_:
			result["error"] = FAILED
			result["message"] = INVALID_CONTENT_TYPE_MESSAGE

	if result["error"] != OK:
		_update_message(result["message"])


func _on_vsk_content_button_pressed(p_id: String) -> void:
	uro_id_selected.emit(p_id)


func _ready() -> void:
	if load_content_on_creation:
		call_deferred("_reload_content")
