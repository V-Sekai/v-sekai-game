# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_avatar_manager.gd
# SPDX-License-Identifier: MIT

@tool
extends "res://addons/vsk_manager/vsk_user_content_manager.gd"  # vsk_user_content_manager.gd

const USER_PREFERENCES_SECTION_NAME = "avatar"

enum {
	HAND_POSE_OPEN,
	HAND_POSE_NEUTRAL,
	HAND_POSE_POINT,
	HAND_POSE_GUN,
	HAND_POSE_THUMBS_UP,
	HAND_POSE_FIST,
	HAND_POSE_VICTORY,
	HAND_POSE_OK_SIGN,
	HAND_POSE_COUNT,
}

var use_avatar_physics: bool = true
var show_nametags: bool = true

var avatar_stage_map: Dictionary = {}

signal avatar_download_started(p_url)
signal avatar_load_callback(p_url, p_callback_id)
signal avatar_load_update(p_url, p_stage, p_stage_count)

signal nametag_visibility_updated

const validator_avatar_const = preload("res://addons/vsk_importer_exporter/vsk_avatar_validator.gd")
var validator_avatar = validator_avatar_const.new()


func get_request_data_progress(p_avatar_path: String) -> Dictionary:
	return VSKAssetManager.get_request_data_progress(p_avatar_path)


func _user_content_load_done(p_url: String, p_err: int, p_packed_scene: PackedScene, p_skip_validation: bool) -> void:
	var validator_blocked: bool = false
	var validated_packed_scene: PackedScene = null

	if !p_skip_validation:
		var result_dictionary: Dictionary = VSKImporter.sanitise_packed_scene_for_avatar(p_packed_scene)
		var validation_result: Dictionary = result_dictionary["result"]
		validated_packed_scene = result_dictionary["packed_scene"]

		if validation_result["code"] != VSKImporter.ImporterResult.OK:
			validator_blocked = true

		super.log_validation_result(p_url, "Avatar", validation_result)
	else:
		validated_packed_scene = p_packed_scene

	match p_err:
		VSKAssetManager.ASSET_OK:
			if validator_blocked:
				avatar_load_callback.emit(p_url, VSKAssetManager.ASSET_FORBIDDEN, validated_packed_scene)
			else:
				if validated_packed_scene:
					print("Emit ok for url " + str(p_url))
					avatar_load_callback.emit(p_url, VSKAssetManager.ASSET_OK, validated_packed_scene)
				else:
					avatar_load_callback.emit(p_url, VSKAssetManager.ASSET_INVALID, validated_packed_scene)
		_:
			avatar_load_callback.emit(p_url, p_err, validated_packed_scene)


func _user_content_asset_request_started(p_url: String) -> void:
	avatar_download_started.emit(p_url)


func _set_loading_stage_count(p_url: String, p_stage_count: int):
	avatar_stage_map[p_url] = p_stage_count

	avatar_load_update.emit(p_url, 0, avatar_stage_map[p_url])


func _set_loading_stage(p_url: String, p_stage: int):
	print("Loading avatar {stage}/{stage_count}".format({"stage": str(p_stage), "stage_count": str(avatar_stage_map[p_url])}))

	avatar_load_update.emit(p_url, p_stage, avatar_stage_map[p_url])


func cancel_avatar(p_avatar_path: String) -> void:
	super.cancel_user_content(p_avatar_path)


func request_avatar(p_avatar_path: String, p_bypass_whitelist: bool, p_skip_validation: bool) -> void:
	await request_user_content_load(VSKAssetManager.loading_avatar_path, VSKAssetManager.user_content_type.USER_CONTENT_AVATAR, true, true, {}, {})
	await request_user_content_load(p_avatar_path, VSKAssetManager.user_content_type.USER_CONTENT_AVATAR, p_bypass_whitelist, p_skip_validation, validator_avatar.valid_external_path_whitelist, validator_avatar.valid_resource_whitelist)


func set_settings_values():
	VSKUserPreferencesManager.set_value(USER_PREFERENCES_SECTION_NAME, "use_avatar_physics", use_avatar_physics)
	VSKUserPreferencesManager.set_value(USER_PREFERENCES_SECTION_NAME, "show_nametags", show_nametags)


func get_settings_values() -> void:
	use_avatar_physics = VSKUserPreferencesManager.get_value(USER_PREFERENCES_SECTION_NAME, "use_avatar_physics", TYPE_BOOL, use_avatar_physics)
	show_nametags = VSKUserPreferencesManager.get_value(USER_PREFERENCES_SECTION_NAME, "show_nametags", TYPE_BOOL, show_nametags)


func set_settings_values_and_save() -> void:
	set_settings_values()
	VSKUserPreferencesManager.save_settings()


func set_avatar_physics_cmd(p_is_true: bool) -> void:
	use_avatar_physics = p_is_true
	print("use_avatar_physics: %s" % use_avatar_physics)


func set_show_nametags_cmd(p_is_true: bool) -> void:
	show_nametags = p_is_true
	print("show_nametags: %s" % show_nametags)
	nametag_visibility_updated.emit()


func add_commands() -> void:
	pass


func setup():
	get_settings_values()

	if connect("user_content_load_done", self._user_content_load_done) != OK:
		assert(false, "Could not connect user_content_load_succeeded")
	if connect("user_content_background_load_stage", self._set_loading_stage) != OK:
		assert(false, "Could not connect user_content_background_load_stage")
	if connect("user_content_background_load_stage_count", self._set_loading_stage_count) != OK:
		assert(false, "Could not connect user_content_background_load_stage_count")


func _ready():
	if !Engine.is_editor_hint():
		add_commands()
