# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# graphics_manager.gd
# SPDX-License-Identifier: MIT

@tool
extends Node

const USER_PREFERENCES_SECTION_NAME = "graphics"

signal graphics_changed

var set_settings_value_callback: Callable = Callable()
var get_settings_value_callback: Callable = Callable()
var save_settings_callback: Callable = Callable()

var msaa: int = SubViewport.MSAA_DISABLED:
	set = set_msaa

var sss_follow_surface: bool = false:
	set = set_sss_follow_surface

var sss_weight_samples: int = 0:
	set = set_sss_weight_samples

var sss_quality: int = 0:
	set = set_sss_quality

var sss_scale: float = 0:
	set = set_sss_scale

var vct_high: bool = 0:
	set = set_vct_high


# MSAA
func set_msaa(p_msaa: int) -> void:
	if msaa != p_msaa:
		msaa = p_msaa
		graphics_changed.emit()


# Subsurface Scattering
func set_sss_follow_surface(p_follow_surface: bool) -> void:
	if sss_follow_surface != p_follow_surface:
		sss_follow_surface = p_follow_surface
		ProjectSettings.set_setting("rendering/quality/subsurface_scattering/follow_surface", sss_follow_surface)
		graphics_changed.emit()


func set_sss_weight_samples(p_sss_weight_samples: int) -> void:
	if sss_weight_samples != p_sss_weight_samples:
		sss_weight_samples = p_sss_weight_samples
		ProjectSettings.set_setting("rendering/quality/subsurface_scattering/weight_samples", sss_weight_samples)
		graphics_changed.emit()


func set_sss_quality(p_sss_quality: int) -> void:
	if sss_quality != p_sss_quality:
		sss_quality = p_sss_quality
		ProjectSettings.set_setting("rendering/quality/subsurface_scattering/quality", sss_quality)
		graphics_changed.emit()


func set_sss_scale(p_sss_scale: float) -> void:
	if sss_scale != p_sss_scale:
		sss_scale = p_sss_scale
		ProjectSettings.set_setting("rendering/size/subsurface_scattering/size", sss_scale)
		graphics_changed.emit()


func set_vct_high(p_vct_high: bool) -> void:
	if vct_high != p_vct_high:
		vct_high = p_vct_high
		ProjectSettings.set_setting("rendering/size/voxel_cone_tracing/high_quality", vct_high)
		graphics_changed.emit()


func set_settings_value(p_key: String, p_value) -> void:
	if set_settings_value_callback.is_valid():
		set_settings_value_callback.call(USER_PREFERENCES_SECTION_NAME, p_key, p_value)


func set_settings_values():
	# 2D MSAA is not supported in GLES3
	# set_settings_value("msaa", msaa)

	set_settings_value("subsurface_scattering_follow_surface", sss_follow_surface)
	set_settings_value("subsurface_scattering_weight_samples", sss_weight_samples)
	set_settings_value("subsurface_scattering_quality", sss_quality)
	set_settings_value("subsurface_scattering_scale", sss_scale)

	set_settings_value("voxel_cone_tracing_high_quality", vct_high)


func get_settings_value(p_key: String, p_type: int, p_default):
	if get_settings_value_callback.is_valid():
		return get_settings_value_callback.call(USER_PREFERENCES_SECTION_NAME, p_key, p_type, p_default)
	else:
		return p_default


func get_settings_values() -> void:
	msaa = get_settings_value("msaa", TYPE_INT, msaa)

	sss_follow_surface = get_settings_value("subsurface_scattering_follow_surface", TYPE_BOOL, sss_follow_surface)
	sss_weight_samples = get_settings_value("subsurface_scattering_weight_samples", TYPE_INT, sss_weight_samples)
	sss_quality = get_settings_value("subsurface_scattering_quality", TYPE_INT, sss_quality)
	sss_scale = get_settings_value("subsurface_scattering_scale", TYPE_FLOAT, sss_scale)

	vct_high = get_settings_value("voxel_cone_tracing_high_quality", TYPE_BOOL, vct_high)


func is_quitting() -> void:
	set_settings_values()


func assign_set_settings_value_funcref(p_instance: Object, p_function: String) -> void:
	set_settings_value_callback = Callable(p_instance, p_function)


func assign_get_settings_value_funcref(p_instance: Object, p_function: String) -> void:
	get_settings_value_callback = Callable(p_instance, p_function)


func assign_save_settings_funcref(p_instance: Object, p_function: String) -> void:
	save_settings_callback = Callable(p_instance, p_function)


func _ready():
	# Antialiasing
	if typeof(ProjectSettings.get_setting("rendering/anti_aliasing/quality/msaa")) != TYPE_NIL:
		msaa = ProjectSettings.get_setting("rendering/anti_aliasing/quality/msaa")
