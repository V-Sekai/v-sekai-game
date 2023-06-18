# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_player_manager.gd
# SPDX-License-Identifier: MIT

@tool
extends Node

##########################
# V-Sekai Player Manager #
##########################

const connection_util_const = preload("res://addons/gd_util/connection_util.gd")
const USER_PREFERENCES_SECTION_NAME = "player"

var signal_table: Array = [{"singleton": "VSKGameFlowManager", "signal": "is_quitting", "method": "set_settings_values"}]

signal display_name_changed(p_name)
signal avatar_path_changed(p_path)

var display_name: String = "Player":
	set = set_display_name

var avatar_path: String


func set_display_name(p_name: String) -> void:
	if p_name != display_name:
		display_name = p_name
		display_name_changed.emit(display_name)


func set_avatar_path(p_path: String) -> void:
	if p_path != avatar_path:
		avatar_path = p_path
		avatar_path_changed.emit(avatar_path)


func set_display_name_cmd(p_name: String) -> void:
	set_display_name(p_name)
	print("Display name changed to '%s'" % p_name)


func set_avatar_path_cmd(p_path: String) -> void:
	set_avatar_path(p_path)
	print("Avatar path changed to '%s'" % p_path)


func print_display_name_cmd() -> void:
	print(display_name)


func print_avatar_path_cmd() -> void:
	print(avatar_path)


func set_settings_values() -> void:
	VSKUserPreferencesManager.set_value(USER_PREFERENCES_SECTION_NAME, "display_name", display_name)
	VSKUserPreferencesManager.set_value(USER_PREFERENCES_SECTION_NAME, "avatar_path", avatar_path)


func get_settings_values() -> void:
	display_name = VSKUserPreferencesManager.get_value(USER_PREFERENCES_SECTION_NAME, "display_name", TYPE_STRING, display_name)
	avatar_path = VSKUserPreferencesManager.get_value(USER_PREFERENCES_SECTION_NAME, "avatar_path", TYPE_STRING, avatar_path)


func set_settings_values_and_save() -> void:
	set_settings_values()
	VSKUserPreferencesManager.save_settings()


func add_commands() -> void:
	pass


func setup() -> void:
	if !Engine.is_editor_hint():
		connection_util_const.connect_signal_table(signal_table, self)
		get_settings_values()


func _ready():
	if !Engine.is_editor_hint():
		add_commands()
