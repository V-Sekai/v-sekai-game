# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_map_manager.gd
# SPDX-License-Identifier: MIT

@tool
extends "res://addons/vsk_manager/vsk_user_content_manager.gd"

const vsk_map_definition_const = preload("res://addons/vsk_map/vsk_map_definition.gd")
const vsk_map_definition_runtime_const = preload(
	"res://addons/vsk_map/vsk_map_definition_runtime.gd"
)
const vsk_map_entity_instance_record_const = preload(
	"res://addons/vsk_map/vsk_map_entity_instance_record.gd"
)

const network_constants_const = preload("res://addons/network_manager/network_constants.gd")

var default_map_path: String = ""

var _loading_stage_count: int = 0

##
## Path to the map we are currently attempting to load.
##
var _pending_map_path: String = ""
##
## Path to the map we have loaded.
##
var _loaded_map_path: String = ""
##
## Path to the map we have instanced.
##
var _instanced_map_path: String = ""
##
## Path to the map we consider to be the 'current' map.
##
var _current_map_path: String = ""

var _current_map_packed: PackedScene = null

var _instance_map_mutex: Mutex = Mutex.new()

const RESPAWN_HEIGHT = -100
const mutex_lock_const = preload("res://addons/gd_util/mutex_lock.gd")

var _instanced_map: Node = null
var _current_map: Node = null
var _gameroot: Node = null

signal map_download_started
signal map_load_callback(p_callback_id)
signal map_load_update(p_stage, p_stage_count)

const validator_map_const = preload("res://addons/vsk_importer_exporter/vsk_map_validator.gd")
var validator_map = validator_map_const.new()


func _user_content_load_done(
	p_url: String, p_err: int, p_packed_scene: PackedScene, p_skip_validation: bool
) -> void:
	if p_url == _pending_map_path:
		var _mutex_lock: mutex_lock_const = mutex_lock_const.new(_instance_map_mutex)

		var validated_packed_scene: PackedScene = null

		if p_packed_scene:
			if !p_skip_validation:
				var result_dictionary: Dictionary = (
					vsk_importer_const.sanitise_packed_scene_for_map(p_packed_scene)
				)
				var validation_result: Dictionary = result_dictionary["result"]
				validated_packed_scene = result_dictionary["packed_scene"]

				super.log_validation_result(p_url, "Map", validation_result)
			else:
				validated_packed_scene = p_packed_scene

		match p_err:
			VSKAssetManager.ASSET_OK:
				_loaded_map_path = _pending_map_path
				_current_map_packed = validated_packed_scene
				if _current_map_packed:
					map_load_callback.emit(VSKAssetManager.ASSET_OK, {})
				else:
					map_load_callback.emit(VSKAssetManager.ASSET_FAILED_VALIDATION_CHECK, {})
			_:
				map_load_callback.emit(p_err, {})


func _user_content_asset_request_started(p_url: String) -> void:
	if p_url == _pending_map_path:
		map_download_started.emit()


func _set_loading_stage_count(p_url: String, p_stage_count: int):
	if p_url == _pending_map_path:
		_loading_stage_count = p_stage_count

		map_load_update.emit(0, _loading_stage_count)


func _set_loading_stage(p_url: String, p_stage: int):
	if p_url == _pending_map_path:
		print(
			"Loading map {stage}/{stage_count}".format(
				{"stage": str(p_stage), "stage_count": str(_loading_stage_count)}
			)
		)

		map_load_update.emit(p_stage, _loading_stage_count)


func _set_current_map_unsafe(p_path: String, p_map_instance: Node) -> void:
	print("Setting current map...")

	_gameroot.add_child(p_map_instance, true)
	_current_map_path = p_path
	_current_map = p_map_instance

	print("Current map set!")


func _unload_current_map_unsafe() -> void:
	print("Unloading current map...")

	_set_instanced_map(null)

	if _current_map:
		_current_map.queue_free()
		_current_map = null
		_current_map_path = ""


func unload_current_map() -> void:
	call_thread_safe("_unload_current_map_unsafe")


func set_current_map(p_path: String, p_map_instance: Node) -> void:
	call_thread_safe("_set_current_map_unsafe", p_path, p_map_instance)


func _set_instanced_map(p_map: Node) -> void:
	var _mutex_lock: mutex_lock_const = mutex_lock_const.new(_instance_map_mutex)
	print("Assigning instanced map...")
	_instanced_map = p_map
	if p_map:
		print("Instanced map assigned!")
	else:
		print("Map cleared!")


func instance_map(_p_strip_all_entities: bool) -> Dictionary:
	print("Instance map...")

	var _mutex_lock: mutex_lock_const = mutex_lock_const.new(_instance_map_mutex)

	# Destroy old current scene
	if _instanced_map:
		_instanced_map.queue_free()

	if _current_map_packed:
		# Add new current scene
		print("Instancing map...")

		# It should be okay to disable safety checks for this
		# thread since all operations on the instantiated node
		# occur outside the scene tree.
		Thread.set_thread_safety_checks_enabled(false)
		var map_instance: Node = _current_map_packed.instantiate()
		Thread.set_thread_safety_checks_enabled(true)

		if (
			map_instance.get_script() != vsk_map_definition_const
			and map_instance.get_script() != vsk_map_definition_runtime_const
		):
			push_error("Map does not have a map definition script at root!")
			map_instance.queue_free()
			return {}

		_set_instanced_map(map_instance)
		print("Map instanced!")

		_instanced_map_path = _loaded_map_path

		return {"node": map_instance, "path": _instanced_map_path}

	return {}


