# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# sar1_mocap_manager.gd
# SPDX-License-Identifier: MIT

@tool
extends Node
class_name MocapManager

const mocap_functions_const = preload("sar1_mocap_functions.gd")
const mocap_constants_const = preload("sar1_mocap_constants.gd")

const USER_PREFERENCES_SECTION_NAME = "mocap"

var set_settings_value_callback: Callable = Callable()
var get_settings_value_callback: Callable = Callable()
var save_settings_callback: Callable = Callable()

var recording_enabled: bool = false

#


static func start_recording(p_fps: int) -> MocapRecording:
	var mocap_recording: MocapRecording = null
	var dict: Dictionary = mocap_functions_const._incremental_mocap_file_path({"mocap_directory": "user://" + mocap_constants_const.MOCAP_DIR})
	if dict["error"] == OK:
		mocap_recording = MocapRecording.new(dict["path"])
		if mocap_recording.open_file_write() == OK:
			mocap_recording.set_version(mocap_constants_const.MOCAP_VERSION)
			mocap_recording.set_fps(p_fps)
			mocap_recording.write_mocap_header()
		else:
			printerr("Could not open mocap file for writing")

	return mocap_recording


func set_settings_value(p_key: String, p_value) -> void:
	if set_settings_value_callback.is_valid():
		set_settings_value_callback.call(USER_PREFERENCES_SECTION_NAME, p_key, p_value)


func set_settings_values():
	set_settings_value("recording_enabled", recording_enabled)


func get_settings_value(p_key: String, p_type: int, p_default):
	if get_settings_value_callback.is_valid():
		return get_settings_value_callback.call(USER_PREFERENCES_SECTION_NAME, p_key, p_type, p_default)
	else:
		return p_default


func is_quitting() -> void:
	set_settings_values()


func get_settings_values() -> void:
	recording_enabled = get_settings_value("recording_enabled", TYPE_BOOL, recording_enabled)


func assign_set_settings_value_funcref(p_instance: Object, p_function: String) -> void:
	set_settings_value_callback = Callable(p_instance, p_function)


func assign_get_settings_value_funcref(p_instance: Object, p_function: String) -> void:
	get_settings_value_callback = Callable(p_instance, p_function)


func assign_save_settings_funcref(p_instance: Object, p_function: String) -> void:
	save_settings_callback = Callable(p_instance, p_function)


func _ready():
	if not ProjectSettings.has_setting("mocap_manager/recording_enabled"):
		ProjectSettings.set_setting("mocap_manager/recording_enabled", false)
	recording_enabled = ProjectSettings.get_setting("mocap_manager/recording_enabled")
	var directory: DirAccess = DirAccess.open("user://")
	if !directory.dir_exists("user://mocap"):
		if directory.make_dir_recursive("user://mocap") != OK:
			printerr("Could not create mocap directory")
