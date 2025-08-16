# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# godot_requester.gd
# SPDX-License-Identifier: MIT

@tool
extends RefCounted
class_name GodotRequester

const BOUNDARY_UID_LENGTH = 32
const YIELD_PERIOD_MS = 50

class Result:
	var requester_code: int = -1
	var generic_code: int = -1
	var response_code: int = -1
	var response_headers: Dictionary = {}
	var data: Dictionary = {}

	func _init(
		p_requester_code: int, p_generic_code: int, p_response_code: int, p_response_headers: Dictionary = {}, p_data: Dictionary = {}
	):
		requester_code = p_requester_code
		generic_code = p_generic_code
		response_code = p_response_code
		response_headers = p_response_headers
		data = p_data


const DEFAULT_OPTIONS: Dictionary = {
	"method": HTTPClient.METHOD_GET,
	"encoding": "query",
	"multipart_boundary_prefix": "",
	"token": null,
	"auth_scheme": "Bearer",
	"extra_headers": null,
	"download_to": null,
}

var _http_pool: HTTPPool = null

var _hostname: String = ""
var _port: int = -1
var _use_ssl: bool = true
var _http_query_string: HTTPClient = HTTPClient.new()  # for non-static query_string_from_dict

var http_state: HTTPPool.HTTPState = null

##
var _has_enhanced_qs_from_dict: bool = false
##


func _init(p_http_pool: HTTPPool, p_hostname: String, p_port: int = -1, p_use_ssl: bool = true):
	_http_pool = p_http_pool
	_hostname = p_hostname
	_port = p_port
	_use_ssl = p_use_ssl

	_has_enhanced_qs_from_dict = _http_query_string.query_string_from_dict({"a": null}) == "a"

static func get_status_error_response(p_status: int) -> Result:
	match p_status:
		HTTPClient.STATUS_CANT_CONNECT:
			return Result.new(GodotRequestHelper.RequesterCode.CANT_CONNECT, FAILED, -1)
		HTTPClient.STATUS_CANT_RESOLVE:
			return Result.new(GodotRequestHelper.RequesterCode.CANT_RESOLVE, FAILED, -1)
		HTTPClient.STATUS_TLS_HANDSHAKE_ERROR:
			return Result.new(GodotRequestHelper.RequesterCode.SSL_HANDSHAKE_ERROR, FAILED, -1)
		HTTPClient.STATUS_DISCONNECTED:
			return Result.new(GodotRequestHelper.RequesterCode.DISCONNECTED, FAILED, -1)
		HTTPClient.STATUS_CONNECTION_ERROR:
			return Result.new(GodotRequestHelper.RequesterCode.CONNECTION_ERROR, FAILED, -1)
		_:
			return Result.new(GodotRequestHelper.RequesterCode.UNKNOWN_STATUS_ERROR, FAILED, -1)


func get_default_options() -> Dictionary:
	return DEFAULT_OPTIONS.duplicate(true)


func http_download_progressed(_http_state: RefCounted, _bytes: int, _total_bytes: int):
	#print("Download progressed " + str(bytes) + "/" + str(total_bytes))
	pass


func request(
	p_path: String,
	p_payload: Dictionary,
	p_token: String,
	p_options: Dictionary = {}) -> Result:
	if p_options.is_empty():
		p_options = get_default_options()
	if http_state:
		push_error("HTTP state is already active for this request")
		return Result.new(GodotRequestHelper.RequesterCode.CANT_CONNECT, ERR_CANT_CREATE, -1)
		
	http_state = await _http_pool.new_http_state()
	if http_state == null:
		return Result.new(GodotRequestHelper.RequesterCode.CANT_CONNECT, ERR_CANT_CREATE, -1)

	var download_prog_callable = self.http_download_progressed.bind(http_state)
	if p_options.get("download_to"):
		http_state.set_output_path(_get_option(p_options, "download_to"))
		http_state.download_progressed.connect(download_prog_callable)

	var http_client: HTTPClient = null
	for i in range(3):
		http_client = await http_state.connect_http(_hostname, _port, _use_ssl)
		if http_client != null:
			break

	if http_client == null:
		var err: int = http_state.connect_err
		if err == OK:
			err = FAILED
		http_state.release()
		http_state = null
		return Result.new(GodotRequestHelper.RequesterCode.CANT_CONNECT, err, -1)

	var uri: String = p_path
	var encoded_payload: PackedByteArray = PackedByteArray()
	var headers: Array = []

	if p_token:
		# TODO: Allow different auth header schemes
		headers.push_back("Authorization: Bearer %s" % p_token)

	var extra_headers: Array = p_options.get("extra_headers", [])
	if not extra_headers.is_empty():
		headers.append_array(extra_headers)

	if p_payload:
		var encoding: String = _get_option(p_options, "encoding")
		match encoding:
			"query":
				uri += "?%s" % _dict_to_query_string(p_payload)
			"json":
				headers.append("Content-Type: application/json")
				var payload_string: String = JSON.stringify(p_payload)
				encoded_payload = payload_string.to_utf8_buffer()
			"form":
				headers.append("Content-Type: application/x-www-form-urlencoded")
				var payload_string: String = _dict_to_query_string(p_payload)
				encoded_payload = payload_string.to_utf8_buffer()
			"multipart":
				var boundary_prefix: String = _get_option(p_options, "multipart_boundary_prefix")
				var boundary_string: String = (
					boundary_prefix
					+ RandomizationUtilities.generate_insecure_unique_id(BOUNDARY_UID_LENGTH)
				)
				headers.append("Content-Type: multipart/form-data; boundary=%s" % boundary_string)
				encoded_payload = GodotRequester._compose_multipart_body(
					p_payload, boundary_string
				)
			_:
				push_error("Unknown encoding type!")
				self._internal_request_done.emit()

	var token = _get_option(p_options, "token")
	if token and token is String:
		var auth_scheme = _get_option(p_options, "auth_scheme")
		headers.append("Authorization: %s %s" % [auth_scheme, token])

	var request_result = http_client.request_raw(
		_get_option(p_options, "method"), uri, headers, encoded_payload
	)
	if request_result != OK:
		push_error("Failed to send request.")
		return

	if not await http_state.wait_for_request():
		var ret = get_status_error_response(http_client.get_status())
		http_state.release()
		http_state = null
		return ret

	if p_options.get("download_to"):
		http_state.download_progressed.disconnect(download_prog_callable)

	var data: Dictionary = {}
	var response_headers: Dictionary = http_state.response_headers
	var response_body: String = http_state.response_body.get_string_from_utf8()
	var response_code: int = http_state.response_code
	http_state.release()
	http_state = null
	if response_body:
		var json_parse_result = JSON.new()
		if json_parse_result.parse(response_body) == OK:
			if typeof(json_parse_result.get_data()) == TYPE_DICTIONARY:
				data = json_parse_result.get_data()
			else:
				data = {"data": str(json_parse_result.get_data())}
			if response_code == HTTPClient.RESPONSE_OK:
				return Result.new(GodotRequestHelper.RequesterCode.OK, OK, response_code, response_headers, data)
			else:
				return Result.new(
					GodotRequestHelper.RequesterCode.HTTP_RESPONSE_NOT_OK,
					FAILED,
					response_code,
					response_headers,
					data
				)
		else:
			if response_code == HTTPClient.RESPONSE_OK:
				return Result.new(
					GodotRequestHelper.RequesterCode.JSON_PARSE_ERROR,
					FAILED,
					response_code,
					response_headers,
					data
				)
			else:
				return Result.new(
					GodotRequestHelper.RequesterCode.HTTP_RESPONSE_NOT_OK,
					FAILED,
					response_code,
					response_headers,
					data
				)
	else:
		# TODO: Handle responses codes like 3xx as ok
		push_error("GodotRequester: No response body!")
		return Result.new(
			GodotRequestHelper.RequesterCode.UNKNOWN_STATUS_ERROR, FAILED, response_code, response_headers, data
		)


