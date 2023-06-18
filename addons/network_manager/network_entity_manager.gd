# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# network_entity_manager.gd
# SPDX-License-Identifier: MIT

@tool
extends Node

const mutex_lock_const = preload("res://addons/gd_util/mutex_lock.gd")
var _mutex: Mutex = Mutex.new()

# List of all the packed scenes which can be transferred over the network
# via small spawn commands
var networked_scenes: Array = []

# The maximum amount of entities which can be active in a scene at once
var max_networked_entities: int = 4096  # Default

###############
# Network ids #
###############

# Invalid network instance id
const NULL_NETWORK_INSTANCE_ID = 0
# The first instance id assigned
const FIRST_NETWORK_INSTANCE_ID = 1
# The last instance id which can be assigned
# before flipping over
const LAST_NETWORK_INSTANCE_ID = 4294967295

var network_manager: Object


func _init(p_network_manager):
	network_manager = p_network_manager


# The next network instance id attempted to be assigned when requested
var next_network_instance_id: int = FIRST_NETWORK_INSTANCE_ID
# Map of all currently active instance IDs
var network_instance_ids: Dictionary = {}


# Returns the corresponding NetworkIdentity node for the id integer
func _get_network_identity_for_instance_id_unsafe(p_network_instance_id: int) -> Node:
	if network_instance_ids.has(p_network_instance_id):
		return network_instance_ids[p_network_instance_id]

	return null


# Writes the index id for the p_entity's base scene as defined in the list
# of p_networked_scenes to the p_writer. The index byte length is determined
# by the number of network scenes. Returns the p_writer
static func write_entity_scene_id(p_entity: Object, p_networked_scenes: Array, p_writer: Object) -> Object:
	var network_identity_node = p_entity.network_identity_node
	if p_networked_scenes.size() > 0xff:
		p_writer.put_u16(network_identity_node.network_scene_id)
	elif p_networked_scenes.size() > 0xffff:
		p_writer.put_u32(network_identity_node.network_scene_id)
	elif p_networked_scenes.size() > 0xffffffff:
		p_writer.put_u64(network_identity_node.network_scene_id)
	else:
		p_writer.put_u8(network_identity_node.network_scene_id)

	return p_writer


# Reads from p_reader the index id for an entity's base scene type as defined
# in the list of p_networked_scenes. The index byte length read is determind
# by the number of network scenes. Returns the scene id.
static func read_entity_scene_id(p_reader: Object, p_networked_scenes: Array) -> int:
	if p_networked_scenes.size() > 0xff:
		return p_reader.get_u16()
	elif p_networked_scenes.size() > 0xffff:
		return p_reader.get_u32()
	elif p_networked_scenes.size() > 0xffffffff:
		return p_reader.get_u64()
	else:
		return p_reader.get_u8()


# Writes the network master id for p_entity to p_writer. Returns the p_writer
static func write_entity_multiplayer_authority(p_entity: Object, p_writer: Object) -> Object:
	p_writer.put_u32(p_entity.get_multiplayer_authority())

	return p_writer


# Reads the network master id for an entity from p_reader.
# Returns the network master id
static func read_entity_multiplayer_authority(p_reader: Object) -> int:
	return p_reader.get_u32()


# Writes the instance id for p_entity to p_writer. Returns the p_writer
static func write_entity_instance_id_for_entity(p_entity: Object, p_writer: Object) -> Object:
	p_writer.put_u32(p_entity.network_identity_node.network_instance_id)

	return p_writer


# Writes the instance id for p_entity to p_writer. Returns the p_writer
static func write_entity_instance_id(p_entity_id: int, p_writer: Object) -> Object:
	p_writer.put_u32(p_entity_id)

	return p_writer


# Reads the instance id for an entity from p_reader.
# Returns the instance id
static func read_entity_instance_id(p_reader: Object) -> int:
	return p_reader.get_u32()


# Clears all active instance ids
func reset_server_instances() -> void:
	var _mutex_lock: RefCounted = mutex_lock_const.new(_mutex)

	network_instance_ids = {}
	next_network_instance_id = FIRST_NETWORK_INSTANCE_ID  # Reset the network id counter


