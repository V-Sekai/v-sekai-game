# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_asset_manager.gd
# SPDX-License-Identifier: MIT

@tool
extends Node

const vsk_asset_manager_const = preload("res://addons/vsk_manager/vsk_asset_manager.gd")

const directory_util_const = preload("res://addons/gd_util/directory_util.gd")

const data_storage_units_const = preload("res://addons/gd_util/data_storage_units.gd")

const URO_AVATAR_PREFIX = "avatar_"
const URO_MAP_PREFIX = "map_"
const URO_PROP_PREFIX = "prop_"
const URO_GAME_MODE_PREFIX = "game_mode_"

const ASSET_CACHE_PATH = "user://asset_cache"
const CACHE_FILE_EXTENSION = "scn"
const ETAG_FILE_EXTENSION = "etag"

const HTTP_DOWNLOAD_CHUNK_SIZE = 65536

const INVALID_REQUEST = 0
const HTTP_REQUEST = 1
const LOCAL_FILE_REQUEST = 2
const URO_REQUEST = 3

var avatar_forbidden_path: String = "res://addons/vsk_avatar/avatars/error_handlers/avatar_forbidden.tscn"
var avatar_not_found_path: String = "res://addons/vsk_avatar/avatars/error_handlers/avatar_not_found.tscn"
var avatar_error_path: String = "res://addons/vsk_avatar/avatars/error_handlers/avatar_error.tscn"
var teapot_path: String = "res://addons/vsk_avatar/avatars/error_handlers/teapot.tscn"
var loading_avatar_path: String = "res://addons/vsk_avatar/avatars/loading/loading_orb.tscn"

var avatar_whitelist: PackedStringArray = []
var map_whitelist: PackedStringArray = []
var prop_whitelist: PackedStringArray = []
var game_mode_whitelist: PackedStringArray = []

enum { ASSET_OK, ASSET_UNKNOWN_FAILURE, ASSET_UNAUTHORIZED, ASSET_FORBIDDEN, ASSET_NOT_FOUND, ASSET_INVALID, ASSET_I_AM_A_TEAPOT, ASSET_UNAVAILABLE_FOR_LEGAL_REASONS, ASSET_NOT_WHITELISTED, ASSET_FAILED_VALIDATION_CHECK, ASSET_RESOURCE_LOAD_FAILED }

enum { STAGE_PENDING, STAGE_DOWNLOADING, STAGE_BACKGROUND_LOADING, STAGE_VALIDATING, STAGE_INSTANCING, STAGE_DONE, STAGE_CANCELLING }

enum user_content_type { USER_CONTENT_AVATAR, USER_CONTENT_MAP, USER_CONTENT_PROP, USER_CONTENT_GAME_MODE, USER_CONTENT_UNKNOWN }

# The amount of space a progress bar should dedicate to the downloading phase
const DOWNLOAD_PROGRESS_BAR_RATIO = 0.9

# The remaining is dedicated to loading from disk
const BACKGROUND_LOAD_PROGRESS_BAR_RATIO = 1.0 - DOWNLOAD_PROGRESS_BAR_RATIO

signal request_started(p_url)
signal request_complete(p_url, request_object, p_response_code)
signal request_cancelled(p_url)

var request_objects: Dictionary = {}


func clear_cache() -> void:
	var dir: DirAccess = DirAccess.open(ASSET_CACHE_PATH)
	if dir != null:
		if directory_util_const.delete_dir_and_contents(dir, ASSET_CACHE_PATH, false) != OK:
			printerr("Could not delete all files in cache!")


func is_whitelisted(p_url: String, p_user_content_type: int) -> bool:
	var whitelist: PackedStringArray

	match p_user_content_type:
		user_content_type.USER_CONTENT_AVATAR:
			whitelist = avatar_whitelist
		user_content_type.USER_CONTENT_MAP:
			whitelist = map_whitelist
		user_content_type.USER_CONTENT_PROP:
			whitelist = prop_whitelist
		user_content_type.USER_CONTENT_GAME_MODE:
			whitelist = game_mode_whitelist
		_:
			return false

	for string in whitelist:
		if p_url.match(string):
			return true

	if p_url.is_empty():
		printerr("Asset is not whitelisted!")
	else:
		printerr("Asset %s is not whitelisted!" % p_url)

	return false