func _get_option(options, key):
	var default_opts: Dictionary = get_default_options()
	return options[key] if options.has(key) else default_opts[key]


static func _compose_multipart_body(
	p_dictionary: Dictionary, p_boundary_string: String
) -> PackedByteArray:
	var buffer: PackedByteArray = PackedByteArray()
	for key in p_dictionary.keys():
		buffer.append_array(("\r\n--" + p_boundary_string + "\r\n").to_utf8_buffer())
		var value = p_dictionary[key]
		if value is String:
			var disposition: PackedByteArray = (
				('Content-Disposition: form-data; name="%s"\r\n\r\n' % key).to_utf8_buffer()
			)
			var body: PackedByteArray = value.to_utf8_buffer()

			buffer.append_array(disposition)
			buffer.append_array(body)
		elif value is Dictionary:
			var content_type: String = value.get("content_type")
			var filename: String = value.get("filename")
			var data: PackedByteArray = value.get("data")

			var disposition = (
				(
					'Content-Disposition: form-data; name="%s"; filename="%s"\r\nContent-Type: %s\r\n\r\n'
					% [key, filename, content_type]
				)
				. to_utf8_buffer()
			)
			var body: PackedByteArray = data

			buffer.append_array(disposition)
			buffer.append_array(body)
		elif value is bool:
			var disposition: PackedByteArray = (
				('Content-Disposition: form-data; name="%s"\r\n\r\n' % key).to_utf8_buffer()
			)
			var body: PackedByteArray = (
				"true".to_utf8_buffer() if value == true else "false".to_utf8_buffer()
			)

			buffer.append_array(disposition)
			buffer.append_array(body)
		elif value is int:
			var disposition: PackedByteArray = (
				('Content-Disposition: form-data; name="%s"\r\n\r\n' % key).to_utf8_buffer()
			)
			var body: PackedByteArray = value.to_string().to_utf8_buffer()

			buffer.append_array(disposition)
			buffer.append_array(body)
		elif value is float:
			var disposition: PackedByteArray = (
				('Content-Disposition: form-data; name="%s"\r\n\r\n' % key).to_utf8_buffer()
			)
			var body: PackedByteArray = value.to_string().to_utf8_buffer()

			buffer.append_array(disposition)
			buffer.append_array(body)
		else:
			push_error("_compose_multipart_body: Unknown tpye!")

	buffer.append_array(("\r\n--" + p_boundary_string + "--\r\n").to_utf8_buffer())

	return buffer


func _dict_to_query_string(p_dictionary: Dictionary) -> String:
	if _has_enhanced_qs_from_dict:
		return _http_query_string.query_string_from_dict(p_dictionary)

	# For 3.0
	var qs: String = ""
	for key in p_dictionary:
		var value = p_dictionary[key]
		if typeof(value) == TYPE_ARRAY:
			for v in value:
				qs += "&%s=%s" % [key.uri_encode(), v.uri_encode()]
		else:
			qs += "&%s=%s" % [key.uri_encode(), String(value).uri_encode()]
	qs = qs.substr(1)
	return qs
	
func cancel() -> void:
	if http_state:
		http_state.cancel()
