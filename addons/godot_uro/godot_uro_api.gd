@tool
extends RefCounted

const godot_uro_requester_const = preload("godot_uro_requester.gd")
const godot_uro_helper_const = preload("godot_uro_helper.gd")
const uro_api_const = preload("res://addons/godot_uro/godot_uro_api.gd")

const USER_NAME = "user"
const SHARD_NAME = "shard"
const AVATAR_NAME = "avatar"
const MAP_NAME = "map"

var requester: RefCounted = null
var godot_uro: Node = null


func cancel_async() -> void:
	await requester.cancel()


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


func get_profile_async() -> Dictionary:
	var query: Dictionary = {}

	var result = await (requester.request(
		godot_uro_helper_const.get_api_path() + godot_uro_helper_const.PROFILE_PATH,
		query,
		godot_uro_requester_const.TokenType.ACCESS_TOKEN,
		{"method": HTTPClient.METHOD_GET, "encoding": "form"}
	))

	return uro_api_const._handle_result(result)


func renew_session_async() -> Dictionary:
	var query: Dictionary = {}

	var result = await (requester.request(
		godot_uro_helper_const.get_api_path() + godot_uro_helper_const.SESSION_PATH + godot_uro_helper_const.RENEW_PATH,
		query,
		godot_uro_requester_const.TokenType.RENEWAL_TOKEN,
		{"method": HTTPClient.METHOD_POST, "encoding": "form"}
	))

	return uro_api_const._handle_result(result)


func sign_in_async(p_username_or_email: String, p_password: String) -> Dictionary:
	var query: Dictionary = {
		"user[username_or_email]": p_username_or_email,
		"user[password]": p_password,
	}

	var new_requester = godot_uro.create_requester()

	var result = await (new_requester.request(
		godot_uro_helper_const.get_api_path() + godot_uro_helper_const.SESSION_PATH,
		query,
		godot_uro_requester_const.TokenType.NO_TOKEN,
		{"method": HTTPClient.METHOD_POST, "encoding": "form"}
	))

	requester = new_requester

	return uro_api_const._handle_result(result)


func sign_out_async() -> Dictionary:
	var query: Dictionary = {}

	var result = await (requester.request(
		godot_uro_helper_const.get_api_path() + godot_uro_helper_const.SESSION_PATH,
		query,
		godot_uro_requester_const.TokenType.ACCESS_TOKEN,
		{"method": HTTPClient.METHOD_DELETE, "encoding": "form"}
	))

	return uro_api_const._handle_result(result)


func register_async(
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
		"user[email_notifications]": uro_api_const.bool_to_string(p_email_notifications)
	}

	var result = await (requester.request(
		godot_uro_helper_const.get_api_path() + godot_uro_helper_const.REGISTRATION_PATH,
		query,
		godot_uro_requester_const.TokenType.NO_TOKEN,
		{"method": HTTPClient.METHOD_POST, "encoding": "form"}
	))

	return uro_api_const._handle_result(result)


func create_identity_proof_for_async(p_id: String) -> Dictionary:
	var query: Dictionary = {
		"identity_proof[user_to]": p_id,
	}

	var result = await (requester.request(
		godot_uro_helper_const.get_api_path() + godot_uro_helper_const.IDENTITY_PROOFS_PATH,
		query,
		godot_uro_requester_const.TokenType.ACCESS_TOKEN,
		{"method": HTTPClient.METHOD_POST, "encoding": "form"}
	))

	return uro_api_const._handle_result(result)


func get_identity_proof_async(p_id: String) -> Dictionary:
	var query: Dictionary = {}

	var result = await (requester.request(
		godot_uro_helper_const.get_api_path() + godot_uro_helper_const.IDENTITY_PROOFS_PATH + "/" + p_id,
		query,
		godot_uro_requester_const.TokenType.ACCESS_TOKEN,
		{"method": HTTPClient.METHOD_GET, "encoding": "form"}
	))

	return uro_api_const._handle_result(result)


func create_shard_async(p_query: Dictionary) -> Dictionary:
	var query: Dictionary = godot_uro_helper_const.populate_query(SHARD_NAME, p_query)

	var result = await (requester.request(
		godot_uro_helper_const.get_api_path() + godot_uro_helper_const.SHARDS_PATH,
		query,
		godot_uro_requester_const.TokenType.ACCESS_TOKEN,
		{"method": HTTPClient.METHOD_POST, "encoding": "form"}
	))

	return uro_api_const._handle_result(result)


