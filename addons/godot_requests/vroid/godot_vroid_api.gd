# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# godot_vroid_api.gd
# SPDX-License-Identifier: MIT

@tool
extends GodotRequestAPI
class_name GodotVroidAPI

var _godot_vroid: GodotVroid = null

func _init(p_godot_vroid):
	_godot_vroid = p_godot_vroid

func get_profile_async(p_requester: GodotRequester, p_access_token: String) -> Dictionary:
	var query: Dictionary = {}

	var result = await (p_requester.request(
		GodotVroidHelper.get_api_path() + GodotVroidHelper.PROFILE_PATH,
		query,
		p_access_token,
		{"method": HTTPClient.METHOD_GET, "encoding": "query", "extra_headers": [GodotVroidHelper.get_api_header()]}
	))

	return _handle_result(result)


func get_uploaded_avatars_async(p_requester: GodotRequester, p_access_token: String, p_filter: Dictionary = {}, p_max_id: String = "", p_count: int = 0) -> Dictionary:
	var query: Dictionary = {}
	var count = 0

	var filter = GodotVroidHelper.interpolate_default_model_filter(p_filter)
	query = filter
	if p_max_id != "":
		query["max_id"] = p_max_id
	if p_count >= 1:
		count = min(p_count, 100) # clamp
	else:
		count = 20 # default
	query["count"] = count

	var result = await (p_requester.request(
		GodotVroidHelper.get_api_path() + GodotVroidHelper.UPLOADED_MODELS_PATH,
		query,
		p_access_token,
		{"method": HTTPClient.METHOD_GET, "encoding": "query", "extra_headers": [GodotVroidHelper.get_api_header()]}
	))

	return _handle_result(result)


func get_liked_avatars_async(p_requester: GodotRequester, p_access_token: String, p_app_id: String, p_filter: Dictionary = {}, p_max_id: String = "", p_count: int = 0) -> Dictionary:
	var query: Dictionary = {}
	var count = 0

	var filter = GodotVroidHelper.interpolate_default_model_filter(p_filter)
	query = filter
	# Vroid API bug: if these are in /api/hearts query, empty array is returned
	query.erase("has_booth_items")
	query.erase("booth_part_categories")
	
	if p_max_id != "":
		query["max_id"] = p_max_id
	if p_count >= 1:
		count = min(p_count, 100) # clamp
	else:
		count = 20 # default
	query["count"] = count
	query["application_id"] = p_app_id

	var result = await (p_requester.request(
		GodotVroidHelper.get_api_path() + GodotVroidHelper.HEARTS_PATH,
		query,
		p_access_token,
		{"method": HTTPClient.METHOD_GET, "encoding": "query", "extra_headers": [GodotVroidHelper.get_api_header()]}
	))

	return _handle_result(result)


func get_staff_picks_async(p_requester: GodotRequester, p_access_token: String, p_max_id: String = "", p_count: int = 0) -> Dictionary:
	var query: Dictionary = {}
	var count = 0

	if p_max_id != "":
		query["max_id"] = p_max_id
	if p_count >= 1:
		count = min(p_count, 100) # clamp
	else:
		count = 20 # default
	query["count"] = count

	var result = await (p_requester.request(
		GodotVroidHelper.get_api_path() + GodotVroidHelper.STAFF_PICKS_PATH,
		query,
		p_access_token,
		{"method": HTTPClient.METHOD_GET, "encoding": "query", "extra_headers": [GodotVroidHelper.get_api_header()]}
	))

	return _handle_result(result)


func search_models_async(p_requester: GodotRequester, p_access_token: String, p_keyword: String, p_filter: Dictionary = {}, p_search_after: String = "", p_sort: String = "", p_count: int = 0) -> Dictionary:
	var query: Dictionary = {}
	var count = 0

	var filter = GodotVroidHelper.interpolate_default_model_filter(p_filter)
	query = filter
	if p_search_after != "":
		query["search_after[]"] = p_search_after
	if p_sort != "":
		query["sort"] = p_sort
	if p_count >= 1:
		count = min(p_count, 100) # clamp
	else:
		count = 20 # default
	query["count"] = count
	query["keyword"] = p_keyword

	var result = await (p_requester.request(
		GodotVroidHelper.get_api_path() + GodotVroidHelper.SEARCH_PATH,
		query,
		p_access_token,
		{"method": HTTPClient.METHOD_GET, "encoding": "query", "extra_headers": [GodotVroidHelper.get_api_header()]}
	))

	return _handle_result(result)


func get_model_details_async(p_requester: GodotRequester, p_access_token: String, p_id: String ) -> Dictionary:
	var query: Dictionary = {}

	var result = await (p_requester.request(
		GodotVroidHelper.get_api_path() + GodotVroidHelper.MODEL_PATH + "/" + p_id,
		query,
		p_access_token,
		{"method": HTTPClient.METHOD_GET, "encoding": "query", "extra_headers": [GodotVroidHelper.get_api_header()]}
	))

	return _handle_result(result)

func get_download_license_async(p_requester: GodotRequester, p_access_token: String, p_id: String) -> Dictionary:
	var query: Dictionary = {}

	var result = await (p_requester.request(
		GodotVroidHelper.get_api_path() + GodotVroidHelper.DOWNLOAD_LICENSE_PATH + "/" + p_id,
		query,
		p_access_token,
		{"method": HTTPClient.METHOD_GET, "encoding": "query", "extra_headers": [GodotVroidHelper.get_api_header()]}
	))

	return _handle_result(result)

func revoke_download_license_async(p_requester: GodotRequester, p_access_token: String, p_id: String) -> Dictionary:
	var query: Dictionary = {}

	var result = await (p_requester.request(
		GodotVroidHelper.get_api_path() + GodotVroidHelper.DOWNLOAD_LICENSE_PATH + "/" + p_id,
		query,
		p_access_token,
		{"method": HTTPClient.METHOD_DELETE, "encoding": "query", "extra_headers": [GodotVroidHelper.get_api_header()]}
	))

	return _handle_result(result)

func request_download_license_async(p_requester: GodotRequester, p_access_token: String, p_id: String, p_is_multiplay: bool = false) -> Dictionary:
	var query: Dictionary = {}

	query["character_model_id"] = p_id
	var multiplay: String = ""
	if p_is_multiplay:
		multiplay = "/multiplay"

	var result = await (p_requester.request(
		GodotVroidHelper.get_api_path() + GodotVroidHelper.DOWNLOAD_LICENSE_PATH + multiplay,
		query,
		p_access_token,
		{"method": HTTPClient.METHOD_POST, "encoding": "json", "extra_headers": [GodotVroidHelper.get_api_header()]}
	))

	return _handle_result(result)


func request_download_url_async(p_requester: GodotRequester, p_access_token: String, p_license_id: String) -> Dictionary:
	var query: Dictionary = {}

	var result = await (p_requester.request(
		GodotVroidHelper.get_api_path() + GodotVroidHelper.DOWNLOAD_LICENSE_PATH + "/" + p_license_id + "/download",
		query,
		p_access_token,
		{"method": HTTPClient.METHOD_GET, "encoding": "query", "extra_headers": [GodotVroidHelper.get_api_header()]}
	))

	return _handle_result(result)
