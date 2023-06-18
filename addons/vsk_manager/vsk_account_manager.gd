# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_account_manager.gd
# SPDX-License-Identifier: MIT

@tool
extends Node

var godot_uro: Node = null

signal registration_request_complete(p_result, p_message)

signal session_renew_started
signal session_request_complete(p_result, p_message)
signal session_deletion_complete(p_result, p_message)

const REFRESH_TIMER = 600  # 10 minutes

const DEFAULT_ACCOUNT_ID = "UNKNOWN_ID"
const DEFAULT_ACCOUNT_USERNAME = "UNKNOWN_USERNAME"
const DEFAULT_ACCOUNT_DISPLAY_NAME = "UNKNOWN_DISPLAY_NAME"

var signed_in: bool = false

var account_id: String = DEFAULT_ACCOUNT_ID
var account_username: String = DEFAULT_ACCOUNT_USERNAME
var account_display_name: String = DEFAULT_ACCOUNT_DISPLAY_NAME

var is_admin: bool = false
var can_upload_avatars: bool = false
var can_upload_maps: bool = false
var can_upload_props: bool = false

var token_refresh_timer: Timer = Timer.new()

var token_refresh_in_progress: bool = false


func is_signed_in() -> bool:
	return signed_in


func _update_session(p_renewal_token: String, p_access_token: String, p_id: String, p_username: String, p_display_name: String, p_user_privilege_rulesets: Dictionary, p_signed_in: bool) -> void:
	if not godot_uro:
		signed_in = false
		return

	signed_in = p_signed_in
	var token_changed: bool = false

	if GodotUroData.renewal_token != p_renewal_token:
		GodotUroData.renewal_token = p_renewal_token
		token_changed = true
	if GodotUroData.access_token != p_access_token:
		GodotUroData.access_token = p_access_token
		token_changed = true

	account_id = p_id
	account_username = p_username
	account_display_name = p_display_name

	is_admin = p_user_privilege_rulesets.get("is_admin", false)
	can_upload_avatars = p_user_privilege_rulesets.get("can_upload_avatars", false)
	can_upload_maps = p_user_privilege_rulesets.get("can_upload_maps", false)
	can_upload_props = p_user_privilege_rulesets.get("can_upload_props", false)

	if not signed_in:
		return

	godot_uro.cfg.set_value("api", "renewal_token", GodotUroData.renewal_token)
	if godot_uro.cfg.save(godot_uro.get_uro_editor_config_path()) != OK:
		printerr("Could not save editor token!")
	if godot_uro.cfg.save(godot_uro.get_uro_config_path()) != OK:
		printerr("Could not save game token!")

	if not token_changed:
		return

	token_refresh_in_progress = false
	if not GodotUroData.renewal_token.is_empty():
		token_refresh_timer.start(REFRESH_TIMER)


func _load_session() -> void:
	if godot_uro:
		GodotUroData.renewal_token = godot_uro.cfg.get_value("api", "renewal_token", "")


func _create_session(p_procesed_result: Dictionary) -> void:
	_update_session(p_procesed_result["renewal_token"], p_procesed_result["access_token"], p_procesed_result["user_id"], p_procesed_result["user_username"], p_procesed_result["user_display_name"], p_procesed_result["user_privilege_ruleset"], true)


func _clear_session() -> void:
	_update_session("", "", DEFAULT_ACCOUNT_ID, DEFAULT_ACCOUNT_USERNAME, DEFAULT_ACCOUNT_DISPLAY_NAME, {}, false)


func _delete_session() -> void:
	_clear_session()
	token_refresh_timer.stop()


func _process_result_and_update(p_result: Dictionary) -> Dictionary:
	if godot_uro:
		var processed_result: Dictionary = godot_uro.godot_uro_helper_const.process_session_json(p_result)

		if godot_uro.godot_uro_helper_const.requester_result_is_ok(processed_result):
			_create_session(processed_result)
		else:
			_clear_session()

		return processed_result
	else:
		return {}


func _process_result_and_delete(p_result: Dictionary) -> Dictionary:
	if not godot_uro:
		return {}

	var processed_result: Dictionary = godot_uro.godot_uro_helper_const.process_session_json(p_result)

	if not godot_uro.godot_uro_helper_const.requester_result_is_ok(processed_result):
		printerr("_process_result_and_delete: %s" % godot_uro.godot_uro_helper_const.get_full_requester_error_string(processed_result))
		return processed_result

	_delete_session()
	return processed_result


func _process_result_and_update_session(p_result: Dictionary) -> Dictionary:
	var processed_result: Dictionary = _process_result_and_update(p_result)

	session_request_complete.emit(processed_result["requester_code"], processed_result["message"])

	return processed_result


func _process_result_and_delete_session(p_result: Dictionary) -> Dictionary:
	var processed_result: Dictionary = _process_result_and_delete(p_result)

	session_deletion_complete.emit(processed_result["requester_code"], processed_result["message"])

	return processed_result


