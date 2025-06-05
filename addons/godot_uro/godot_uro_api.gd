# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# godot_uro_api.gd
# SPDX-License-Identifier: MIT

@tool
extends RefCounted
class_name GodotUroAPI

const USER_NAME = "user"
const SHARD_NAME = "shard"
const AVATAR_NAME = "avatar"
const MAP_NAME = "map"

var _godot_uro: GodotUro = null

func cancel(p_requester: GodotUroRequester) -> void:
	p_requester.cancel()

func get_profile_async(p_requester: GodotUroRequester, p_access_token: String) -> Dictionary:
	var query: Dictionary = {}

	var result = await (p_requester.request(
		GodotUroHelper.get_api_path() + GodotUroHelper.PROFILE_PATH,
		query,
		p_access_token,
		{"method": HTTPClient.METHOD_GET, "encoding": "form"}
	))

	return _handle_result(result)
	
func renew_session_async(p_requester: GodotUroRequester, p_renewal_token: String) -> Dictionary:
	var query: Dictionary = {}
	
	var result = await (p_requester.request(
		(
			GodotUroHelper.get_api_path()
			+ GodotUroHelper.SESSION_PATH
			+ GodotUroHelper.RENEW_PATH
		),
		query,
		p_renewal_token,
		{"method": HTTPClient.METHOD_POST, "encoding": "form"}
	))

	return _handle_result(result)

func sign_in_async(p_requester: GodotUroRequester, p_username_or_email: String, p_password: String) -> Dictionary:
	var query: Dictionary = {
		"user[username_or_email]": p_username_or_email,
		"user[password]": p_password,
	}

	var result: GodotUroRequester.Result = await (p_requester.request(
		GodotUroHelper.get_api_path() + GodotUroHelper.SESSION_PATH,
		query,
		"",
		{"method": HTTPClient.METHOD_POST, "encoding": "form"}
	))

	return _handle_result(result)


func sign_out_async(p_requester: GodotUroRequester, p_access_token: String) -> Dictionary:
	var query: Dictionary = {}

	var result = await (p_requester.request(
		GodotUroHelper.get_api_path() + GodotUroHelper.SESSION_PATH,
		query,
		p_access_token,
		{"method": HTTPClient.METHOD_DELETE, "encoding": "form"}
	))

	return _handle_result(result)


func register_async(
	p_requester: GodotUroRequester,
	p_username: String,
	p_email: String,
	p_password: String,
	p_password_confirmation: String,
	p_email_notifications: bool
) -> Dictionary:
	var query: Dictionary = {
		"user[username]": p_username,
		"user[email]": p_email,
		"user[password]": p_password,
		"user[password_confirmation]": p_password_confirmation,
		"user[email_notifications]": GodotUroHelper.bool_to_string(p_email_notifications)
	}

	var result = await (p_requester.request(
		GodotUroHelper.get_api_path() + GodotUroHelper.REGISTRATION_PATH,
		query,
		"",
		{"method": HTTPClient.METHOD_POST, "encoding": "form"}
	))

	return _handle_result(result)

func create_identity_proof_for_async(p_requester: GodotUroRequester, p_access_token: String, p_id: String) -> Dictionary:
	var query: Dictionary = {
		"identity_proof[user_to]": p_id,
	}

	var result = await (p_requester.request(
		GodotUroHelper.get_api_path() + GodotUroHelper.IDENTITY_PROOFS_PATH,
		query,
		p_access_token,
		{"method": HTTPClient.METHOD_POST, "encoding": "form"}
	))
	
	return _handle_result(result)

func get_identity_proof_async(p_requester: GodotUroRequester, p_access_token: String, p_id: String) -> Dictionary:
	var query: Dictionary = {}

	var result = await (p_requester.request(
		(
			GodotUroHelper.get_api_path()
			+ GodotUroHelper.IDENTITY_PROOFS_PATH
			+ "/"
			+ p_id
		),
		query,
		p_access_token,
		{"method": HTTPClient.METHOD_GET, "encoding": "form"}
	))
	return _handle_result(result)

func create_shard_async(p_requester: GodotUroRequester, p_access_token: String, p_query: Dictionary) -> Dictionary:
	var query: Dictionary = GodotUroHelper.populate_query(SHARD_NAME, p_query)

	var result = await (p_requester.request(
		GodotUroHelper.get_api_path() + GodotUroHelper.SHARDS_PATH,
		query,
		p_access_token,
		{"method": HTTPClient.METHOD_POST, "encoding": "form"}
	))
	return _handle_result(result)

