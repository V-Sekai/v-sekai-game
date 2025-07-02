# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_game_asset_manager.gd
# SPDX-License-Identifier: MIT

@tool
extends SarGameAssetManager
class_name VSKGameAssetManager

## The VSKGameAssetManager class extends the base SarGameAssetManager
## with a unified interface which allows assets to be fetched from an
## abstract set of sources.
##
## Some of the sources include local files, files fetched via
## HTTP request, and files fetched from the Uro web service, and this
## functionality can be extended as needed. Requests made will provide
## VSKGameAssetRequest objects so that systems interacting with the
## manager can keep track of their object's progress.
## It will also register various GLTF extensions which V-Sekai provides
## support for including VRM and OMI extensions.

enum RequestType {
	INVALID_REQUEST,
	HTTP_REQUEST,
	LOCAL_FILE_REQUEST,
	URO_REQUEST
}

var avatar_forbidden_packed_scene: PackedScene = null
var avatar_not_found_packed_scene: PackedScene = null
var avatar_error_packed_scene: PackedScene = null
var teapot_packed_scene: PackedScene = null
var loading_avatar_packed_scene: PackedScene = null

## Path to a fallback avatar used when the request for an avatar type asset is classified
## as forbidden.
var avatar_forbidden_path: String = "res://addons/vsk_game_framework/scenes/avatars/error_handlers/avatar_forbidden.tscn"
## Path to a fallback avatar used when the request for an avatar type asset is not found.
var avatar_not_found_path: String = "res://addons/vsk_game_framework/scenes/avatars/error_handlers/avatar_not_found.tscn"
## Path to a fallback avatar used when the request for an avatar type asset is classified
## as having caused an error.
var avatar_error_path: String = "res://addons/vsk_game_framework/scenes/avatars/error_handlers/avatar_error.tscn"
## Path to a fallback avatar used when the request for an avatar which refuses to brew coffee
## because it is, permanently, a teapot.
var teapot_path: String = "res://addons/vsk_game_framework/scenes/avatars/error_handlers/teapot.tscn"
## Path to avatar to be used to indicate that a new avatar is being loaded.
var loading_avatar_path: String = "res://addons/vsk_game_framework/scenes/avatars/loading/loading_orb.tscn"

var avatar_allow_list: PackedStringArray = []
var map_allow_list: PackedStringArray = []
var prop_allow_list: PackedStringArray = []
var game_mode_allow_list: PackedStringArray = []

enum AssetType {
	UNKNOWN,
	AVATAR,
	MAP,
	PROP,
	GAME_MODE
}

var _request_objects: Dictionary[String, VSKGameAssetRequest] = {}

# This function should add GLTF extensions to the _global_extensions array which contains
# GLTFDocumentExtensions which should be loaded and unloaded during the lifecycle of the
# VSKGameAssetManager. All potentially supported extensions should be added here, irrespective
# of support in the context of a particular asset type due to limitation of extensions being 
# a global state and desiring thread parallelism for loading.
# If certain extension functionality is desired or undesired for a particular asset
# type, it will have to be supported via the set_additional_data property.
func _fetch_global_extensions() -> void:
	super._fetch_global_extensions()
	
	# VRM extensions.
	_global_extensions.push_back(preload("res://addons/vrm/vrm_extension.gd").new())
	_global_extensions.push_back(preload("res://addons/vrm/1.0/VRMC_materials_mtoon.gd").new())
	_global_extensions.push_back(preload("res://addons/vrm/1.0/VRMC_materials_hdr_emissiveMultiplier.gd").new())
	_global_extensions.push_back(preload("res://addons/vrm/1.0/VRMC_springBone.gd").new())
	_global_extensions.push_back(preload("res://addons/vrm/1.0/VRMC_node_constraint.gd").new())
	_global_extensions.push_back(preload("res://addons/vrm/1.0/VRMC_vrm.gd").new())

func _request_complete(_error: VSKGameAssetRequest.AssetError, p_request_url: String) -> void:
	if _request_objects.has(p_request_url):
		var request_obj: VSKGameAssetRequest = _request_objects[p_request_url]
		_request_objects.erase(p_request_url)
		request_obj.cleanup()
		
func _get_request_data_progress_internal(p_request_object: VSKGameAssetRequest) -> float:
	return p_request_object.get_progress()