func get_error_path(p_type: int, p_asset_err: int) -> String:
	match p_type:
		user_content_type.USER_CONTENT_AVATAR:
			match p_asset_err:
				ASSET_I_AM_A_TEAPOT:
					return teapot_path
				ASSET_UNAVAILABLE_FOR_LEGAL_REASONS:
					return avatar_forbidden_path
				ASSET_NOT_FOUND:
					return avatar_not_found_path
				ASSET_UNAUTHORIZED:
					return avatar_forbidden_path
				ASSET_FORBIDDEN:
					return avatar_forbidden_path
				ASSET_NOT_WHITELISTED:
					return avatar_forbidden_path
				_:
					return avatar_error_path
		user_content_type.USER_CONTENT_MAP:
			return ""
		user_content_type.USER_CONTENT_PROP:
			return ""
		user_content_type.USER_CONTENT_GAME_MODE:
			return ""
		_:
			return ""


func _http_request_completed(p_result: int, p_response_code: int, _headers: PackedStringArray, p_body: PackedByteArray, p_request_object: Dictionary) -> void:
	var response_code: int = ASSET_UNKNOWN_FAILURE

	if p_result != OK:
		_complete_request(p_request_object, response_code)
		return

	match p_response_code:
		HTTPClient.RESPONSE_OK:
			if p_request_object["path"] == "":
				var path: String = "%s/%s.%s" % [ASSET_CACHE_PATH, String(p_request_object["url"]).md5_text(), CACHE_FILE_EXTENSION]
				var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
				if file != null:
					file.store_buffer(p_body)
				p_request_object["path"] = path
			response_code = ASSET_OK
		HTTPClient.RESPONSE_UNAUTHORIZED:
			p_request_object["path"] = get_error_path(p_request_object["asset_type"], ASSET_UNAUTHORIZED)
			response_code = ASSET_FORBIDDEN
		HTTPClient.RESPONSE_FORBIDDEN:
			p_request_object["path"] = get_error_path(p_request_object["asset_type"], ASSET_FORBIDDEN)
			response_code = ASSET_FORBIDDEN
		HTTPClient.RESPONSE_NOT_FOUND:
			p_request_object["path"] = get_error_path(p_request_object["asset_type"], ASSET_NOT_FOUND)
			response_code = ASSET_NOT_FOUND
		HTTPClient.RESPONSE_IM_A_TEAPOT:
			p_request_object["path"] = get_error_path(p_request_object["asset_type"], ASSET_I_AM_A_TEAPOT)
			response_code = ASSET_I_AM_A_TEAPOT
		HTTPClient.RESPONSE_UNAVAILABLE_FOR_LEGAL_REASONS:
			p_request_object["path"] = get_error_path(p_request_object["asset_type"], ASSET_UNAVAILABLE_FOR_LEGAL_REASONS)
			response_code = ASSET_UNAVAILABLE_FOR_LEGAL_REASONS
		_:
			p_request_object["path"] = get_error_path(p_request_object["asset_type"], ASSET_UNKNOWN_FAILURE)
			response_code = ASSET_UNKNOWN_FAILURE

	if request_objects.has(p_request_object["request_path"]):
		_complete_request(p_request_object, response_code)


static func get_request_type(p_request_path: String) -> int:
	var path_lower: String = p_request_path.to_lower()
	if path_lower.begins_with("https://") or path_lower.begins_with("http://"):
		return HTTP_REQUEST
	elif path_lower.begins_with("file:///") or path_lower.begins_with("res://"):
		return LOCAL_FILE_REQUEST
	elif path_lower.begins_with("uro:///") or path_lower.begins_with("uro://"):
		return URO_REQUEST
	else:
		return INVALID_REQUEST


func make_http_request(p_request_object: Dictionary, p_bypass_whitelist: bool) -> Dictionary:
	var request_object: Dictionary = p_request_object
	var url: String = p_request_object["url"]
	var asset_type: int = request_object["asset_type"]

	if not p_bypass_whitelist and not is_whitelisted(url, asset_type):
		request_object["path"] = get_error_path(request_object["asset_type"], ASSET_NOT_WHITELISTED)
		_complete_request(p_request_object, ASSET_NOT_WHITELISTED)
		return request_object

	var etag_path: String = "%s/%s.%s" % [ASSET_CACHE_PATH, String(url).md5_text(), ETAG_FILE_EXTENSION]
	if FileAccess.file_exists(etag_path):
		var etag_file = FileAccess.open(etag_path, FileAccess.READ)
		if etag_file != null:
			var resource_path: String = "%s/%s.%s" % [ASSET_CACHE_PATH, String(url).md5_text(), CACHE_FILE_EXTENSION]

			if FileAccess.file_exists(resource_path):
				request_object["path"] = resource_path
				_complete_request(p_request_object, ASSET_OK)
				return request_object
		else:
			printerr("Could not open etag file!")
	else:
		var etag_file: FileAccess = FileAccess.open(etag_path, FileAccess.WRITE)
		if etag_file == null:
			printerr("Could not create etag file!")

	var http_request: HTTPRequest = HTTPRequest.new()
	http_request.name = "httpreq"
	http_request.use_threads = true
	http_request.download_chunk_size = HTTP_DOWNLOAD_CHUNK_SIZE
	add_child(http_request, true)

	if http_request.request_completed.connect(self._http_request_completed.bind(request_object)) != OK:
		printerr("Could not connect signal 'request_complete'!")

	register_request(request_object)
	if http_request.request(url) == OK:
		request_object["object"] = http_request
		request_started.emit(request_object["request_path"])
	else:
		request_object["path"] = get_error_path(request_object["asset_type"], ASSET_UNKNOWN_FAILURE)
		_complete_request(p_request_object, ASSET_UNKNOWN_FAILURE)

	return request_object