func _process_result_and_update_registration(p_result: Dictionary) -> Dictionary:
	var processed_result: Dictionary = _process_result_and_update(p_result)

	registration_request_complete.emit(processed_result["requester_code"], processed_result["message"])

	return processed_result


func renew_session() -> Dictionary:
	if not godot_uro or not godot_uro.godot_uro_api:
		return {}

	session_renew_started.emit()

	if GodotUroData.renewal_token.is_empty():
		token_refresh_in_progress = false
		_clear_session()
		session_request_complete.emit(godot_uro.godot_uro_helper_const.RequesterCode.NO_TOKEN, "No token")
		return {}

	token_refresh_in_progress = true
	var result = await godot_uro.godot_uro_api.renew_session_async()
	print("renew_session result received.")

	if typeof(result) != TYPE_DICTIONARY:
		push_error("Failed to get_profile_async: " + str(result))
		return {}

	return _process_result_and_update_session(result)


func get_profile_info() -> Dictionary:
	if godot_uro and godot_uro.godot_uro_api:
		var result = await godot_uro.godot_uro_api.get_profile_async()
		if typeof(result) != TYPE_DICTIONARY:
			push_error("Failed to get_profile_async: " + str(result))
			return {}

		return _process_result_and_update_session(result)

	return {}


func sign_in(p_username_or_email: String, p_password: String) -> Dictionary:
	if godot_uro and godot_uro.godot_uro_api:
		token_refresh_in_progress = true
		var result = await godot_uro.godot_uro_api.sign_in_async(p_username_or_email, p_password)
		if typeof(result) != TYPE_DICTIONARY:
			push_error("Failed to get_profile_async: " + str(result))
			return {}

		return _process_result_and_update_session(result)

	return {}


func sign_out() -> Dictionary:
	if godot_uro and godot_uro.godot_uro_api:
		token_refresh_in_progress = true
		var result = await godot_uro.godot_uro_api.sign_out_async()
		if typeof(result) != TYPE_DICTIONARY:
			push_error("Failed to get_profile_async: " + str(result))
			return {}

		return _process_result_and_delete_session(result)

	return {}


func register(p_username: String, p_email: String, p_password: String, p_password_confirmation: String, p_email_notifications: bool) -> Dictionary:
	if godot_uro and godot_uro.godot_uro_api:
		token_refresh_in_progress = true
		var result = await godot_uro.godot_uro_api.register_async(p_username, p_email, p_password, p_password_confirmation, p_email_notifications)
		if typeof(result) != TYPE_DICTIONARY:
			push_error("Failed to get_profile_async: " + str(result))
			return {}

		return _process_result_and_update_registration(result)

	return {}


func create_identity_proof_for(p_id: String) -> Dictionary:
	if godot_uro and godot_uro.godot_uro_api:
		var result = await godot_uro.godot_uro_api.create_identity_proof_for_async(p_id)
		if typeof(result) != TYPE_DICTIONARY:
			push_error("Failed to get_profile_async: " + str(result))
			return {}

		return _process_result_and_update_registration(result)

	return {}


func get_identity_proof(p_id: String) -> Dictionary:
	if godot_uro and godot_uro.godot_uro_api:
		var result = await godot_uro.godot_uro_api.get_identity_proof_async(p_id)
		if typeof(result) != TYPE_DICTIONARY:
			push_error("Failed to get_profile_async: " + str(result))
			return {}

		return _process_result_and_update_registration(result)

	return {}


func _token_refresh_timer_timeout() -> void:
	print("_token_refresh_timer_timeout")
	await renew_session()


# Called manually from another place to load
func start_session() -> void:
	_load_session()
	await renew_session()


##
## Linking
##


func _link_godot_uro(p_node: Node) -> void:
	print("_link_godot_uro")
	godot_uro = p_node


func _unlink_godot_uro() -> void:
	print("_unlink_godot_uro")

	godot_uro = null


func _node_added(p_node: Node) -> void:
	var parent_node: Node = p_node.get_parent()
	if parent_node:
		if !parent_node.get_parent():
			if p_node.get_name() == "GodotUro":
				_link_godot_uro(p_node)


func _node_removed(p_node: Node) -> void:
	if p_node == godot_uro:
		_unlink_godot_uro()


func setup() -> void:
	pass


func _enter_tree() -> void:
	godot_uro = get_node_or_null("/root/GodotUro")

	if Engine.is_editor_hint():
		assert(get_tree().node_added.connect(self._node_added) == OK)
		assert(get_tree().node_removed.connect(self._node_removed) == OK)

	token_refresh_timer = Timer.new()
	token_refresh_timer.set_name("TokenRefreshTimer")
	if token_refresh_timer.timeout.connect(self._token_refresh_timer_timeout) != OK:
		printerr("Could not connect signal 'timeout'")

	add_child(token_refresh_timer, true)
