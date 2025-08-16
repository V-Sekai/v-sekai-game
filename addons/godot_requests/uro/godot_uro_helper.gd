# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# godot_uro_helper.gd
# SPDX-License-Identifier: MIT

@tool
extends GodotRequestHelper
class_name GodotUroHelper

static func _get_upload_data_for_file(p_file_path: String) -> Dictionary:
	var file: FileAccess = FileAccess.open(p_file_path, FileAccess.READ)
	if file:
		var buffer = file.get_buffer(file.get_length())
		return {
			"filename": p_file_path.get_file(),
			"content_type": "application/octet-stream",
			"data": buffer
		}

	push_error("Failed to get upload data!")
	return {}


static func _get_raw_png_from_image(p_image: Image) -> Dictionary:
	return {
		"filename": "autogen.png", "content_type": "image/png", "data": p_image.save_png_to_buffer()
	}

###

enum UroUserContentType { UNKNOWN, AVATAR, MAP, PROP }

const API_PATH: String = "/api"
const API_VERSION: String = "/v1"
const SHOW_PATH: String = "/show"
const NEW_PATH: String = "/new"
const RENEW_PATH: String = "/renew"
const PROFILE_PATH: String = "/profile"
const SESSION_PATH: String = "/session"
const REGISTRATION_PATH: String = "/registration"
const IDENTITY_PROOFS_PATH: String = "/identity_proofs"
const NATIVE_OAUTH_PATH: String = "/login/native"
const AVATARS_PATH: String = "/avatars"
const MAPS_PATH: String = "/maps"
const SHARDS_PATH: String = "/shards"
const DASHBOARD_PATH: String = "/dashboard"
const DEFAULT_ACCOUNT_ID: String = "UNKNOWN_ID"
const DEFAULT_ACCOUNT_USERNAME: String = "UNKNOWN_USERNAME"
const DEFAULT_ACCOUNT_DISPLAY_NAME: String = "UNKNOWN_DISPLAY_NAME"
const UNTITLED_SHARD: String = "UNTITLED_SHARD"
const UNKNOWN_MAP: String = "UNKNOWN_MAP"
const SIGNUP_API_KEY = "eNoZ4kXHgT0z9ZTYGsq7eE0rQYvR6YBi"


static func get_api_path() -> String:
	return API_PATH + API_VERSION


static func process_user_privilege_ruleset(p_data) -> Dictionary:
	var ruleset: Dictionary = {}

	if typeof(p_data) == TYPE_DICTIONARY:
		ruleset["is_admin"] = get_value_of_type(p_data, "is_admin", TYPE_BOOL, false)
		ruleset["can_upload_avatars"] = get_value_of_type(
			p_data, "can_upload_avatars", TYPE_BOOL, false
		)
		ruleset["can_upload_maps"] = get_value_of_type(p_data, "can_upload_maps", TYPE_BOOL, false)
		ruleset["can_upload_props"] = get_value_of_type(
			p_data, "can_upload_props", TYPE_BOOL, false
		)
	else:
		ruleset["is_admin"] = false
		ruleset["can_upload_avatars"] = false
		ruleset["can_upload_maps"] = false
		ruleset["can_upload_props"] = false

	return ruleset


