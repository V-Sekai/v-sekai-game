@tool
extends "res://addons/vsk_manager/vsk_user_content_manager.gd"

const vsk_map_definition_const = preload("res://addons/vsk_map/vsk_map_definition.gd")
const vsk_map_definition_runtime_const = preload("res://addons/vsk_map/vsk_map_definition_runtime.gd")
const vsk_map_entity_instance_record_const = preload("res://addons/vsk_map/vsk_map_entity_instance_record.gd")
const runtime_entity_const = preload("res://addons/entity_manager/runtime_entity.gd")
const network_constants_const = preload("res://addons/network_manager/network_constants.gd")

var default_map_path: String = ""

var _loading_stage_count: int = 0

var _current_map_path: String = ""
var _current_map_packed: PackedScene = null

var _instance_map_mutex: Mutex = Mutex.new()

const RESPAWN_HEIGHT = -100
const mutex_lock_const = preload("res://addons/gd_util/mutex_lock.gd")

var _instanced_map: Node = null
var current_map: Node = null
var gameroot: Node = null

signal map_download_started
signal map_load_callback(p_callback_id)
signal map_load_update(p_stage, p_stage_count)

const validator_map_const = preload("res://addons/vsk_importer_exporter/vsk_map_validator.gd")
var validator_map = validator_map_const.new()


func _user_content_load_done(p_url: String, p_err: int, p_packed_scene: PackedScene, p_skip_validation: bool) -> void:
	if p_url == _current_map_path:
		var validated_packed_scene: PackedScene = null

		if p_packed_scene:
			if !p_skip_validation:
				var result_dictionary: Dictionary = vsk_importer_const.sanitise_packed_scene_for_map(p_packed_scene)
				var validation_result: Dictionary = result_dictionary["result"]
				validated_packed_scene = result_dictionary["packed_scene"]

				super.log_validation_result(p_url, "Map", validation_result)
			else:
				validated_packed_scene = p_packed_scene

		match p_err:
			VSKAssetManager.ASSET_OK:
				_current_map_packed = validated_packed_scene
				if _current_map_packed:
					map_load_callback.emit(VSKAssetManager.ASSET_OK, {})
				else:
					map_load_callback.emit(VSKAssetManager.ASSET_FAILED_VALIDATION_CHECK, {})
			_:
				map_load_callback.emit(p_err, {})


func _user_content_asset_request_started(p_url: String) -> void:
	if p_url == _current_map_path:
		map_download_started.emit()


func _set_loading_stage_count(p_url: String, p_stage_count: int):
	if p_url == _current_map_path:
		_loading_stage_count = p_stage_count

		map_load_update.emit(0, _loading_stage_count)


func _set_loading_stage(p_url: String, p_stage: int):
	if p_url == _current_map_path:
		LogManager.printl("Loading map {stage}/{stage_count}".format({"stage": str(p_stage), "stage_count": str(_loading_stage_count)}))

		map_load_update.emit(p_stage, _loading_stage_count)


func _set_current_map_unsafe(p_map_instance: Node) -> void:
	LogManager.printl("Setting current map...")
	gameroot.add_child(p_map_instance, true)
	current_map = p_map_instance
	LogManager.printl("Current map set!")


func _unload_current_map_unsafe() -> void:
	LogManager.printl("Unloading current map...")

	_set_instanced_map(null)

	if current_map:
		current_map.queue_free()
		current_map = null


func unload_current_map() -> void:
	call_deferred("_unload_current_map_unsafe")


func set_current_map(p_map_instance: Node) -> void:
	call_deferred("_set_current_map_unsafe", p_map_instance)


func _set_instanced_map(p_map: Node) -> void:
	var _mutex_lock = mutex_lock_const.new(_instance_map_mutex)
	LogManager.printl("Assigning instanced map...")
	_instanced_map = p_map
	if p_map:
		LogManager.printl("Instanced map assigned!")
	else:
		LogManager.printl("Map cleared!")


func instance_map(_p_strip_all_entities: bool) -> Node:
	LogManager.printl("Instance map...")
	# Destroy old current scene
	unload_current_map()

	if _current_map_packed:
		# Add new current scene
		LogManager.printl("Instancing map...")
		var map_instance: Node = _current_map_packed.instantiate()

		if map_instance.get_script() != vsk_map_definition_const and map_instance.get_script() != vsk_map_definition_runtime_const:
			LogManager.error("Map does not have a map definition script at root!")
			map_instance.queue_free()

			return null
		_set_instanced_map(map_instance)
		LogManager.printl("Map instanced!")
		return map_instance

	return null


