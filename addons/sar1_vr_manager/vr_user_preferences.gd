# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vr_user_preferences.gd
# SPDX-License-Identifier: MIT

@tool
extends RefCounted

signal settings_changed

const USER_PREFERENCES_SECTION_NAME = "vr"

var set_settings_value_callback: Callable = Callable()
var get_settings_value_callback: Callable = Callable()
var save_settings_callback: Callable = Callable()


class hand_enum:
	const LEFT_HAND = 0
	const RIGHT_HAND = 1


class vr_mode_override_enum:
	const VR_MODE_USE_CONFIG = 0
	const VR_MODE_USE_FLAT = 1
	const VR_MODE_USE_VR = 2


var vr_mode_override: int = vr_mode_override_enum.VR_MODE_USE_CONFIG

@export var vr_mode_enabled: bool = true


class vr_hmd_mirroring_enum:
	const HMD_MIRROR_FLAT_UI = 0
	const HMD_MIRROR_VR = 1


@export var vr_hmd_mirroring: int = vr_hmd_mirroring_enum.HMD_MIRROR_FLAT_UI


class vr_control_type_enum:
	const CONTROL_TYPE_CLASSIC = 0
	const CONTROL_TYPE_DUAL_HAND_CONTROLLERS = 1


@export var vr_control_type: int = vr_control_type_enum.CONTROL_TYPE_DUAL_HAND_CONTROLLERS


class body_awareness_enum:
	const BODY_AWARENESS_HANDS_ONLY = 0
	const BODY_AWARENESS_CONTROLLERS_ONLY = 1
	const BODY_AWARENESS_FULL_BODY = 2


@export var body_awareness: int = body_awareness_enum.BODY_AWARENESS_HANDS_ONLY

@export var fov_comfort_mode: bool = true

@export var movement_on_rotation_controller: bool = false
@export var click_to_move: bool = false

@export var strafe_movement: bool = true
@export var always_move_at_full_speed: bool = true

@export var movement_deadzone: float = 0.2

@export var rotation_sensitivity: float = 1.0
@export var rotation_deadzone: float = 0.2

@export var max_positional_distance_start: float = 1.0
@export var max_positional_distance_end: float = 1.1

const TURNING_MODE_SMOOTH = 0
const TURNING_MODE_SNAP_30 = 1
const TURNING_MODE_SNAP_45 = 2
const TURNING_MODE_SNAP_90 = 3
const TURNING_MODE_SNAP_CUSTOM = 4

@export var turning_mode: int = TURNING_MODE_SMOOTH
@export var snap_turning_degrees_custom: int = 0


class play_position_enum:
	const PLAY_POSITION_STANDING = 0
	const PLAY_POSITION_SEATED = 1


@export var play_position: int = play_position_enum.PLAY_POSITION_STANDING


class movement_orientation_enum:
	const HEAD_ORIENTED_MOVEMENT = 0
	const HAND_ORIENTED_MOVEMENT = 1
	const PLAYSPACE_ORIENTED_MOVEMENT = 2


@export var movement_orientation: int = movement_orientation_enum.HEAD_ORIENTED_MOVEMENT
@export var preferred_hand_oriented_movement_hand: int = hand_enum.LEFT_HAND


class movement_type_enum:
	const MOVEMENT_TYPE_TELEPORT = 0
	const MOVEMENT_TYPE_LOCOMOTION = 1


var movement_type: int = movement_type_enum.MOVEMENT_TYPE_LOCOMOTION

# 1.0 arm vs 0.0 eye
@export var eye_to_arm_ratio: float = 1.0

# Measured in centimeters
@export var custom_player_height: float = 1.63

# Full armspan/wingspan (to fingers).
# Data indicates that the average armspan is that of overall height
@export var custom_player_armspan_to_height_ratio: float = 1.0

@export var laser_color: Color = Color(1.0, 0, 0, 0.5)


func set_settings_values_and_save() -> void:
	set_settings_values()
	if save_settings_callback.is_valid():
		save_settings_callback.call()


func set_settings_value(p_key: String, p_value) -> void:
	if set_settings_value_callback.is_valid():
		set_settings_value_callback.call(USER_PREFERENCES_SECTION_NAME, p_key, p_value)