func delete_shard_async(p_requester: GodotUroRequester, p_access_token: String, p_id: String, p_query: Dictionary) -> Dictionary:
	var query: Dictionary = GodotUroHelper.populate_query(SHARD_NAME, p_query)
	
	var result = await (p_requester.request(
		(
			"%s%s/%s"
			% [GodotUroHelper.get_api_path(), GodotUroHelper.SHARDS_PATH, p_id]
		),
		query,
		p_access_token,
		{"method": HTTPClient.METHOD_DELETE, "encoding": "form"}
	))

	return _handle_result(result)

func update_shard_async(p_requester: GodotUroRequester, p_access_token: String, p_id: String, p_query: Dictionary) -> Dictionary:
	var query: Dictionary = GodotUroHelper.populate_query(SHARD_NAME, p_query)
	
	var result = await (p_requester.request(
		(
			"%s%s/%s"
			% [GodotUroHelper.get_api_path(), GodotUroHelper.SHARDS_PATH, p_id]
		),
		query,
		p_access_token,
		{"method": HTTPClient.METHOD_PUT, "encoding": "form"}
	))

	return _handle_result(result)

func get_shards_async(p_requester: GodotUroRequester) -> Dictionary:
	var query: Dictionary = GodotUroHelper.populate_query(SHARD_NAME, {})

	var result = await (p_requester.request(
		GodotUroHelper.get_api_path() + GodotUroHelper.SHARDS_PATH,
		query,
		"",
		{"method": HTTPClient.METHOD_GET, "encoding": "form"}
	))

	return GodotUroHelper.process_shards_json(_handle_result(result))

func get_avatars_async(p_requester: GodotUroRequester) -> Dictionary:
	var query: Dictionary = GodotUroHelper.populate_query(AVATAR_NAME, {})

	var result = await (p_requester.request(
		GodotUroHelper.get_api_path() + GodotUroHelper.AVATARS_PATH,
		query,
		"",
		{"method": HTTPClient.METHOD_GET, "encoding": "form"}
	))

	return _handle_result(result)

func get_avatar_async(p_requester: GodotUroRequester, p_id: String) -> Dictionary:
	var query: Dictionary = {}

	var result = await (p_requester.request(
		GodotUroHelper.get_api_path() + GodotUroHelper.AVATARS_PATH + "/" + p_id,
		query,
		"",
		{"method": HTTPClient.METHOD_GET, "encoding": "form"}
	))

	return _handle_result(result)

func get_maps_async(p_requester: GodotUroRequester) -> Dictionary:
	var query: Dictionary = GodotUroHelper.populate_query(MAP_NAME, {})

	var result = await (p_requester.request(
		GodotUroHelper.get_api_path() + GodotUroHelper.MAPS_PATH,
		query,
		"",
		{"method": HTTPClient.METHOD_GET, "encoding": "form"}
	))

	return _handle_result(result)

func get_map_async(p_requester: GodotUroRequester, p_access_token: String, p_id: String) -> Dictionary:
	var query: Dictionary = {}
	
	var result = await (p_requester.request(
		GodotUroHelper.get_api_path() + GodotUroHelper.MAPS_PATH + "/" + p_id,
		query,
		p_access_token,
		{"method": HTTPClient.METHOD_GET, "encoding": "form"}
	))

	return _handle_result(result)

##
## Dashboard Avatar
##


func dashboard_get_avatars_async(p_requester: GodotUroRequester, p_access_token: String) -> Dictionary:
	var query: Dictionary = {}
	
	var path: String = (
		GodotUroHelper.get_api_path()
		+ GodotUroHelper.DASHBOARD_PATH
		+ GodotUroHelper.AVATARS_PATH
	)

	var result = await p_requester.request(
		path,
		query,
		p_access_token,
		{"method": HTTPClient.METHOD_GET, "encoding": "form"}
	)
	print("Path " + str(path) + " returned " + str(result) + " type " + str(typeof(result)))

	return _handle_result(result)

func dashboard_create_avatar_async(p_requester: GodotUroRequester, p_access_token: String, p_query: Dictionary) -> Dictionary:
	var query: Dictionary = GodotUroHelper.populate_query(AVATAR_NAME, p_query)

	var path: String = (
		GodotUroHelper.get_api_path()
		+ GodotUroHelper.DASHBOARD_PATH
		+ GodotUroHelper.AVATARS_PATH
	)

	var result = await p_requester.request(
		path,
		query,
		p_access_token,
		{"method": HTTPClient.METHOD_POST, "encoding": "multipart"}
	)

	return _handle_result(result)

