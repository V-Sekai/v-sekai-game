# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# godot_uro_helper.gd
# SPDX-License-Identifier: MIT

@tool
extends RefCounted

enum UroUserContentType { UNKNOWN, AVATAR, MAP, PROP }

const LOCALHOST_HOST = "127.0.0.1"
const LOCALHOST_PORT = 4000

const DEFAULT_URO_HOST = LOCALHOST_HOST
const DEFAULT_URO_PORT = LOCALHOST_PORT

const API_PATH = "/api"
const API_VERSION = "/v1"

const SHOW_PATH = "/show"
const NEW_PATH = "/new"
const RENEW_PATH = "/renew"

const PROFILE_PATH = "/profile"
const SESSION_PATH = "/session"
const REGISTRATION_PATH = "/registration"
const IDENTITY_PROOFS_PATH = "/identity_proofs"
const AVATARS_PATH = "/avatars"
const MAPS_PATH = "/maps"
const SHARDS_PATH = "/shards"
const DASHBOARD_PATH = "/dashboard"

const DEFAULT_ACCOUNT_ID = "UNKNOWN_ID"
const DEFAULT_ACCOUNT_USERNAME = "UNKNOWN_USERNAME"
const DEFAULT_ACCOUNT_DISPLAY_NAME = "UNKNOWN_DISPLAY_NAME"

const UNTITLED_SHARD = "UNTITLED_SHARD"
const UNKNOWN_MAP = "UNKNOWN_MAP"

enum RequesterCode {
	OK = 0,
	CANCELLED,
	TERMINATED,
	CANT_CONNECT,
	CANT_RESOLVE,
	SSL_HANDSHAKE_ERROR,
	DISCONNECTED,
	CONNECTION_ERROR,
	UNKNOWN_STATUS_ERROR,
	FILE_ERROR,
	HTTP_RESPONSE_NOT_OK,
	NO_TOKEN,
	MALFORMED_RESPONSE_DATA,
	JSON_PARSE_ERROR,
	JSON_VALIDATE_ERROR,
	NO_RESPONSE_BODY,
	FAILED_TO_CONNECT,
	POLL_ERROR,
}


static func get_string_for_requester_code(p_requester_code: int) -> String:
	match p_requester_code:
		RequesterCode.OK:
			return "OK"
		RequesterCode.CANCELLED:
			return "CANCELLED"
		RequesterCode.TERMINATED:
			return "TERMINATED"
		RequesterCode.CANT_RESOLVE:
			return "CANT_RESOLVE"
		RequesterCode.SSL_HANDSHAKE_ERROR:
			return "SSL_HANDSHAKE_ERROR"
		RequesterCode.DISCONNECTED:
			return "DISCONNECTED"
		RequesterCode.CONNECTION_ERROR:
			return "CONNECTION_ERROR"
		RequesterCode.UNKNOWN_STATUS_ERROR:
			return "UNKNOWN_STATUS_ERROR"
		RequesterCode.FILE_ERROR:
			return "FILE_ERROR"
		RequesterCode.HTTP_RESPONSE_NOT_OK:
			return "HTTP_RESPONSE_NOT_OK"
		RequesterCode.NO_TOKEN:
			return "NO_TOKEN"
		RequesterCode.MALFORMED_RESPONSE_DATA:
			return "MALFORMED_RESPONSE_DATA"
		RequesterCode.JSON_PARSE_ERROR:
			return "JSON_PARSE_ERROR"
		RequesterCode.JSON_VALIDATE_ERROR:
			return "JSON_VALIDATE_ERROR"
		RequesterCode.NO_RESPONSE_BODY:
			return "NO_RESPONSE_BODY"
		RequesterCode.FAILED_TO_CONNECT:
			return "FAILED_TO_CONNECT"
		RequesterCode.POLL_ERROR:
			return "POLL_ERROR"
		_:
			return "UNKNOWN_REQUESTER_ERROR (" + str(p_requester_code) + ")"