func _get_or_create_request_object_for_type(p_request_url: String, p_asset_type: AssetType, p_request_type: RequestType) -> VSKGameAssetRequest:
	var request_obj: VSKGameAssetRequest = null
	if _request_objects.has(p_request_url):
		request_obj = _request_objects[p_request_url]
		match p_request_type:
			RequestType.HTTP_REQUEST:
				if request_obj is VSKGameAssetRequestHTTP:
					return request_obj
				else:
					push_error("Existing asset request for %s is not a valid HTTP request.")
			RequestType.LOCAL_FILE_REQUEST:
				if request_obj is VSKGameAssetRequestLocal:
					return request_obj
				else:
					push_error("Existing asset request for %s is not a valid local file request.")
			RequestType.URO_REQUEST:
				if request_obj is VSKGameAssetRequestUro:
					return request_obj
				else:
					push_error("Existing asset request for %s is not a valid Uro request.")
	else:
		match p_request_type:
			RequestType.HTTP_REQUEST:
				request_obj = VSKGameAssetRequestHTTP.new(self, p_request_url, p_asset_type)
				request_obj.execute_request.call_deferred()
				_request_objects[p_request_url] = request_obj
				if not SarUtils.assert_ok(request_obj.request_complete.connect(_request_complete.bind(p_request_url)),
					"Could not connect signal 'request_obj.request_complete' to '_request_complete.bind(p_request_url)'"):
					return null
			RequestType.LOCAL_FILE_REQUEST:
				request_obj = VSKGameAssetRequestLocal.new(self, p_request_url, p_asset_type)
				request_obj.execute_request.call_deferred()
				_request_objects[p_request_url] = request_obj
				if not SarUtils.assert_ok(request_obj.request_complete.connect(_request_complete.bind(p_request_url)),
					"Could not connect signal 'request_obj.request_complete' to '_request_complete.bind(p_request_url)'"):
					return null
			RequestType.URO_REQUEST:
				request_obj = VSKGameAssetRequestUro.new(self, p_request_url, p_asset_type)
				request_obj.execute_request.call_deferred()
				_request_objects[p_request_url] = request_obj
				if not SarUtils.assert_ok(request_obj.request_complete.connect(_request_complete.bind(p_request_url)),
					"Could not connect signal 'request_obj.request_complete' to '_request_complete.bind(p_request_url)'"):
					return null
			_:
				push_error("Unknown file request type: %s" % str(p_request_url))
				return null
			
	return request_obj

static func _get_request_type(p_request_path: String) -> RequestType:
	var path_lower: String = p_request_path.to_lower()
	if path_lower.begins_with("https://") or path_lower.begins_with("http://"):
		return RequestType.HTTP_REQUEST
	elif path_lower.begins_with("file:///") or path_lower.begins_with("res://"):
		return RequestType.LOCAL_FILE_REQUEST
	elif path_lower.begins_with("uro:///") or path_lower.begins_with("uro://"):
		return RequestType.URO_REQUEST
	else:
		return RequestType.INVALID_REQUEST

func _get_project_settings() -> void:
	if ProjectSettings.has_setting("ugc/config/avatar_forbidden_path"):
		avatar_forbidden_path = ProjectSettings.get_setting("ugc/config/avatar_forbidden_path")
	if ProjectSettings.has_setting("ugc/config/avatar_not_found_path"):
		avatar_not_found_path = ProjectSettings.get_setting("ugc/config/avatar_not_found_path")
	if ProjectSettings.has_setting("ugc/config/avatar_error_path"):
		avatar_error_path = ProjectSettings.get_setting("ugc/config/avatar_error_path")
	if ProjectSettings.has_setting("ugc/config/teapot_path"):
		teapot_path = ProjectSettings.get_setting("ugc/config/teapot_path")

	if ProjectSettings.has_setting("ugc/config/loading_avatar_path"):
		loading_avatar_path = ProjectSettings.get_setting("ugc/config/loading_avatar_path")

	if ProjectSettings.has_setting("ugc/config/avatar_allow_list"):
		avatar_allow_list = ProjectSettings.get_setting("ugc/config/avatar_allow_list")
	if ProjectSettings.has_setting("ugc/config/prop_allow_list"):
		prop_allow_list = ProjectSettings.get_setting("ugc/config/prop_allow_list")
	if ProjectSettings.has_setting("ugc/config/map_allow_list"):
		map_allow_list = ProjectSettings.get_setting("ugc/config/map_allow_list")
	if ProjectSettings.has_setting("ugc/config/game_mode_allow_list"):
		game_mode_allow_list = ProjectSettings.get_setting("ugc/config/game_mode_allow_list")

