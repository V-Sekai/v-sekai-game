# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# godot_request_service.gd
# SPDX-License-Identifier: MIT

@tool
extends Node
class_name GodotRequestService

var cfg: ConfigFile = null

const EDITOR_CONFIG_FILE_PATH = "user://vsekai_editor_cfg.ini"
const GAME_CONFIG_FILE_PATH = "user://vsekai_game_cfg.ini"

var godot_request_api: GodotRequestAPI = null
var http_pool = HTTPPool.new()

func load_selected_id() -> String:
	var selected_id: String = ""
	
	if Engine.is_editor_hint():
		if cfg.load_encrypted_pass(get_editor_config_path(), OS.get_unique_id()) != OK:
			return ""
	else:
		if cfg.load_encrypted_pass(get_game_config_path(), OS.get_unique_id()) != OK:
			return ""

	var section_name = get_section_name("api")
	if cfg.has_section(section_name) and cfg.has_section_key(section_name, "current_id"):
		var value: Variant = cfg.get_value(section_name, "current_id")
		if value is String:
			selected_id = value
	
	return selected_id
	
func store_selected_id(p_id: String) -> void:
	var _os_unique_id = OS.get_unique_id()
	var section_name = get_section_name("api")
	
	cfg.set_value(section_name, "current_id", p_id)
	
	var err = FAILED
	if Engine.is_editor_hint():
		err = cfg.save_encrypted_pass(get_editor_config_path(), OS.get_unique_id())
	else:
		err = cfg.save_encrypted_pass(get_game_config_path(), OS.get_unique_id())

	if err != OK:
		push_error("Could not save selected id!")

func store_tokens(p_username: String, p_domain: String, p_access_token: String, p_renewal_token: String) -> void:
	var _os_unique_id = OS.get_unique_id()
	var section_name = get_section_name("api")
	cfg.set_value(section_name, p_username + "@" + p_domain + "/" + "renewal_token", p_renewal_token)
	cfg.set_value(section_name, p_username + "@" + p_domain + "/" + "access_token", p_access_token)

	var err = FAILED
	if Engine.is_editor_hint():
		err = cfg.save_encrypted_pass(get_editor_config_path(), OS.get_unique_id())
	else:
		err = cfg.save_encrypted_pass(get_game_config_path(), OS.get_unique_id())
	
	if err != OK:
		push_error("Could not save access tokens!")

func get_tokens(p_username: String, p_domain: String) -> Dictionary:
	var renewal_token: String = ""
	var access_token: String = ""
	
	var result_dictionary: Dictionary = {}
	result_dictionary["renewal_token"] = renewal_token
	result_dictionary["access_token"] = access_token
	
	if Engine.is_editor_hint():
		if cfg.load_encrypted_pass(get_editor_config_path(), OS.get_unique_id()) != OK:
			return result_dictionary
	else:
		if cfg.load_encrypted_pass(get_game_config_path(), OS.get_unique_id()) != OK:
			return result_dictionary

	var section_name = get_section_name("api")
	if cfg.has_section(section_name):
		if cfg.has_section_key(section_name, p_username + "@" + p_domain + "/" + "renewal_token"):
			renewal_token = cfg.get_value(section_name, p_username + "@" + p_domain + "/" + "renewal_token", "")
		if cfg.has_section_key(section_name, p_username + "@" + p_domain + "/" + "access_token"):
			access_token = cfg.get_value(section_name, p_username + "@" + p_domain + "/" + "access_token", "")
	
	result_dictionary["renewal_token"] = renewal_token
	result_dictionary["access_token"] = access_token
	
	return result_dictionary
	
func clear_tokens(p_username: String, p_domain: String) -> void:
	if Engine.is_editor_hint():
		if cfg.load_encrypted_pass(get_editor_config_path(), OS.get_unique_id()) != OK:
			return
	else:
		if cfg.load_encrypted_pass(get_game_config_path(), OS.get_unique_id()) != OK:
			return
		
	var section_name = get_section_name("api")
	if cfg.has_section(section_name):
		if cfg.has_section_key(section_name, p_username + "@" + p_domain + "/" + "renewal_token"):
			cfg.erase_section_key(section_name, p_username + "@" + p_domain + "/" + "renewal_token")
		if cfg.has_section_key(section_name, p_username + "@" + p_domain + "/" + "access_token"):
			cfg.erase_section_key(section_name, p_username + "@" + p_domain + "/" + "access_token")

	cfg.save_encrypted_pass(get_game_config_path(), OS.get_unique_id())

func get_api() -> GodotRequestAPI:
	return godot_request_api

func get_game_config_path() -> String:
	return GAME_CONFIG_FILE_PATH

func get_editor_config_path() -> String:
	return EDITOR_CONFIG_FILE_PATH

func get_section_name(section: String) -> String:
	return get_service_name() + "_" + section

func get_service_name() -> String:
	return "default"

static func _is_host_localhost(p_host: String) -> bool:
	if p_host == GodotRequestHelper.LOCALHOST_HOST:
		return true
	else:
		return false

static func _is_host_ssl(p_host: String) -> bool:
	var disable_ssl: bool = ProjectSettings.get_setting("debug/network/disable_ssl", false)
	if _is_host_localhost(p_host):
		return false
	elif disable_ssl:
		return false
	else:
		return true

func create_requester(p_host: String, p_port: int) -> GodotRequester:
	if p_host == "localhost":
		p_host = GodotRequestHelper.LOCALHOST_HOST
	
	var new_requester = GodotRequester.new(
		http_pool, p_host, p_port, _is_host_ssl(p_host)
	)

	return new_requester


func _load_api() -> void:
	if godot_request_api == null:
		godot_request_api = GodotRequestAPI.new(self)	

func _ready() -> void:
	add_child(http_pool)
	

func _init():
	cfg = ConfigFile.new()
	
	# TODO: web support
	if OS.get_name() == "Web":
		push_error("Web platform API token support is not implemented")
		return
	
	# Get a unique OS ID to encrypt the session keys just in case
	# the file gets stolen.
	var os_unique_id: String = OS.get_unique_id()
	
	if Engine.is_editor_hint():
		if cfg.load_encrypted_pass(get_editor_config_path(), os_unique_id) != OK:
			push_error("Could not load editor token!")
	else:
		if cfg.load_encrypted_pass(get_game_config_path(), os_unique_id) != OK:
			push_error("Could not load game token!")
			
	if Engine.is_editor_hint():
		if cfg.save_encrypted_pass(get_editor_config_path(), os_unique_id) != OK:
			push_error("Could not save editor token!")
	else:
		if cfg.save_encrypted_pass(get_game_config_path(), os_unique_id) != OK:
			push_error("Could not save game token!")

	_load_api()