func make_local_file_request(p_request_object: Dictionary, p_bypass_whitelist: bool) -> Dictionary:
	var request_object: Dictionary = p_request_object
	var path: String = request_object["path"]
	if path.is_empty():
		_complete_request(p_request_object, ASSET_NOT_FOUND)
		return p_request_object
	var asset_type: int = request_object["asset_type"]

	var asset_err: int = ASSET_OK

	if p_bypass_whitelist or is_whitelisted(path, asset_type):
		var stripped_path: String = path.lstrip("file:///")

		var file_exists: bool = FileAccess.file_exists(stripped_path)
		if !file_exists:
			printerr("Local asset not found: %s " % path)
			asset_err = ASSET_NOT_FOUND
	else:
		asset_err = ASSET_NOT_WHITELISTED

	if asset_err != ASSET_OK:
		request_object["path"] = get_error_path(request_object["asset_type"], asset_err)

	_complete_request(p_request_object, asset_err)

	return request_object


static func _get_full_url_for_uro_request(p_request) -> String:
	return GodotUro.get_base_url() + p_request


func _uro_api_request(p_request_object: Dictionary, p_id: String, p_asset_type: int):
	var async_result = null
	var user_content_type_string: String = ""
	match p_asset_type:
		GodotUro.godot_uro_helper_const.UroUserContentType.AVATAR:
			async_result = await GodotUro.godot_uro_api.get_avatar_async(p_id)
			user_content_type_string = "avatar"
		GodotUro.godot_uro_helper_const.UroUserContentType.MAP:
			async_result = await GodotUro.godot_uro_api.get_map_async(p_id)
			user_content_type_string = "map"

	if not async_result is Dictionary or not request_objects.has(p_request_object["request_path"]):
		return {}

	var request_path: String = p_request_object["request_path"]
	if not GodotUro.godot_uro_helper_const.requester_result_is_ok(async_result):
		print("Uro Request for %s returned with error: %s" % [request_path, GodotUro.godot_uro_helper_const.get_full_requester_error_string(async_result)])
		_complete_request(p_request_object, ASSET_UNKNOWN_FAILURE)
		return {}

	print("Uro Request: %s" % str(async_result["output"]))
	var data_valid: bool = false

	var output: Dictionary = async_result["output"]
	if output.has("data"):
		var data = output["data"]
		if data.has(user_content_type_string):
			var user_content = data[user_content_type_string]
			if user_content.has("user_content_data"):
				var user_content_data = user_content["user_content_data"]
				p_request_object["url"] = vsk_asset_manager_const._get_full_url_for_uro_request(user_content_data)
				data_valid = true
				p_request_object = make_http_request(p_request_object, true)
				return p_request_object

	if not data_valid:
		print("Uro Request for %s data invalid" % request_path)
		_complete_request(p_request_object, ASSET_INVALID)

	return {}


func _execute_uro_file_request(p_request_object: Dictionary, p_id: String, p_uro_content_type: int, p_request_path: String) -> void:
	var request_object: Dictionary = p_request_object
	request_object = await _uro_api_request(request_object, p_id, p_uro_content_type)

	if !request_object.is_empty():
		request_started.emit(p_request_path)
	else:
		_destroy_request(p_request_path)