static func get_full_requester_error_string(p_requester: Dictionary) -> String:
	if p_requester["requester_code"] == RequesterCode.FILE_ERROR:
		return (
			"%s (error code: %s)"
			% [get_string_for_requester_code(p_requester["requester_code"]), p_requester["generic_code"]]
		)
	elif p_requester["requester_code"] == RequesterCode.HTTP_RESPONSE_NOT_OK:
		return (
			"%s (error code: %s)"
			% [get_string_for_requester_code(p_requester["requester_code"]), p_requester["response_code"]]
		)
	elif p_requester["requester_code"] == RequesterCode.POLL_ERROR:
		return (
			"%s (error code: %s)"
			% [get_string_for_requester_code(p_requester["requester_code"]), p_requester["generic_code"]]
		)
	else:
		return get_string_for_requester_code(p_requester["requester_code"])


static func requester_result_is_ok(p_result) -> bool:
	if p_result["requester_code"] == RequesterCode.OK:
		return true
	else:
		return false


static func requester_result_has_response(p_result) -> bool:
	if (
		p_result["requester_code"] == RequesterCode.OK
		or p_result["requester_code"] == RequesterCode.HTTP_RESPONSE_NOT_OK
	):
		return true
	else:
		return false


static func populate_query(p_query_name: String, p_query_dictionary: Dictionary) -> Dictionary:
	var query: Dictionary = {}

	for key in p_query_dictionary.keys():
		query["%s[%s]" % [p_query_name, key]] = p_query_dictionary[key]

	return query


static func get_api_path() -> String:
	return API_PATH + API_VERSION


static func get_value_of_type(p_data: Dictionary, p_key: String, p_type: int, p_default_value):
	var value = p_data.get(p_key, p_default_value)
	if typeof(value) == p_type:
		return value
	else:
		return p_default_value


static func process_user_privilege_ruleset(p_data) -> Dictionary:
	var ruleset: Dictionary = {}

	if typeof(p_data) == TYPE_DICTIONARY:
		ruleset["is_admin"] = get_value_of_type(p_data, "is_admin", TYPE_BOOL, false)
		ruleset["can_upload_avatars"] = get_value_of_type(p_data, "can_upload_avatars", TYPE_BOOL, false)
		ruleset["can_upload_maps"] = get_value_of_type(p_data, "can_upload_maps", TYPE_BOOL, false)
		ruleset["can_upload_props"] = get_value_of_type(p_data, "can_upload_props", TYPE_BOOL, false)
	else:
		ruleset["is_admin"] = false
		ruleset["can_upload_avatars"] = false
		ruleset["can_upload_maps"] = false
		ruleset["can_upload_props"] = false

	return ruleset


static func process_session_json(p_input: Dictionary) -> Dictionary:
	if requester_result_has_response(p_input):
		if requester_result_is_ok(p_input):
			var output = p_input["output"]
			if output is Dictionary:
				var data = output.get("data")
				if data is Dictionary:
					var renewal_token: String = get_value_of_type(
						data, "renewal_token", TYPE_STRING, GodotUroData.renewal_token
					)
					var access_token: String = get_value_of_type(
						data, "access_token", TYPE_STRING, GodotUroData.access_token
					)

					var user: Dictionary = get_value_of_type(data, "user", TYPE_DICTIONARY, {})

					var user_id: String = get_value_of_type(user, "id", TYPE_STRING, DEFAULT_ACCOUNT_ID)
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

		else:
			var output = p_input.get("output")
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
	else:
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
					new_shard["name"] = get_value_of_type(shard, "name", TYPE_STRING, UNTITLED_SHARD)
					new_shard["current_users"] = get_value_of_type(shard, "current_users", TYPE_FLOAT, 0)
					new_shard["max_users"] = get_value_of_type(shard, "max_users", TYPE_FLOAT, 0)

					new_shards.push_back(new_shard)

	result_dict["requester_code"] = p_input["requester_code"]
	result_dict["generic_code"] = p_input["generic_code"]
	result_dict["response_code"] = p_input["response_code"]
	result_dict["output"] = {"data": {"shards": new_shards}}
	return result_dict