# Requests a new instance id. It will flip to FIRST_NETWORK_INSTANCE_ID
# if it reaches the LAST_NETWORK_INSTANCE_ID, and if one is already in
# use, it will loop until it finds an unused one. Returns an instance ID
func get_next_network_id() -> int:
	var _mutex_lock: RefCounted = mutex_lock_const.new(_mutex)

	var network_instance_id: int = next_network_instance_id
	next_network_instance_id += 1
	if next_network_instance_id >= LAST_NETWORK_INSTANCE_ID:
		NetworkLogger.printl("Maximum network instantiate ids used. Reverting to first")
		next_network_instance_id = FIRST_NETWORK_INSTANCE_ID

	# If the instance id is already in use, keep iterating until
	# we find an unused one
	while network_instance_ids.has(network_instance_id):
		network_instance_id = next_network_instance_id
		next_network_instance_id += 1
		if next_network_instance_id >= LAST_NETWORK_INSTANCE_ID:
			NetworkLogger.printl("Maximum network instantiate ids used. Reverting to first")
			next_network_instance_id = FIRST_NETWORK_INSTANCE_ID

	return network_instance_id


# Registers an entity's network identity in the network_instance_id map
# TODO: add more graceful error handling for exceeding maximum number of
# entities
func register_network_instance_id(p_network_instance_id: int, p_network_identity: Node) -> void:
	var _mutex_lock: RefCounted = mutex_lock_const.new(_mutex)

	NetworkLogger.printl("Attempting to register network instance_id {network_instance_id}".format({"network_instance_id": str(p_network_instance_id)}))

	if network_instance_ids.size() > max_networked_entities:
		NetworkLogger.error("EXCEEDED MAXIMUM ALLOWED INSTANCE IDS!")
		return

	if !network_instance_ids.has(p_network_instance_id):
		network_instance_ids[p_network_instance_id] = p_network_identity
		network_manager.emit_entity_network_id_registered(p_network_instance_id)
	else:
		printerr("Attempted to register duplicate network instance_id")


# Unregisters a network_instance from the network_instance_id map
func unregister_network_instance_id(p_network_instance_id: int) -> void:
	var _mutex_lock: RefCounted = mutex_lock_const.new(_mutex)

	NetworkLogger.printl("Attempting to unregister network instance_id {network_instance_id}".format({"network_instance_id": str(p_network_instance_id)}))

	if !network_instance_ids.erase(p_network_instance_id):
		NetworkLogger.error("Could not unregister network instantiate id: {network_instance_id}".format({"network_instance_id": str(p_network_instance_id)}))
	network_manager.emit_entity_network_id_unregistered(p_network_instance_id)


# Returns the network identity node for a given network instance id
func get_network_identity_for_instance_id(p_network_instance_id: int) -> Node:
	var _mutex_lock: RefCounted = mutex_lock_const.new(_mutex)

	return _get_network_identity_for_instance_id_unsafe(p_network_instance_id)


# Returns the network identity node for a given network instance id
func get_network_instance_for_instance_id(p_network_instance_id: int) -> Node:
	var _mutex_lock: RefCounted = mutex_lock_const.new(_mutex)

	var identity_node: Node = _get_network_identity_for_instance_id_unsafe(p_network_instance_id)
	if identity_node:
		return identity_node.get_entity_node()

	return null


func get_network_scene_paths() -> Array:
	return networked_scenes


func _ready() -> void:
	if !ProjectSettings.has_setting("network/config/networked_scenes"):
		ProjectSettings.set_setting("network/config/networked_scenes", PackedStringArray())

	var networked_objects_property_info: Dictionary = {"name": "network/config/networked_scenes", "type": TYPE_PACKED_STRING_ARRAY, "hint": PROPERTY_HINT_FILE, "hint_string": ""}

	ProjectSettings.add_property_info(networked_objects_property_info)

	if !Engine.is_editor_hint():
		var network_scenes_config = ProjectSettings.get_setting("network/config/networked_scenes")
		if typeof(network_scenes_config) != TYPE_PACKED_STRING_ARRAY:
			networked_scenes = Array()
		else:
			networked_scenes = Array(network_scenes_config)

		max_networked_entities = ProjectSettings.get_setting("network/config/max_networked_entities")

	if !ProjectSettings.has_setting("network/config/max_networked_entities"):
		ProjectSettings.set_setting("network/config/max_networked_entities", max_networked_entities)