func delete_shard_async(p_id: String, p_query: Dictionary) -> Dictionary:
	var query: Dictionary = godot_uro_helper_const.populate_query(SHARD_NAME, p_query)

	var result = await (requester.request(
		"%s%s/%s" % [godot_uro_helper_const.get_api_path(), godot_uro_helper_const.SHARDS_PATH, p_id],
		query,
		godot_uro_requester_const.TokenType.ACCESS_TOKEN,
		{"method": HTTPClient.METHOD_DELETE, "encoding": "form"}
	))

	return uro_api_const._handle_result(result)


func update_shard_async(p_id: String, p_query: Dictionary) -> Dictionary:
	var query: Dictionary = godot_uro_helper_const.populate_query(SHARD_NAME, p_query)

	var result = await (requester.request(
		"%s%s/%s" % [godot_uro_helper_const.get_api_path(), godot_uro_helper_const.SHARDS_PATH, p_id],
		query,
		godot_uro_requester_const.TokenType.ACCESS_TOKEN,
		{"method": HTTPClient.METHOD_PUT, "encoding": "form"}
	))

	return uro_api_const._handle_result(result)


func get_shards_async() -> Dictionary:
	var query: Dictionary = godot_uro_helper_const.populate_query(SHARD_NAME, {})

	var result = await (requester.request(
		godot_uro_helper_const.get_api_path() + godot_uro_helper_const.SHARDS_PATH,
		query,
		godot_uro_requester_const.TokenType.NO_TOKEN,
		{"method": HTTPClient.METHOD_GET, "encoding": "form"}
	))

	return godot_uro_helper_const.process_shards_json(uro_api_const._handle_result(result))


func get_avatars_async() -> Dictionary:
	var query: Dictionary = godot_uro_helper_const.populate_query(AVATAR_NAME, {})

	var result = await (requester.request(
		godot_uro_helper_const.get_api_path() + godot_uro_helper_const.AVATARS_PATH,
		query,
		godot_uro_requester_const.TokenType.NO_TOKEN,
		{"method": HTTPClient.METHOD_GET, "encoding": "form"}
	))

	return uro_api_const._handle_result(result)


func get_avatar_async(p_id: String) -> Dictionary:
	var query: Dictionary = {}

	var result = await (requester.request(
		godot_uro_helper_const.get_api_path() + godot_uro_helper_const.AVATARS_PATH + "/" + p_id,
		query,
		godot_uro_requester_const.TokenType.ACCESS_TOKEN,
		{"method": HTTPClient.METHOD_GET, "encoding": "form"}
	))

	return uro_api_const._handle_result(result)


func get_maps_async() -> Dictionary:
	var query: Dictionary = godot_uro_helper_const.populate_query(MAP_NAME, {})

	var result = await (requester.request(
		godot_uro_helper_const.get_api_path() + godot_uro_helper_const.MAPS_PATH,
		query,
		godot_uro_requester_const.TokenType.NO_TOKEN,
		{"method": HTTPClient.METHOD_GET, "encoding": "form"}
	))

	return uro_api_const._handle_result(result)


func get_map_async(p_id: String) -> Dictionary:
	var query: Dictionary = {}

	var result = await (requester.request(
		godot_uro_helper_const.get_api_path() + godot_uro_helper_const.MAPS_PATH + "/" + p_id,
		query,
		godot_uro_requester_const.TokenType.ACCESS_TOKEN,
		{"method": HTTPClient.METHOD_GET, "encoding": "form"}
	))

	return uro_api_const._handle_result(result)


##
## Dashboard Avatar
##


func dashboard_get_avatars_async() -> Dictionary:
	var query: Dictionary = {}

	var path: String = (
		godot_uro_helper_const.get_api_path()
		+ godot_uro_helper_const.DASHBOARD_PATH
		+ godot_uro_helper_const.AVATARS_PATH
	)

	var result = await requester.request(
		path,
		query,
		godot_uro_requester_const.TokenType.ACCESS_TOKEN,
		{"method": HTTPClient.METHOD_GET, "encoding": "form"}
	)
	print("Path " + str(path) + " returned " + str(result) + " type " + str(typeof(result)))

	return uro_api_const._handle_result(result)


func dashboard_create_avatar_async(p_query: Dictionary) -> Dictionary:
	var query: Dictionary = godot_uro_helper_const.populate_query(AVATAR_NAME, p_query)

	var path: String = (
		godot_uro_helper_const.get_api_path()
		+ godot_uro_helper_const.DASHBOARD_PATH
		+ godot_uro_helper_const.AVATARS_PATH
	)

	var result = await requester.request(
		path,
		query,
		godot_uro_requester_const.TokenType.ACCESS_TOKEN,
		{"method": HTTPClient.METHOD_POST, "encoding": "multipart"}
	)

	return uro_api_const._handle_result(result)


