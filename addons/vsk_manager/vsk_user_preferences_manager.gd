# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_user_preferences_manager.gd
# SPDX-License-Identifier: MIT

@tool
extends Node

####################################
# V-Sekai User Preferences Manager #
####################################

const connection_util_const = preload("res://addons/gd_util/connection_util.gd")

# Important note: the user preference manager must be the last class to connect
# to is_quitting since it is ultimately responsible for serialising the result.

var config: ConfigFile = ConfigFile.new()
const SETTINGS_PATH = "user://settings.cfg"

var signal_table: Array = [{"singleton": "VSKGameFlowManager", "signal": "is_quitting", "method": "save_settings"}]


##
## Called to get a value from a particular section of the ConfigFile.
## p_section is the section name
## p_key is the key for the value
## p_type is the TYPE_ of the variant which is expected. Value from the key must match.
## p_default is the value which should be returned if the key is not found. NULL by default
## Returns the value from p_key in p_section. Returns p_default is not found or p_type does not match.
##
func get_value(p_section: String, p_key: String, p_type: int, p_default = null):
	var value = config.get_value(p_section, p_key, p_default)
	if typeof(value) != p_type:
		printerr("Invalid type {key} in {section}!".format({"key": p_key, "section": p_section}))
		return p_default

	return value


##
## Called to set a value in a particular section of the ConfigFile.
## p_section is the section name
## p_key is the key for the value
## p_value is the TYPE_ of the variant which is expected. Value from the key must match.
##
func set_value(p_section: String, p_key: String, p_value) -> void:
	config.set_value(p_section, p_key, p_value)


##
## Saves ConfigFile to disk.
##
func save_settings() -> void:
	if config.save(SETTINGS_PATH) != OK:
		printerr("Could not save config file!")


##
## Loads ConfigFile to disk.
##
func load_settings() -> void:
	if config.load(SETTINGS_PATH) != OK:
		save_settings()


########
# Node #
########


func _enter_tree() -> void:
	load_settings()


func setup() -> void:
	connection_util_const.connect_signal_table(signal_table, self)
