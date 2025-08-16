# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# godot_request_helper.gd
# SPDX-License-Identifier: MIT

@tool
extends RefCounted
class_name GodotRequestHelper

###

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

const LOCALHOST_HOST: String = "127.0.0.1"
const LOCALHOST_PORT: int = 4000

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
			% [
				get_string_for_requester_code(p_requester["requester_code"]),
				p_requester["generic_code"]
			]
		)

	if p_requester["requester_code"] == RequesterCode.HTTP_RESPONSE_NOT_OK:
		return (
			"%s (error code: %s)"
			% [
				get_string_for_requester_code(p_requester["requester_code"]),
				p_requester["response_code"]
			]
		)

	if p_requester["requester_code"] == RequesterCode.POLL_ERROR:
		return (
			"%s (error code: %s)"
			% [
				get_string_for_requester_code(p_requester["requester_code"]),
				p_requester["generic_code"]
			]
		)

	return get_string_for_requester_code(p_requester["requester_code"])


static func requester_result_is_ok(p_result) -> bool:
	return p_result.get("requester_code", RequesterCode.UNKNOWN_STATUS_ERROR) == RequesterCode.OK


static func requester_result_has_response(p_result) -> bool:
	return (
		p_result.get("requester_code", RequesterCode.UNKNOWN_STATUS_ERROR) == RequesterCode.OK
		or p_result.get("requester_code", RequesterCode.UNKNOWN_STATUS_ERROR) == RequesterCode.HTTP_RESPONSE_NOT_OK
	)

static func bool_to_string(p_bool: bool) -> String:
	if p_bool:
		return "true"
	else:
		return "false"


static func populate_query(p_query_name: String, p_query_dictionary: Dictionary) -> Dictionary:
	var query: Dictionary = {}

	for key in p_query_dictionary.keys():
		query["%s[%s]" % [p_query_name, key]] = p_query_dictionary[key]

	return query


static func get_api_path() -> String:
	return ""


static func get_value_of_type(p_data: Dictionary, p_key: String, p_type: int, p_default_value):
	var value = p_data.get(p_key, p_default_value)
	if typeof(value) == p_type:
		return value
	return p_default_value


## Returns a dictionary containing the username and domain from an account
## address. The address should be formatted as username@domain. If either
## can't be found, it will return a dictionary with an empty username
## and domain.
static func get_username_and_domain_from_address(p_address: String) -> Dictionary[String, String]:
	var result_dictionary: Dictionary[String, String] = {"username":"", "domain":""}
	if not p_address.is_empty():
		var splits: Array = p_address.split("@")
		if splits.size() == 2:
			result_dictionary["username"] = splits[0]
			result_dictionary["domain"] = splits[1]
	
	return result_dictionary