func dashboard_update_avatar_async(p_id: String, p_query: Dictionary) -> Dictionary:
	var query: Dictionary = godot_uro_helper_const.populate_query(AVATAR_NAME, p_query)

	var path: String = (
		godot_uro_helper_const.get_api_path()
		+ godot_uro_helper_const.DASHBOARD_PATH
		+ godot_uro_helper_const.AVATARS_PATH
		+ "/"
		+ str(p_id)
	)

	var result = await requester.request(
		path,
		query,
		godot_uro_requester_const.TokenType.ACCESS_TOKEN,
		{"method": HTTPClient.METHOD_PUT, "encoding": "multipart"}
	)

	return uro_api_const._handle_result(result)


func dashboard_get_avatar_async(p_id: String) -> Dictionary:
	var query: Dictionary = {}

	var path: String = (
		godot_uro_helper_const.get_api_path()
		+ godot_uro_helper_const.DASHBOARD_PATH
		+ godot_uro_helper_const.AVATARS_PATH
		+ "/"
		+ str(p_id)
	)

	var result = await requester.request(
		path,
		query,
		godot_uro_requester_const.TokenType.ACCESS_TOKEN,
		{"method": HTTPClient.METHOD_GET, "encoding": "form"}
	)

	return uro_api_const._handle_result(result)


##
## Dashboard Map
##


func dashboard_get_maps_async() -> Dictionary:
	var query: Dictionary = {}

	var path: String = (
		godot_uro_helper_const.get_api_path() + godot_uro_helper_const.DASHBOARD_PATH + godot_uro_helper_const.MAPS_PATH
	)

	var result = await requester.request(
		path,
		query,
		godot_uro_requester_const.TokenType.ACCESS_TOKEN,
		{"method": HTTPClient.METHOD_GET, "encoding": "form"}
	)

	return uro_api_const._handle_result(result)


func dashboard_create_map_async(p_query: Dictionary) -> Dictionary:
	var query: Dictionary = godot_uro_helper_const.populate_query(MAP_NAME, p_query)

	var path: String = (
		godot_uro_helper_const.get_api_path() + godot_uro_helper_const.DASHBOARD_PATH + godot_uro_helper_const.MAPS_PATH
	)

	var result = await requester.request(
		path,
		query,
		godot_uro_requester_const.TokenType.ACCESS_TOKEN,
		{"method": HTTPClient.METHOD_POST, "encoding": "multipart"}
	)

	return uro_api_const._handle_result(result)


func dashboard_update_map_async(p_id: String, p_query: Dictionary) -> Dictionary:
	var query: Dictionary = godot_uro_helper_const.populate_query(MAP_NAME, p_query)

	var path: String = (
		godot_uro_helper_const.get_api_path()
		+ godot_uro_helper_const.DASHBOARD_PATH
		+ godot_uro_helper_const.MAPS_PATH
		+ "/"
		+ str(p_id)
	)

	var result = await requester.request(
		path,
		query,
		godot_uro_requester_const.TokenType.ACCESS_TOKEN,
		{"method": HTTPClient.METHOD_PUT, "encoding": "multipart"}
	)

	return uro_api_const._handle_result(result)


func dashboard_get_map_async(p_id: String) -> Dictionary:
	var query: Dictionary = {}

	var path: String = (
		godot_uro_helper_const.get_api_path()
		+ godot_uro_helper_const.DASHBOARD_PATH
		+ godot_uro_helper_const.MAPS_PATH
		+ "/"
		+ str(p_id)
	)

	var result = await requester.request(
		path,
		query,
		godot_uro_requester_const.TokenType.ACCESS_TOKEN,
		{"method": HTTPClient.METHOD_GET, "encoding": "form"}
	)

	return uro_api_const._handle_result(result)


static func _handle_result(result: RefCounted) -> Dictionary:
	var result_dict: Dictionary = {"requester_code": -1, "generic_code": -1, "response_code": -1, "output": {}}

	if result:
		result_dict["requester_code"] = result.requester_code
		result_dict["generic_code"] = result.generic_code
		result_dict["response_code"] = result.response_code
		result_dict["output"] = result.data

	return result_dict


func _init(p_godot_uro):
	godot_uro = p_godot_uro
	requester = p_godot_uro.create_requester()
