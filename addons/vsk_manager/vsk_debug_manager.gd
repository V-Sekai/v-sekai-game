# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_debug_manager.gd
# SPDX-License-Identifier: MIT

@tool
extends Node

const USER_PREFERENCES_SECTION_NAME = "debug"

signal noclip_changed

var developer_mode: bool = false
var noclip_mode: bool = false


func toggle_noclip() -> void:
	noclip_mode = !noclip_mode
	if developer_mode:
		print("Noclip mode: %s" % noclip_mode)
		noclip_changed.emit()
	else:
		print("Requires developer mode to be enabled!")


func set_settings_values():
	VSKUserPreferencesManager.set_value(USER_PREFERENCES_SECTION_NAME, "developer_mode", developer_mode)


func get_settings_values() -> void:
	developer_mode = VSKUserPreferencesManager.get_value(USER_PREFERENCES_SECTION_NAME, "developer_mode", TYPE_BOOL, developer_mode)


func set_settings_values_and_save() -> void:
	set_settings_values()
	VSKUserPreferencesManager.save_settings()


func setup() -> void:
	pass


func add_commands() -> void:
	pass


func _ready():
	get_settings_values()

	if !Engine.is_editor_hint():
		add_commands()