static func process_session_json(p_input: Dictionary, p_renewal_token: String, p_access_token: String) -> Dictionary:
	if requester_result_has_response(p_input):
		var output: Variant
		if requester_result_is_ok(p_input):
			output = p_input["output"]
			if output is Dictionary:
				var data = output.get("data")
				if data is Dictionary:
					var renewal_token: String = get_value_of_type(
						data, "renewal_token", TYPE_STRING, p_renewal_token
					)
					var access_token: String = get_value_of_type(
						data, "access_token", TYPE_STRING, p_access_token
					)
					
					var user: Dictionary = get_value_of_type(data, "user", TYPE_DICTIONARY, {})
					
					var user_id: String = get_value_of_type(
						user, "id", TYPE_STRING, DEFAULT_ACCOUNT_ID
					)
					var user_username: String = get_value_of_type(
						user, "username", TYPE_STRING, DEFAULT_ACCOUNT_USERNAME
					)
					var user_display_name: String = get_value_of_type(
						user, "display_name", TYPE_STRING, DEFAULT_ACCOUNT_DISPLAY_NAME
					)

					var user_privilege_ruleset: Dictionary = process_user_privilege_ruleset(
						data.get("user_privilege_ruleset")
					)

					return {
						"requester_code": p_input["requester_code"],
						"generic_code": p_input["generic_code"],
						"response_code": p_input["response_code"],
						"message": "Success!",
						"renewal_token": renewal_token,
						"access_token": access_token,
						"user_id": user_id,
						"user_username": user_username,
						"user_display_name": user_display_name,
						"user_privilege_ruleset": user_privilege_ruleset
					}
			return {
				"requester_code": RequesterCode.MALFORMED_RESPONSE_DATA,
				"generic_code": p_input["generic_code"],
				"response_code": p_input["response_code"],
				"message": "Malformed response data!",
			}

		output = p_input.get("output")
		if output is Dictionary:
			var error = output.get("error")
			if error is Dictionary:
				var message = error.get("message")
				if message is String:
					return {
						"requester_code": p_input["requester_code"],
						"generic_code": p_input["generic_code"],
						"response_code": p_input["response_code"],
						"message": message
					}

		return {
			"requester_code": RequesterCode.MALFORMED_RESPONSE_DATA,
			"generic_code": p_input["generic_code"],
			"response_code": p_input["response_code"],
			"message": get_full_requester_error_string(p_input)
		}

	return {
		"requester_code": p_input["requester_code"],
		"generic_code": p_input["generic_code"],
		"response_code": p_input["response_code"],
		"message": get_full_requester_error_string(p_input)
	}


static func process_shards_json(p_input: Dictionary) -> Dictionary:
	var result_dict: Dictionary = {}
	var new_shards: Array = []

	var data = p_input["output"].get("data")
	if data is Dictionary:
		var shards = data.get("shards")
		if shards is Array:
			for shard in shards:
				if shard is Dictionary:
					var new_shard: Dictionary = {}
					new_shard["user"] = get_value_of_type(shard, "user", TYPE_STRING, "")
					new_shard["address"] = get_value_of_type(shard, "address", TYPE_STRING, "")
					new_shard["port"] = get_value_of_type(shard, "port", TYPE_FLOAT, -1)
					new_shard["map"] = get_value_of_type(shard, "map", TYPE_STRING, UNKNOWN_MAP)
					new_shard["name"] = get_value_of_type(
						shard, "name", TYPE_STRING, UNTITLED_SHARD
					)
					new_shard["current_users"] = get_value_of_type(
						shard, "current_users", TYPE_FLOAT, 0
					)
					new_shard["max_users"] = get_value_of_type(shard, "max_users", TYPE_FLOAT, 0)

					new_shards.push_back(new_shard)

	result_dict["requester_code"] = p_input["requester_code"]
	result_dict["generic_code"] = p_input["generic_code"]
	result_dict["response_code"] = p_input["response_code"]
	result_dict["output"] = {"data": {"shards": new_shards}}
	return result_dict


## Returns a dictionary formatted with all the information required to
## upload a piece of user-generated content.
static func create_content_upload_dictionary(
	p_name: String,
	p_description: String,
	p_file_path: String,
	p_image: Image,
	p_is_public: bool
) -> Dictionary:
	var dictionary: Dictionary = {
		"name": p_name, "description": p_description, "is_public": p_is_public
	}

	var user_content_data: Dictionary = _get_upload_data_for_file(p_file_path)
	if !user_content_data.is_empty():
		dictionary["user_content_data"] = user_content_data
	else:
		return {}
		
	if p_image:
		dictionary["user_content_preview"] = _get_raw_png_from_image(p_image)
	
	return dictionary