func make_uro_file_request(p_request_object: Dictionary, _bypass_whitelist: bool) -> Dictionary:
	var request_object: Dictionary = p_request_object
	var request_path: String = p_request_object["request_path"]
	var asset_type: int = p_request_object["asset_type"]

	var link: String = request_path.lstrip("uro:///")
	link = request_path.lstrip("uro://")

	var uro_content_type: int = GodotUro.godot_uro_helper_const.UroUserContentType.UNKNOWN

	# Find the type of asset this Uro link is for
	var id: String = ""
	match asset_type:
		user_content_type.USER_CONTENT_AVATAR:
			id = link.lstrip(URO_AVATAR_PREFIX)
			uro_content_type = GodotUro.godot_uro_helper_const.UroUserContentType.AVATAR
		user_content_type.USER_CONTENT_MAP:
			id = link.lstrip(URO_MAP_PREFIX)
			uro_content_type = GodotUro.godot_uro_helper_const.UroUserContentType.MAP
		_:
			return request_object

	if id.find("/") == -1:
		register_request(request_object)
		_execute_uro_file_request.call(request_object, id, uro_content_type, request_path)

	return request_object


func make_request(p_request_path: String, p_asset_type: int, p_bypass_whitelist: bool, p_skip_validation: bool, p_external_path_whitelist: Dictionary, p_resource_whitelist: Dictionary) -> Dictionary:
	var request_object: Dictionary = {"request_id": INVALID_REQUEST, "request_path": p_request_path, "path": "", "asset_type": p_asset_type}

	var request_type: int = vsk_asset_manager_const.get_request_type(p_request_path)
	request_object["object"] = {}
	request_object["skip_validation"] = p_skip_validation
	request_object["external_path_whitelist"] = p_external_path_whitelist
	request_object["resource_whitelist"] = p_resource_whitelist
	match request_type:
		HTTP_REQUEST:
			request_object["request_id"] = HTTP_REQUEST
			request_object["url"] = p_request_path
			request_object = make_http_request(request_object, p_bypass_whitelist)
		LOCAL_FILE_REQUEST:
			request_object["request_id"] = LOCAL_FILE_REQUEST
			request_object["path"] = p_request_path
			request_object = make_local_file_request(request_object, p_bypass_whitelist)
		URO_REQUEST:
			request_object["request_id"] = URO_REQUEST
			request_object = make_uro_file_request(request_object, p_bypass_whitelist)
		_:
			request_object["request_id"] = LOCAL_FILE_REQUEST
			request_object["path"] = p_request_path
			request_object = make_local_file_request(request_object, p_bypass_whitelist)
	return request_object


func register_request(p_request_object: Dictionary) -> void:
	request_objects[p_request_object["request_path"]] = p_request_object


func _destroy_request_internal(p_request_object: Dictionary) -> void:
	if not p_request_object.has("object"):
		return
	var object = p_request_object["object"]
	if object and object is HTTPRequest:
		object.cancel_request()
		object.queue_free()


func _destroy_request(p_request_path: String) -> void:
	if request_objects.has(p_request_path):
		var request_object: Dictionary = request_objects[p_request_path]
		match request_object["request_id"]:
			HTTP_REQUEST:
				_destroy_request_internal(request_object)
			URO_REQUEST:
				_destroy_request_internal(request_object)

		if request_objects.has(p_request_path):
			assert(request_objects.erase(p_request_path))


func _complete_request(p_request_object: Dictionary, p_response_code: int) -> void:
	_destroy_request(p_request_object["request_path"])
	request_complete.emit(p_request_object["request_path"], p_request_object, p_response_code)


func cancel_request(p_request_path: String) -> void:
	if request_objects.has(p_request_path):
		var request_object: Dictionary = request_objects[p_request_path]
		_destroy_request(p_request_path)
		request_cancelled.emit(request_object["request_path"])


func _get_request_data_progress_internal(p_request_object: Dictionary) -> Dictionary:
	var object = p_request_object.get("object")
	if typeof(object) != TYPE_NIL and object is HTTPRequest:
		return {"body_size": p_request_object["object"].get_body_size(), "downloaded_bytes": p_request_object["object"].get_downloaded_bytes()}
	else:
		return {"body_size": 0, "downloaded_bytes": 0}


func get_request_data_progress(p_request_path: String) -> Dictionary:
	var ret: Dictionary = {}
	if request_objects.has(p_request_path):
		var request_object: Dictionary = request_objects[p_request_path]
		match request_object["request_id"]:
			HTTP_REQUEST:
				ret = _get_request_data_progress_internal(request_object)
			URO_REQUEST:
				ret = _get_request_data_progress_internal(request_object)
		#print("Request " + str(p_request_path) + ": " + str(request_object) + " is still going: " + str(ret))
	return ret


