# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# network_identity.gd
# SPDX-License-Identifier: MIT

@tool
class_name NetworkIdentity extends "res://addons/entity_manager/component_node.gd"

const network_manager_const = preload("res://addons/network_manager/network_manager.gd")
const network_entity_manager_const = preload("res://addons/network_manager/network_entity_manager.gd")

##
## Network Instance ID
##
var network_instance_id: int = network_entity_manager_const.NULL_NETWORK_INSTANCE_ID:
	set = set_network_instance_id

var network_scene_id: int = -1:
	set = set_network_scene_id


func set_network_instance_id(p_id: int) -> void:
	if !Engine.is_editor_hint():
		if network_instance_id == network_entity_manager_const.NULL_NETWORK_INSTANCE_ID:
			network_instance_id = p_id
			NetworkManager.network_entity_manager.register_network_instance_id(network_instance_id, self)
		else:
			NetworkLogger.error("network_instance_id has already been assigned")


func set_network_scene_id(p_id: int) -> void:
	if !Engine.is_editor_hint():
		if network_scene_id == -1:
			network_scene_id = p_id
		else:
			NetworkLogger.error("network_scene_id has already been assigned")


func on_predelete() -> void:
	if !Engine.is_editor_hint():
		if network_instance_id != network_entity_manager_const.NULL_NETWORK_INSTANCE_ID:
			if NetworkManager and NetworkManager.network_entity_manager != null:
				NetworkManager.network_entity_manager.unregister_network_instance_id(network_instance_id)


func get_state(p_writer, p_initial_state: bool):
	p_writer = entity_node.network_logic_node.on_serialize(p_writer, p_initial_state)
	return p_writer


func update_state(p_reader, p_initial_state: bool):
	p_reader = entity_node.network_logic_node.on_deserialize(p_reader, p_initial_state)
	return p_reader


func get_network_root_node() -> Node:
	return NetworkManager.get_entity_root_node()


func update_name() -> void:
	# Make sure this entity is correctly named
	if NetworkManager.is_server():
		get_entity_node().set_name("NetEntity_{instance_id}".format({"instance_id": str(network_instance_id)}))


func _entity_ready() -> void:
	if !Engine.is_editor_hint():
		entity_node = get_entity_node()

		if NetworkManager.is_server():
			set_network_instance_id(NetworkManager.network_entity_manager.get_next_network_id())
		else:
			# This is a bad approach, we should be purging entities for the clients
			# BEFORE they are instantiated, but this will do for now...
			if !str(entity_node.get_name()).begins_with("NetEntity"):
				print("Client deleting entity node %s" % entity_node.get_name())
				entity_node.queue_free()
				return

		set_network_scene_id(NetworkManager.network_replication_manager.get_network_scene_id_from_path(entity_node.scene_file_path))

		entity_node.add_to_group("NetworkedEntities")


func _threaded_instance_setup(p_instance_id: int, p_network_reader: RefCounted) -> void:
	set_network_instance_id(p_instance_id)
	p_network_reader = update_state(p_network_reader, true)


func _notification(what):
	match what:
		NOTIFICATION_PREDELETE:
			on_predelete()