static func instance_embedded_map_entities(
	p_map_instance: Node, p_invalid_scene_paths: PackedStringArray
) -> Node:
	if not p_map_instance:
		push_error("Could not find 'p_map_instance' at vsk_map_manager")
		return
	if not (p_map_instance is vsk_map_definition_runtime_const):
		push_error("'p_map_instance' is not a valid map instance")
		return

	for i in range(0, p_map_instance.entity_instance_list.size()):
		var map_entity_instance_info = p_map_instance.entity_instance_list[i]
		if map_entity_instance_info is vsk_map_entity_instance_record_const:
			if map_entity_instance_info.parent_id != -1:
				push_warning(
					"Map entity id %s: parented entities are not currently supported" % str(i)
				)
				continue

			if (
				p_map_instance.entity_instance_properties_list.size()
				<= map_entity_instance_info.properties_id
			):
				push_warning("Map entity id %s: invalid property info" % str(i))
				continue

			var _properties: Dictionary = p_map_instance.entity_instance_properties_list[
				map_entity_instance_info.properties_id
			]

			var scene_path: String = (
				NetworkManager
				. network_replication_manager
				. get_scene_path_for_scene_id(map_entity_instance_info.scene_id)
			)
			if p_invalid_scene_paths.has(scene_path):
				push_warning(
					(
						"Map entity id %s: invalid entity '%s' embedded in map data"
						% [str(i), scene_path]
					)
				)
				continue

			if not scene_path.is_empty():
				var packed_scene: PackedScene = (
					NetworkManager.network_replication_manager.get_packed_scene_for_path(scene_path)
				)
				if not packed_scene:
					continue

				var map_entity_instance: Node = packed_scene.instantiate()
				var logic_node: Node = map_entity_instance.get_node_or_null(
					map_entity_instance.simulation_logic_node_path
				)
				if not logic_node:
					continue

				p_map_instance.add_child(map_entity_instance, true)
				map_entity_instance.transform = map_entity_instance_info.transform
			else:
				push_warning("Map entity id %s: no scene path could be found for entity" % str(i))
				continue

	return p_map_instance


func destroy_map() -> void:
	# Destroy old current scene and cancel any in progress map loads
	unload_current_map()


func request_map_load(
	p_map_path: String, p_bypass_whitelist: bool, p_skip_validation: bool
) -> void:
	_pending_map_path = p_map_path

	await (super.request_user_content_load(
		p_map_path,
		VSKAssetManager.user_content_type.USER_CONTENT_MAP,
		p_bypass_whitelist,
		p_skip_validation,
		validator_map.valid_external_path_whitelist,
		validator_map.valid_resource_whitelist
	))


func cancel_map_load() -> void:
	super.request_user_content_cancel(get_pending_map_path())
	_pending_map_path = ""


func get_pending_map_path() -> String:
	return _pending_map_path


func get_loaded_map_path() -> String:
	return _loaded_map_path


func get_instanced_map_path() -> String:
	return _instanced_map_path


func get_current_map_path() -> String:
	return _current_map_path


func get_request_data_progress() -> Dictionary:
	if _pending_map_path:
		var request_data_progress: Dictionary = VSKAssetManager.get_request_data_progress(
			_pending_map_path
		)
		return request_data_progress

	return {}


func get_map_id_for_resource(p_resource: Resource) -> int:
	var _mutex_lock: mutex_lock_const = mutex_lock_const.new(_instance_map_mutex)

	if _instanced_map:
		return _instanced_map.map_resources.find(p_resource)

	return -1


func get_resource_for_map_id(p_id: int) -> Resource:
	print("get_resource_for_map_id %s" % str(p_id))
	if _instanced_map:
		if p_id >= 0 and p_id < _instanced_map.map_resources.size():
			return _instanced_map.map_resources[p_id]

	return null


func get_default_map_path() -> String:
	return default_map_path


func setup() -> void:
	VSKResourceManager.assign_get_map_id_for_resource_function(self, "get_map_id_for_resource")
	VSKResourceManager.assign_get_resource_for_map_id_function(self, "get_resource_for_map_id")

	if connect("user_content_load_done", self._user_content_load_done) != OK:
		push_error("Could not connect _user_content_load_done")
		return
	if connect("user_content_background_load_stage", self._set_loading_stage) != OK:
		push_error("Could not connect user_content_background_load_stage")
		return
	if connect("user_content_background_load_stage_count", self._set_loading_stage_count) != OK:
		push_error("Could not connect user_content_background_load_stage_count")
		return


func apply_project_settings() -> void:
	if Engine.is_editor_hint():
		if !ProjectSettings.has_setting("network/config/default_map_path"):
			ProjectSettings.set_setting("network/config/default_map_path", default_map_path)

		if ProjectSettings.save() != OK:
			push_error("Could not save project settings!")


func get_project_settings() -> void:
	default_map_path = ProjectSettings.get_setting("network/config/default_map_path")


func setup_manager(p_gameroot: Node) -> void:
	_gameroot = p_gameroot


func _ready() -> void:
	apply_project_settings()
	get_project_settings()