func _apply_project_settings() -> void:
	if Engine.is_editor_hint():
		if !ProjectSettings.has_setting("assets/config/avatar_forbidden_path"):
			ProjectSettings.set_setting("assets/config/avatar_forbidden_path", avatar_forbidden_path)

		if !ProjectSettings.has_setting("assets/config/avatar_not_found_path"):
			ProjectSettings.set_setting("assets/config/avatar_not_found_path", avatar_not_found_path)

		if !ProjectSettings.has_setting("assets/config/avatar_error_path"):
			ProjectSettings.set_setting("assets/config/avatar_error_path", avatar_error_path)

		if !ProjectSettings.has_setting("assets/config/teapot_path"):
			ProjectSettings.set_setting("assets/config/teapot_path", teapot_path)

		if !ProjectSettings.has_setting("assets/config/loading_avatar_path"):
			ProjectSettings.set_setting("assets/config/loading_avatar_path", loading_avatar_path)

		if !ProjectSettings.has_setting("assets/config/avatar_allow_list"):
			ProjectSettings.set_setting("assets/config/avatar_allow_list", avatar_allow_list)

		if !ProjectSettings.has_setting("assets/config/prop_allow_list"):
			ProjectSettings.set_setting("assets/config/prop_allow_list", prop_allow_list)

		if !ProjectSettings.has_setting("assets/config/map_allow_list"):
			ProjectSettings.set_setting("assets/config/map_allow_list", map_allow_list)

		if !ProjectSettings.has_setting("assets/config/game_mode_allow_list"):
			ProjectSettings.set_setting("assets/config/game_mode_allow_list", game_mode_allow_list)

		if ProjectSettings.save() != OK:
			push_error("VSKAssetManager: could not save project settings!")

func _ready() -> void:
	if Engine.is_editor_hint():
		_apply_project_settings()
		_get_project_settings()
	else:
		if not DirAccess.dir_exists_absolute(get_asset_cache_path()):
			if DirAccess.make_dir_absolute(get_asset_cache_path()) != OK:
				push_error("Could not create asset cache directory!")

		if not DirAccess.dir_exists_absolute(get_unvalidated_assets_path()):
			if DirAccess.make_dir_absolute(get_unvalidated_assets_path()) != OK:
				push_error("Could not create unvalidated assets directory!")
				
		_get_project_settings()
		
		avatar_forbidden_packed_scene = ResourceLoader.load(avatar_forbidden_path)
		SarUtils.assert_true(avatar_forbidden_packed_scene, "Could not load %s" % avatar_forbidden_path)
		avatar_not_found_packed_scene = ResourceLoader.load(avatar_not_found_path)
		SarUtils.assert_true(avatar_not_found_packed_scene, "Could not load %s" % avatar_not_found_path)
		avatar_error_packed_scene = ResourceLoader.load(avatar_error_path)
		SarUtils.assert_true(avatar_error_packed_scene, "Could not load %s" % avatar_error_path)
		teapot_packed_scene = ResourceLoader.load(teapot_path)
		SarUtils.assert_true(teapot_packed_scene, "Could not load %s" % teapot_path)
		loading_avatar_packed_scene = ResourceLoader.load(loading_avatar_path)
		SarUtils.assert_true(loading_avatar_packed_scene, "Could not load %s" % loading_avatar_path)

###

