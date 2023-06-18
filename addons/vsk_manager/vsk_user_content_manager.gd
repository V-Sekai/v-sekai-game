# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_user_content_manager.gd
# SPDX-License-Identifier: MIT

@tool
extends Node

const vsk_importer_const = preload("res://addons/vsk_importer_exporter/vsk_importer.gd")
const vsk_asset_manager_const = preload("res://addons/vsk_manager/vsk_asset_manager.gd")

signal user_content_load_done(p_url, p_err, p_packed_scene, p_skip_validation)
signal user_content_background_load_stage(p_url, p_stage)
signal user_content_background_load_stage_count(p_url, p_stage_count)

var asset_requests_in_progress: int = 0
var background_loading_tasks_in_progress: int = 0

var user_content_urls: Dictionary = {}
var background_loading_tasks: Dictionary = {}
var validation_skip_flags: Dictionary = {}


func _finished_background_load_request(p_task_path: String) -> void:
	if not background_loading_tasks.erase(p_task_path):
		push_error("Background load request underflow!")
		return

	background_loading_tasks_in_progress -= 1
	if background_loading_tasks_in_progress == 0:
		if BackgroundLoader.task_done.is_connected(self._background_loader_task_done):
			BackgroundLoader.task_done.disconnect(self._background_loader_task_done)
		if BackgroundLoader.task_set_stage.is_connected(self._background_loader_task_stage):
			BackgroundLoader.task_set_stage.disconnect(self._background_loader_task_stage)
		if BackgroundLoader.task_set_stage_count.is_connected(self._background_loader_task_stage_count):
			BackgroundLoader.task_set_stage_count.disconnect(self._background_loader_task_stage_count)
	elif background_loading_tasks_in_progress < 0:
		push_error("Background load request underflow!")
		return


func _background_loader_task_done(p_task_path: String, p_err: int, p_resource: Resource) -> void:
	if background_loading_tasks.has(p_task_path):
		var url_array: Array = background_loading_tasks[p_task_path]
		_finished_background_load_request(p_task_path)

		# Convert from standard Godot error enum to AssetManager enum
		var asset_err: int = VSKAssetManager.ASSET_OK
		if p_err != OK:
			asset_err = VSKAssetManager.ASSET_RESOURCE_LOAD_FAILED

		for url in url_array:
			user_content_load_done.emit(url, asset_err, p_resource, validation_skip_flags[url])


func _background_loader_task_stage(p_task_path: String, p_stage: int) -> void:
	if background_loading_tasks.has(p_task_path):
		var url_array: Array = background_loading_tasks[p_task_path]
		for url in url_array:
			user_content_background_load_stage.emit(url, p_stage)


func _background_loader_task_stage_count(p_task_path: String, p_stage_count: int) -> void:
	if background_loading_tasks.has(p_task_path):
		var url_array: Array = background_loading_tasks[p_task_path]
		for url in url_array:
			user_content_background_load_stage_count.emit(url, p_stage_count)


func finished_asset_request() -> void:
	asset_requests_in_progress -= 1
	if asset_requests_in_progress == 0:
		VSKAssetManager.request_complete.disconnect(self._user_content_asset_request_complete)
		VSKAssetManager.request_cancelled.disconnect(self._user_content_asset_request_cancelled)
		VSKAssetManager.request_started.disconnect(self._user_content_asset_request_started)
	elif asset_requests_in_progress < 0:
		push_error("Asset request underflow!")
		return


func _user_content_asset_request_complete(p_url: String, p_request_object: Dictionary, p_response_code: int) -> void:
	if user_content_urls.has(p_url):
		finished_asset_request()

		if p_response_code != VSKAssetManager.ASSET_OK:
			printerr("Asset download failed with code: %s" % str(p_response_code))

		if not str(p_request_object["path"]).is_empty():
			user_content_urls[p_url]["stage"] = VSKAssetManager.STAGE_DOWNLOADING
			if !make_background_load_request(p_url, p_request_object["path"], p_request_object["skip_validation"], p_request_object["external_path_whitelist"], p_request_object["resource_whitelist"]):
				printerr("make_background_load_request failed")
		else:
			user_content_load_done.emit(p_url, p_response_code, null, p_request_object["skip_validation"])


func _user_content_asset_request_cancelled(p_url: String) -> void:
	if user_content_urls.has(p_url):
		finished_asset_request()


func _user_content_asset_request_started(_url: String) -> void:
	pass


