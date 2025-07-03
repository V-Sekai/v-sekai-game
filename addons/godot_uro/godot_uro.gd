# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# godot_uro.gd
# SPDX-License-Identifier: MIT

@tool
extends Node
class_name GodotUro

var cfg: ConfigFile = null

const EDITOR_CONFIG_FILE_PATH = "user://uro_editor.ini"
const GAME_CONFIG_FILE_PATH = "user://uro_game.ini"

var godot_uro_api: GodotUroAPI = null
var http_pool = HTTPPool.new()

func load_selected_id() -> String:
	var selected_id: String = ""
	
	if Engine.is_editor_hint():
		if cfg.load_encrypted_pass(get_uro_editor_config_path(), OS.get_unique_id()) != OK:
			return ""
	else:
		if cfg.load_encrypted_pass(get_uro_game_config_path(), OS.get_unique_id()) != OK:
			return ""
			
	if cfg.has_section("api") and cfg.has_section_key("api", "current_id"):
		var value: Variant = cfg.get_value("api", "current_id")
		if value is String:
			selected_id = value
	
	return selected_id
	
func store_selected_id(p_id: String) -> void:
	var _os_unique_id = OS.get_unique_id()
	
	cfg.set_value("api", "current_id", p_id)
	
	if Engine.is_editor_hint():
		cfg.save_encrypted_pass(get_uro_editor_config_path(), OS.get_unique_id())
	else:
		cfg.save_encrypted_pass(get_uro_game_config_path(), OS.get_unique_id())
	
func get_tokens(p_username: String, p_domain: String) -> Dictionary:
	var renewal_token: String = ""
	var access_token: String = ""
	
	var result_dictionary: Dictionary = {}
	result_dictionary["renewal_token"] = renewal_token
	result_dictionary["access_token"] = access_token
	
	if Engine.is_editor_hint():
		if cfg.load_encrypted_pass(get_uro_editor_config_path(), OS.get_unique_id()) != OK:
			return result_dictionary
	else:
		if cfg.load_encrypted_pass(get_uro_game_config_path(), OS.get_unique_id()) != OK:
			return result_dictionary
	
	if cfg.has_section("api"):
		if cfg.has_section_key("api", p_username + "@" + p_domain + "/" + "renewal_token"):
			renewal_token = cfg.get_value("api", p_username + "@" + p_domain + "/" + "renewal_token", "")
		if cfg.has_section_key("api", p_username + "@" + p_domain + "/" + "access_token"):
			access_token = cfg.get_value("api", p_username + "@" + p_domain + "/" + "access_token", "")
	
	result_dictionary["renewal_token"] = renewal_token
	result_dictionary["access_token"] = access_token
	
	return result_dictionary
	
func clear_tokens(p_username: String, p_domain: String) -> void:
	if Engine.is_editor_hint():
		if cfg.load_encrypted_pass(get_uro_editor_config_path(), OS.get_unique_id()) != OK:
			return
	else:
		if cfg.load_encrypted_pass(get_uro_game_config_path(), OS.get_unique_id()) != OK:
			return
		
	if cfg.has_section("api"):
		if cfg.has_section_key("api", p_username + "@" + p_domain + "/" + "renewal_token"):
			cfg.erase_section_key("api", p_username + "@" + p_domain + "/" + "renewal_token")
		if cfg.has_section_key("api", p_username + "@" + p_domain + "/" + "access_token"):
			cfg.erase_section_key("api", p_username + "@" + p_domain + "/" + "access_token")

	cfg.save_encrypted_pass(get_uro_game_config_path(), OS.get_unique_id())

func get_api() -> GodotUroAPI:
	return godot_uro_api

func get_uro_game_config_path() -> String:
	return GAME_CONFIG_FILE_PATH

func get_uro_editor_config_path() -> String:
	return EDITOR_CONFIG_FILE_PATH

static func _is_host_localhost(p_host: String) -> bool:
	if p_host == GodotUroHelper.LOCALHOST_HOST:
		return true
	else:
		return false

func create_requester(p_host: String, p_port: int) -> GodotUroRequester:
	if p_host == "localhost":
		p_host = GodotUroHelper.LOCALHOST_HOST
	
	var new_requester = GodotUroRequester.new(
		http_pool, p_host, p_port, not _is_host_localhost(p_host)
	)

	return new_requester


func _ready() -> void:
	add_child(http_pool)
	

func _init():
	cfg = ConfigFile.new()
	
	# TODO: web support
	if OS.get_name() == "Web":
		push_error("Web platform uro token support is not implemented")
		return
	
	# Get a unique OS ID to encrypt the session keys just in case
	# the file gets stolen.
	var os_unique_id: String = OS.get_unique_id()
	
	if Engine.is_editor_hint():
		if cfg.load_encrypted_pass(get_uro_editor_config_path(), os_unique_id) != OK:
			push_error("Could not load editor token!")
	else:
		if cfg.load_encrypted_pass(get_uro_game_config_path(), os_unique_id) != OK:
			push_error("Could not load game token!")
			
	if Engine.is_editor_hint():
		if cfg.save_encrypted_pass(get_uro_editor_config_path(), os_unique_id) != OK:
			push_error("Could not save editor token!")
	else:
		if cfg.save_encrypted_pass(get_uro_game_config_path(), os_unique_id) != OK:
			push_error("Could not save game token!")

	if godot_uro_api == null:
		godot_uro_api = GodotUroAPI.new(self)