## Returns a string representing the download progress in the largest
## unit type.
static func get_download_progress_string(p_downloaded_bytes: int, p_body_size: int) -> String:
	var downloaded_bytes_data_block: Dictionary = SarDataStorageUnitUtilities.convert_bytes_to_data_unit_block(p_downloaded_bytes)
	var body_size_data_block: Dictionary = SarDataStorageUnitUtilities.convert_bytes_to_data_unit_block(p_body_size)

	var downloaded_bytes_largest_unit: int = SarDataStorageUnitUtilities.get_largest_unit_type(downloaded_bytes_data_block)
	var body_size_largest_unit: int = SarDataStorageUnitUtilities.get_largest_unit_type(body_size_data_block)

	var downloaded_bytes_string: String = "%s%s" % [SarDataStorageUnitUtilities.get_string_for_unit_data_block(downloaded_bytes_data_block, downloaded_bytes_largest_unit), SarDataStorageUnitUtilities.get_string_for_unit_type(downloaded_bytes_largest_unit)]

	var body_size_string: String = "%s%s" % [SarDataStorageUnitUtilities.get_string_for_unit_data_block(body_size_data_block, body_size_largest_unit), SarDataStorageUnitUtilities.get_string_for_unit_type(body_size_largest_unit)]

	return "%s/%s" % [downloaded_bytes_string, body_size_string]

## The method will schedule an asset to be loaded via the p_request_url
## and the type should be defined by the p_asset_type enum. It will return
## a VSKGameAssetRequest object which can be used to track the loading
## progress for the asset.
func make_request(
	p_request_url: String,
	p_asset_type: AssetType) -> VSKGameAssetRequest:
	
	if not Engine.is_editor_hint():
		var request_obj: VSKGameAssetRequest = null
		var request_type: RequestType = _get_request_type(p_request_url)
		
		request_obj = _get_or_create_request_object_for_type(p_request_url, p_asset_type, request_type)
		
		return request_obj
	else:
		return null

## This method will attempt to cancel all currently in progress
## requests to load an asset at p_request_url.
func attempt_to_cancel_request(p_request_url: String) -> void:
	if _request_objects.has(p_request_url):
		var request_obj: VSKGameAssetRequest = _request_objects[p_request_url]
		if request_obj.request_complete.get_connections().size() <= 1:
			_request_objects.erase(p_request_url)
			if request_obj.request_complete.is_connected(_request_complete):
				request_obj.request_complete.disconnect(_request_complete)
			request_obj.cleanup()
			
## Returns true if p_url is in the allow list for a particular asset type.
func is_in_allow_list(p_url: String, p_asset_type: AssetType) -> bool:
	var allow_list: PackedStringArray
	
	match p_asset_type:
		AssetType.AVATAR:
			allow_list = avatar_allow_list
		AssetType.MAP:
			allow_list = map_allow_list
		AssetType.PROP:
			allow_list = prop_allow_list
		AssetType.GAME_MODE:
			allow_list = game_mode_allow_list
		_:
			return false
	for string: String in allow_list:
		if p_url.match(string):
			return true
			
	if p_url.is_empty():
		push_error("Asset is not in allow list!")
	else:
		push_error("Asset %s is not in allow list!" % p_url)
		
	return false
			
## Returns the path for a particular asset_type corresponding to a particuar
## asset error.
func get_error_path_for_asset_type(p_asset_type: AssetType, p_asset_err: VSKGameAssetRequest.AssetError) -> String:
	match p_asset_type:
		AssetType.AVATAR:
			match p_asset_err:
				VSKGameAssetRequest.AssetError.I_AM_A_TEAPOT:
					return teapot_path
				VSKGameAssetRequest.AssetError.UNAVAILABLE_FOR_LEGAL_REASONS:
					return avatar_forbidden_path
				VSKGameAssetRequest.AssetError.NOT_FOUND:
					return avatar_not_found_path
				VSKGameAssetRequest.AssetError.UNAUTHORIZED:
					return avatar_forbidden_path
				VSKGameAssetRequest.AssetError.FORBIDDEN:
					return avatar_forbidden_path
				VSKGameAssetRequest.AssetError.NOT_IN_ALLOW_LIST:
					return avatar_forbidden_path
				_:
					return avatar_error_path
		AssetType.MAP:
			return ""
		AssetType.PROP:
			return ""
		AssetType.GAME_MODE:
			return ""
		_:
			return ""

## Clears the internal cache for assets.
func clear_cache() -> void:
	var dir: DirAccess = DirAccess.open(get_asset_cache_path())
	if dir != null:
		if SarDirectoryUtilities.delete_dir_and_contents(dir, get_asset_cache_path(), false) != OK:
			push_error("Could not delete all files in cache!")