static func get_download_progress_string(p_downloaded_bytes: int, p_body_size: int) -> String:
	var downloaded_bytes_data_block: Dictionary = data_storage_units_const.convert_bytes_to_data_unit_block(p_downloaded_bytes)
	var body_size_data_block: Dictionary = data_storage_units_const.convert_bytes_to_data_unit_block(p_body_size)

	var downloaded_bytes_largest_unit: int = data_storage_units_const.get_largest_unit_type(downloaded_bytes_data_block)
	var body_size_largest_unit: int = data_storage_units_const.get_largest_unit_type(body_size_data_block)

	var downloaded_bytes_string: String = "%s%s" % [data_storage_units_const.get_string_for_unit_data_block(downloaded_bytes_data_block, downloaded_bytes_largest_unit), data_storage_units_const.get_string_for_unit_type(downloaded_bytes_largest_unit)]

	var body_size_string: String = "%s%s" % [data_storage_units_const.get_string_for_unit_data_block(body_size_data_block, body_size_largest_unit), data_storage_units_const.get_string_for_unit_type(body_size_largest_unit)]

	return "%s/%s" % [downloaded_bytes_string, body_size_string]


func cancel_all_requests() -> void:
	for key in request_objects.keys():
		cancel_request(key)


func _exit_tree() -> void:
	cancel_all_requests()


func get_project_settings() -> void:
	if ProjectSettings.has_setting("assets/config/avatar_forbidden_path"):
		avatar_forbidden_path = ProjectSettings.get_setting("assets/config/avatar_forbidden_path")
	if ProjectSettings.has_setting("assets/config/avatar_not_found_path"):
		avatar_not_found_path = ProjectSettings.get_setting("assets/config/avatar_not_found_path")
	if ProjectSettings.has_setting("assets/config/avatar_error_path"):
		avatar_error_path = ProjectSettings.get_setting("assets/config/avatar_error_path")
	if ProjectSettings.has_setting("assets/config/teapot_path"):
		teapot_path = ProjectSettings.get_setting("assets/config/teapot_path")

	if ProjectSettings.has_setting("assets/config/loading_avatar_path"):
		loading_avatar_path = ProjectSettings.get_setting("assets/config/loading_avatar_path")

	if ProjectSettings.has_setting("assets/config/avatar_whitelist"):
		avatar_whitelist = ProjectSettings.get_setting("assets/config/avatar_whitelist")
	if ProjectSettings.has_setting("assets/config/prop_whitelist"):
		prop_whitelist = ProjectSettings.get_setting("assets/config/prop_whitelist")
	if ProjectSettings.has_setting("assets/config/map_whitelist"):
		map_whitelist = ProjectSettings.get_setting("assets/config/map_whitelist")
	if ProjectSettings.has_setting("assets/config/game_mode_whitelist"):
		game_mode_whitelist = ProjectSettings.get_setting("assets/config/game_mode_whitelist")


func apply_project_settings() -> void:
	if !ProjectSettings.has_setting("assets/config/avatar_forbidden_path"):
		ProjectSettings.set_setting("assets/config/avatar_forbidden_path", avatar_forbidden_path)

	if !ProjectSettings.has_setting("assets/config/avatar_not_found_path"):
		ProjectSettings.set_setting("assets/config/avatar_not_found_path", avatar_not_found_path)

	if !ProjectSettings.has_setting("assets/config/avatar_error_path"):
		ProjectSettings.set_setting("assets/config/avatar_error_path", avatar_error_path)

	if !ProjectSettings.has_setting("assets/config/teapot_path"):
		ProjectSettings.set_setting("assets/config/teapot_path", teapot_path)

	if !ProjectSettings.has_setting("assets/config/loading_avatar_path"):
		ProjectSettings.set_setting("assets/config/loading_avatar_path", loading_avatar_path)

	if !ProjectSettings.has_setting("assets/config/avatar_whitelist"):
		ProjectSettings.set_setting("assets/config/avatar_whitelist", avatar_whitelist)

	if !ProjectSettings.has_setting("assets/config/prop_whitelist"):
		ProjectSettings.set_setting("assets/config/prop_whitelist", prop_whitelist)

	if !ProjectSettings.has_setting("assets/config/map_whitelist"):
		ProjectSettings.set_setting("assets/config/map_whitelist", map_whitelist)

	if !ProjectSettings.has_setting("assets/config/game_mode_whitelist"):
		ProjectSettings.set_setting("assets/config/game_mode_whitelist", game_mode_whitelist)

	if ProjectSettings.save() != OK:
		printerr("VSKAssetManager: could not save project settings!")


func setup() -> void:
	if !Engine.is_editor_hint():
		if not DirAccess.dir_exists_absolute(ASSET_CACHE_PATH):
			if DirAccess.make_dir_absolute(ASSET_CACHE_PATH) != OK:
				printerr("Could not create asset cache directory!")

		get_project_settings()


func _ready() -> void:
	if Engine.is_editor_hint():
		apply_project_settings()
		get_project_settings()