func set_settings_values():
	set_settings_value("vr_mode_enabled", vr_mode_enabled)
	set_settings_value("vr_hmd_mirroring", vr_hmd_mirroring)
	set_settings_value("vr_control_type", vr_control_type)
	set_settings_value("body_awareness", body_awareness)
	set_settings_value("fov_comfort_mode", fov_comfort_mode)
	set_settings_value("click_to_move", click_to_move)
	set_settings_value("strafe_movement", strafe_movement)
	set_settings_value("always_move_at_full_speed", always_move_at_full_speed)
	set_settings_value("movement_on_rotation_controller", movement_on_rotation_controller)
	set_settings_value("rotation_sensitivity", rotation_sensitivity)
	set_settings_value("movement_deadzone", movement_deadzone)
	set_settings_value("rotation_deadzone", rotation_deadzone)
	set_settings_value("max_positional_distance_start", max_positional_distance_start)
	set_settings_value("max_positional_distance_end", max_positional_distance_end)
	set_settings_value("turning_mode", turning_mode)
	set_settings_value("snap_turning_degrees_custom", snap_turning_degrees_custom)
	set_settings_value("play_position", play_position)
	set_settings_value("movement_orientation", movement_orientation)
	set_settings_value("preferred_hand_oriented_movement_hand", preferred_hand_oriented_movement_hand)
	set_settings_value("eye_to_arm_ratio", eye_to_arm_ratio)
	set_settings_value("custom_player_height", custom_player_height)
	set_settings_value("custom_player_armspan_to_height_ratio", custom_player_armspan_to_height_ratio)
	set_settings_value("laser_color", laser_color)
	set_settings_value("movement_type", movement_type)

	settings_changed.emit()


func get_settings_value(p_key: String, p_type: int, p_default):
	if get_settings_value_callback.is_valid():
		return get_settings_value_callback.call(USER_PREFERENCES_SECTION_NAME, p_key, p_type, p_default)
	else:
		return p_default


func get_settings_values() -> void:
	match vr_mode_override:
		vr_mode_override_enum.VR_MODE_USE_CONFIG:
			vr_mode_enabled = get_settings_value("vr_mode_enabled", TYPE_BOOL, vr_mode_enabled)
		vr_mode_override_enum.VR_MODE_USE_VR:
			vr_mode_enabled = true
		vr_mode_override_enum.VR_MODE_USE_FLAT:
			vr_mode_enabled = false

	vr_hmd_mirroring = get_settings_value("vr_hmd_mirroring", TYPE_INT, vr_hmd_mirroring)
	vr_control_type = get_settings_value("vr_control_type", TYPE_INT, vr_control_type)
	body_awareness = get_settings_value("body_awareness", TYPE_INT, body_awareness)
	fov_comfort_mode = get_settings_value("fov_comfort_mode", TYPE_BOOL, fov_comfort_mode)
	click_to_move = get_settings_value("click_to_move", TYPE_BOOL, click_to_move)
	strafe_movement = get_settings_value("strafe_movement", TYPE_BOOL, strafe_movement)
	always_move_at_full_speed = get_settings_value("always_move_at_full_speed", TYPE_BOOL, always_move_at_full_speed)
	movement_on_rotation_controller = get_settings_value(
		"movement_on_rotation_controller", TYPE_BOOL, movement_on_rotation_controller
	)
	rotation_sensitivity = get_settings_value("rotation_sensitivity", TYPE_FLOAT, rotation_sensitivity)
	movement_deadzone = get_settings_value("movement_deadzone", TYPE_FLOAT, movement_deadzone)
	rotation_deadzone = get_settings_value("rotation_deadzone", TYPE_FLOAT, rotation_deadzone)
	max_positional_distance_start = get_settings_value(
		"max_positional_distance_start", TYPE_FLOAT, max_positional_distance_start
	)
	max_positional_distance_end = get_settings_value(
		"max_positional_distance_end", TYPE_FLOAT, max_positional_distance_end
	)
	turning_mode = get_settings_value("turning_mode", TYPE_INT, turning_mode)
	snap_turning_degrees_custom = get_settings_value(
		"snap_turning_degrees_custom", TYPE_INT, snap_turning_degrees_custom
	)
	play_position = get_settings_value("play_position", TYPE_INT, play_position)
	movement_orientation = get_settings_value("movement_orientation", TYPE_INT, movement_orientation)
	preferred_hand_oriented_movement_hand = get_settings_value(
		"preferred_hand_oriented_movement_hand", TYPE_INT, preferred_hand_oriented_movement_hand
	)
	eye_to_arm_ratio = get_settings_value("eye_to_arm_ratio", TYPE_FLOAT, eye_to_arm_ratio)
	custom_player_height = get_settings_value("custom_player_height", TYPE_FLOAT, custom_player_height)
	custom_player_armspan_to_height_ratio = get_settings_value(
		"custom_player_armspan_to_height_ratio", TYPE_FLOAT, custom_player_armspan_to_height_ratio
	)
	laser_color = get_settings_value("laser_color", TYPE_COLOR, laser_color)
	movement_type = get_settings_value("movement_type", TYPE_INT, movement_type)


func assign_set_settings_value_funcref(p_instance: Object, p_function: String) -> void:
	set_settings_value_callback = Callable(p_instance, p_function)


func assign_get_settings_value_funcref(p_instance: Object, p_function: String) -> void:
	get_settings_value_callback = Callable(p_instance, p_function)


func assign_save_settings_funcref(p_instance: Object, p_function: String) -> void:
	save_settings_callback = Callable(p_instance, p_function)