func cancel_user_content(p_user_content_path: String) -> void:
	if user_content_urls.has(p_user_content_path):
		match user_content_urls[p_user_content_path]["stage"]:
			vsk_asset_manager_const.STAGE_DOWNLOADING:
				VSKAssetManager.cancel_request(p_user_content_path)
			vsk_asset_manager_const.STAGE_BACKGROUND_LOADING:
				BackgroundLoader.cancel_loading_task(user_content_urls[p_user_content_path]["local_path"])

		user_content_urls[p_user_content_path]["stage"] = VSKAssetManager.STAGE_CANCELLING
	else:
		pass


func make_background_load_request(p_url: String, p_user_content_path: String, p_skip_validation: bool, p_external_path_whitelist: Dictionary, p_resource_whitelist: Dictionary) -> bool:
	validation_skip_flags[p_url] = p_skip_validation

	if !background_loading_tasks.has(p_user_content_path):
		background_loading_tasks[p_user_content_path] = [p_url]
		if background_loading_tasks_in_progress == 0:
			if BackgroundLoader.task_done.connect(self._background_loader_task_done) != OK:
				printerr("Could not connect task_finished")
				return false
			if BackgroundLoader.task_set_stage.connect(self._background_loader_task_stage) != OK:
				printerr("Could not connect task_set_stage")
				return false
			if BackgroundLoader.task_set_stage_count.connect(self._background_loader_task_stage_count) != OK:
				printerr("Could not connect task_set_stage_count")
				return false

		background_loading_tasks_in_progress += 1
		if p_skip_validation:
			return BackgroundLoader.request_loading_task_bypass_whitelist(p_user_content_path, "PackedScene")
		else:
			return BackgroundLoader.request_loading_task(p_user_content_path, p_external_path_whitelist, p_resource_whitelist, "PackedScene")
	else:
		# If a loading task for this user content is already in progress,
		# add an extra url to it.
		if background_loading_tasks[p_user_content_path].find(p_url) == -1:
			background_loading_tasks[p_user_content_path].push_back(p_url)
		return true


func make_asset_request(p_user_content_path: String, p_asset_type: int, p_bypass_whitelist: bool, p_skip_validation: bool, p_external_path_whitelist: Dictionary, p_resource_whitelist: Dictionary) -> bool:
	if asset_requests_in_progress == 0:
		var request_complete_result = VSKAssetManager.request_complete.connect(self._user_content_asset_request_complete)
		var request_cancelled_result = VSKAssetManager.request_cancelled.connect(self._user_content_asset_request_cancelled)
		var request_started_result = VSKAssetManager.request_started.connect(self._user_content_asset_request_started)

		if request_complete_result != OK or request_cancelled_result != OK or request_started_result != OK:
			push_error("Failed to connect signals.")
			return false

	asset_requests_in_progress += 1
	var request_result = await VSKAssetManager.make_request(p_user_content_path, p_asset_type, p_bypass_whitelist, p_skip_validation, p_external_path_whitelist, p_resource_whitelist)

	if request_result.is_empty():
		return false
	else:
		return true


func request_user_content_load(p_user_content_path: String, p_asset_type: int, p_bypass_whitelist: bool, p_skip_validation: bool, p_external_path_whitelist: Dictionary, p_resource_whitelist: Dictionary) -> void:
	user_content_urls[p_user_content_path] = {"stage": VSKAssetManager.STAGE_DOWNLOADING, "local_path": ""}

	if !await make_asset_request(p_user_content_path, p_asset_type, p_bypass_whitelist, p_skip_validation, p_external_path_whitelist, p_resource_whitelist):
		printerr("VSKUserContentManager: request %s failed!" % p_user_content_path)


func log_validation_result(p_url: String, p_user_content_type_name: String, p_validation_result: Dictionary) -> void:
	var code: int = p_validation_result["code"]
	var info: String = p_validation_result["info"]

	if code != VSKImporter.ImporterResult.OK:
		var error_message = "{user_content_type_name} at url '{user_content_url}' failed validation check with error '{code_string}'.\nThe following information was provided:\n{info}".format({"user_content_type_name": p_user_content_type_name, "user_content_url": p_url, "code_string": vsk_importer_const.get_string_for_importer_result(code), "info": info if not info.is_empty() else "No extra information provided"})
		push_error(error_message)


func request_user_content_cancel(p_user_content_path: String) -> void:
	cancel_user_content(p_user_content_path)


func setup() -> void:
	pass