func dashboard_update_avatar_async(p_requester: GodotUroRequester, p_access_token: String, p_id: String, p_query: Dictionary) -> Dictionary:
	var query: Dictionary = GodotUroHelper.populate_query(AVATAR_NAME, p_query)

	var path: String = (
		GodotUroHelper.get_api_path()
		+ GodotUroHelper.DASHBOARD_PATH
		+ GodotUroHelper.AVATARS_PATH
		+ "/"
		+ str(p_id)
	)
	
	var result = await p_requester.request(
		path,
		query,
		p_access_token,
		{"method": HTTPClient.METHOD_PUT, "encoding": "multipart"}
	)

	return _handle_result(result)


func dashboard_get_avatar_async(p_requester: GodotUroRequester, p_access_token: String, p_id: String) -> Dictionary:
	var query: Dictionary = {}

	var path: String = (
		GodotUroHelper.get_api_path()
		+ GodotUroHelper.DASHBOARD_PATH
		+ GodotUroHelper.AVATARS_PATH
		+ "/"
		+ str(p_id)
	)
	
	var result = await p_requester.request(
		path,
		query,
		p_access_token,
		{"method": HTTPClient.METHOD_GET, "encoding": "form"}
	)

	return _handle_result(result)


##
## Dashboard Map
##


func dashboard_get_maps_async(p_requester: GodotUroRequester, p_access_token: String) -> Dictionary:
	var query: Dictionary = {}

	var path: String = (
		GodotUroHelper.get_api_path()
		+ GodotUroHelper.DASHBOARD_PATH
		+ GodotUroHelper.MAPS_PATH
	)
	
	var result = await p_requester.request(
		path,
		query,
		p_access_token,
		{"method": HTTPClient.METHOD_GET, "encoding": "form"}
	)

	return _handle_result(result)

func dashboard_create_map_async(p_requester: GodotUroRequester, p_access_token: String, p_query: Dictionary) -> Dictionary:
	var query: Dictionary = GodotUroHelper.populate_query(MAP_NAME, p_query)

	var path: String = (
		GodotUroHelper.get_api_path()
		+ GodotUroHelper.DASHBOARD_PATH
		+ GodotUroHelper.MAPS_PATH
	)
	
	var result = await p_requester.request(
		path,
		query,
		p_access_token,
		{"method": HTTPClient.METHOD_POST, "encoding": "multipart"}
	)

	return _handle_result(result)

func dashboard_update_map_async(p_requester: GodotUroRequester, p_access_token: String, p_id: String, p_query: Dictionary) -> Dictionary:
	var query: Dictionary = GodotUroHelper.populate_query(MAP_NAME, p_query)

	var path: String = (
		GodotUroHelper.get_api_path()
		+ GodotUroHelper.DASHBOARD_PATH
		+ GodotUroHelper.MAPS_PATH
		+ "/"
		+ str(p_id)
	)
	
	var result = await p_requester.request(
		path,
		query,
		p_access_token,
		{"method": HTTPClient.METHOD_PUT, "encoding": "multipart"}
	)

	return _handle_result(result)

func dashboard_get_map_async(p_requester: GodotUroRequester, p_access_token: String, p_id: String) -> Dictionary:
	var query: Dictionary = {}

	var path: String = (
		GodotUroHelper.get_api_path()
		+ GodotUroHelper.DASHBOARD_PATH
		+ GodotUroHelper.MAPS_PATH
		+ "/"
		+ str(p_id)
	)
	
	var result = await p_requester.request(
		path,
		query,
		p_access_token,
		{"method": HTTPClient.METHOD_GET, "encoding": "form"}
	)

	return _handle_result(result)

static func _handle_result(result: RefCounted) -> Dictionary:
	var result_dict: Dictionary = {
		"requester_code": -1, "generic_code": -1, "response_code": -1, "output": {}
	}

	if result:
		result_dict["requester_code"] = result.requester_code
		result_dict["generic_code"] = result.generic_code
		result_dict["response_code"] = result.response_code
		result_dict["output"] = result.data

	return result_dict


func _init(p_godot_uro):
	_godot_uro = p_godot_uro