static func instance_embedded_map_entities(p_map_instance: Node, p_invalid_scene_paths: PackedStringArray) -> Node:
	assert(p_map_instance)
	assert(p_map_instance is vsk_map_definition_runtime_const)

	for i in range(0, p_map_instance.entity_instance_list.size()):
		var map_entity_instance_info = p_map_instance.entity_instance_list[i]
		if map_entity_instance_info is vsk_map_entity_instance_record_const:
			if map_entity_instance_info.parent_id != -1:
				push_warning("Map entity id %s: parented entities are not currently supported" % str(i))
				continue

			if p_map_instance.entity_instance_properties_list.size() <= map_entity_instance_info.properties_id:
				push_warning("Map entity id %s: invalid property info" % str(i))
				continue

			var properties: Dictionary = p_map_instance.entity_instance_properties_list[map_entity_instance_info.properties_id]

			var scene_path: String = NetworkManager.network_replication_manager.get_scene_path_for_scene_id(map_entity_instance_info.scene_id)
			if p_invalid_scene_paths.has(scene_path):
				push_warning("Map entity id %s: invalid entity '%s' embedded in map data" % [str(i), scene_path])
				continue

			if not scene_path.is_empty():
				var packed_scene: PackedScene = NetworkManager.network_replication_manager.get_packed_scene_for_path(scene_path)
				assert(packed_scene)

				var map_entity_instance: Node = packed_scene.instantiate()
				var logic_node: Node = map_entity_instance.get_node(map_entity_instance.simulation_logic_node_path)
				assert(logic_node)

				var logic_node_property_list = runtime_entity_const.get_custom_logic_node_properties(logic_node)

				var logic_node_property_names: Array = []
				for property in logic_node_property_list:
					logic_node_property_names.push_back(property.name)

				for key in properties.keys():
					if logic_node_property_names.has(key):
						logic_node.set(key, properties[key])

				p_map_instance.add_child(map_entity_instance, true)
				map_entity_instance.transform = map_entity_instance_info.transform
			else:
				push_warning("Map entity id %s: no scene path could be found for entity" % str(i))
				continue

	return p_map_instance


func destroy_map() -> void:
	# Destroy old current scene and cancel any in progress map loads
	unload_current_map()


func request_map_load(p_map_path: String, p_bypass_whitelist: bool, p_skip_validation: bool) -> void:
	_current_map_path = p_map_path

	await (
		super
		. request_user_content_load(
			p_map_path,
			VSKAssetManager.user_content_type.USER_CONTENT_MAP,
			p_bypass_whitelist,
			p_skip_validation,
			validator_map.valid_external_path_whitelist,
			validator_map.valid_resource_whitelist
		)
	)


func cancel_map_load() -> void:
	super.request_user_content_cancel(get_current_map_path())
	_current_map_path = ""


func get_current_map_path() -> String:
	return _current_map_path


func get_request_data_progress() -> Dictionary:
	if _current_map_path:
		var request_data_progress: Dictionary = VSKAssetManager.get_request_data_progress(_current_map_path)
		return request_data_progress

	return {}


func get_map_id_for_resource(p_resource: Resource) -> int:
	var _mutex_lock = mutex_lock_const.new(_instance_map_mutex)

	if _instanced_map:
		return _instanced_map.map_resources.find(p_resource)

	return -1


func get_resource_for_map_id(p_id: int) -> Resource:
	LogManager.printl("get_resource_for_map_id %s" % str(p_id))
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
		LogManager.error("Could not connect _user_content_load_done")
	if connect("user_content_background_load_stage", self._set_loading_stage) != OK:
		LogManager.error("Could not connect user_content_background_load_stage")
	if connect("user_content_background_load_stage_count", self._set_loading_stage_count) != OK:
		LogManager.error("Could not connect user_content_background_load_stage_count")


func apply_project_settings() -> void:
	if Engine.is_editor_hint():
		if !ProjectSettings.has_setting("network/config/default_map_path"):
			ProjectSettings.set_setting("network/config/default_map_path", default_map_path)

		if ProjectSettings.save() != OK:
			printerr("Could not save project settings!")


func get_project_settings() -> void:
	default_map_path = ProjectSettings.get_setting("network/config/default_map_path")


func _ready() -> void:
	apply_project_settings()
	get_project_settings()
