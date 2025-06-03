# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_prop_manager.gd
# SPDX-License-Identifier: MIT

@tool
extends "res://addons/vsk_manager/vsk_user_content_manager.gd"  # vsk_user_content_manager.gd

var prop_stage_map: Dictionary = {}

signal prop_download_started(p_url)
signal prop_load_callback(p_url, p_callback_id)
signal prop_load_update(p_url, p_stage, p_stage_count)

#TODO: implement prop validation logic
#const validator_prop_const = preload("res://addons/vsk_importer_exporter/vsk_prop_validator.gd")
#var validator_prop = validator_prop_const.new()


func get_request_data_progress(p_prop_path: String) -> Dictionary:
	return VSKAssetManager.get_request_data_progress(p_prop_path)


func _user_content_load_done(
	p_url: String, p_err: int, p_packed_scene: PackedScene, p_skip_validation: bool
) -> void:
	var validator_blocked: bool = false
	var validated_packed_scene: PackedScene = null

	if !p_skip_validation:
		#TODO: using avatar validation as test, implement prop validation logic
		var result_dictionary: Dictionary = VSKImporter.sanitise_packed_scene_for_avatar(
			p_packed_scene
		)
		var validation_result: Dictionary = result_dictionary["result"]
		validated_packed_scene = result_dictionary["packed_scene"]

		if validation_result["code"] != VSKImporter.ImporterResult.OK:
			validator_blocked = true

		super.log_validation_result(p_url, "Prop", validation_result)
	else:
		validated_packed_scene = p_packed_scene

	match p_err:
		VSKAssetManager.ASSET_OK:
			if validator_blocked:
				prop_load_callback.emit(
					p_url, VSKAssetManager.ASSET_FORBIDDEN, validated_packed_scene
				)
			else:
				if validated_packed_scene:
					print("Emit ok for url " + str(p_url))
					prop_load_callback.emit(
						p_url, VSKAssetManager.ASSET_OK, validated_packed_scene
					)
				else:
					prop_load_callback.emit(
						p_url, VSKAssetManager.ASSET_INVALID, validated_packed_scene
					)
		_:
			prop_load_callback.emit(p_url, p_err, validated_packed_scene)


func _user_content_asset_request_started(p_url: String) -> void:
	prop_download_started.emit(p_url)


func _set_loading_stage_count(p_url: String, p_stage_count: int):
	prop_stage_map[p_url] = p_stage_count

	prop_load_update.emit(p_url, 0, prop_stage_map[p_url])


func _set_loading_stage(p_url: String, p_stage: int):
	print(
		"Loading prop {stage}/{stage_count}".format(
			{"stage": str(p_stage), "stage_count": str(prop_stage_map[p_url])}
		)
	)

	prop_load_update.emit(p_url, p_stage, prop_stage_map[p_url])


func cancel_prop(p_prop_path: String) -> void:
	super.cancel_user_content(p_prop_path)


func request_prop(
	p_prop_path: String, p_bypass_whitelist: bool, p_skip_validation: bool
) -> void:
	# TODO: replace with vsk USER_CONTENT_PROP
	await request_user_content_load(
		p_prop_path,
		VSKAssetManager.user_content_type.USER_CONTENT_AVATAR,
		p_bypass_whitelist,
		p_skip_validation,
		{}, {}
		#validator_avatar.valid_external_path_whitelist,
		#validator_avatar.valid_resource_whitelist
	)


func setup():
	#get_settings_values()

	if connect("user_content_load_done", self._user_content_load_done) != OK:
		push_error("Could not connect user_content_load_succeeded")
		return
	if connect("user_content_background_load_stage", self._set_loading_stage) != OK:
		push_error("Could not connect user_content_background_load_stage")
		return
	if connect("user_content_background_load_stage_count", self._set_loading_stage_count) != OK:
		push_error("Could not connect user_content_background_load_stage_count")
		return


func _ready():
	if !Engine.is_editor_hint():
		setup()
		#pass
		# add_commands()
