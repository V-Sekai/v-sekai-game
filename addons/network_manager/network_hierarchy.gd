# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# network_hierarchy.gd
# SPDX-License-Identifier: MIT

@tool
class_name NetworkHierarchy extends NetworkLogic

const network_entity_manager_const = preload("res://addons/network_manager/network_entity_manager.gd")

var parent_id: int = network_entity_manager_const.NULL_NETWORK_INSTANCE_ID
var attachment_id: int = 0

@export var sync_parent: bool = false
@export var sync_attachment: bool = false


static func encode_parent_id(p_writer: Object, p_id: int) -> Object:
	p_writer.put_u32(p_id)

	return p_writer


static func decode_parent_id(p_reader: Object) -> int:
	return p_reader.get_u32()


static func encode_attachment_id(p_writer: Object, p_id: int) -> Object:
	p_writer.put_u8(p_id)

	return p_writer


static func decode_attachment_id(p_reader: Object) -> int:
	return p_reader.get_u8()


static func write_entity_parent_id(p_writer: Object, p_entity_hierarchy_node: Node) -> Object:
	if p_entity_hierarchy_node and p_entity_hierarchy_node.get_entity_parent():
		p_writer = encode_parent_id(p_writer, p_entity_hierarchy_node.get_entity_parent().network_identity_node.network_instance_id)
	else:
		p_writer.put_u32(NetworkManager.network_entity_manager.NULL_NETWORK_INSTANCE_ID)

	return p_writer


static func write_entity_attachment_id(p_writer: Object, p_entity_hierarchy_node: Node) -> Object:
	if p_entity_hierarchy_node:
		p_writer = encode_attachment_id(p_writer, p_entity_hierarchy_node.cached_entity_attachment_id)
	else:
		p_writer = encode_attachment_id(p_writer, 0)
	return p_writer


static func read_entity_parent_id(p_reader: Object) -> int:
	return decode_parent_id(p_reader)


static func read_entity_attachment_id(p_reader: Object) -> int:
	return decode_attachment_id(p_reader)


func serialize_hierarchy(p_writer: Object) -> Object:
	if sync_parent:
		p_writer = write_entity_parent_id(p_writer, entity_node.hierarchy_component_node)
		if sync_attachment:
			if entity_node.hierarchy_component_node.get_entity_parent():
				p_writer = write_entity_attachment_id(p_writer, entity_node.hierarchy_component_node)
	return p_writer


func on_serialize(p_writer: Object, p_initial_state: bool) -> Object:
	if p_initial_state:
		pass

	# Hierarchy
	p_writer = serialize_hierarchy(p_writer)

	return p_writer


func deserialize_hierarchy(p_reader: Object, p_initial_state: bool) -> Object:
	if sync_parent:
		parent_id = read_entity_parent_id(p_reader)
		if sync_attachment:
			if parent_id != network_entity_manager_const.NULL_NETWORK_INSTANCE_ID:
				attachment_id = read_entity_attachment_id(p_reader)

		if !p_initial_state:
			process_parenting()

	return p_reader


func on_deserialize(p_reader: Object, p_initial_state: bool) -> Object:
	received_data = true

	# Hierarchy
	p_reader = deserialize_hierarchy(p_reader, p_initial_state)

	return p_reader


func process_parenting():
	if entity_node:
		get_entity_node().hierarchy_component_node.parent_entity_is_valid = true
		if parent_id != network_entity_manager_const.NULL_NETWORK_INSTANCE_ID:
			if NetworkManager.network_entity_manager.network_instance_ids.has(parent_id):
				var network_identity: Node = NetworkManager.network_entity_manager.get_network_identity_for_instance_id(parent_id)
				if network_identity:
					var parent_instance: Node = network_identity.get_entity_node()
					if entity_node.hierarchy_component_node:
						entity_node.hierarchy_component_node.request_reparent_entity(parent_instance.get_entity_ref(), attachment_id)
			else:
				get_entity_node().hierarchy_component_node.parent_entity_is_valid = false
				if entity_node.hierarchy_component_node:
					entity_node.hierarchy_component_node.request_reparent_entity(null, attachment_id)
		else:
			get_entity_node().hierarchy_component_node.parent_entity_is_valid = true
			if entity_node.hierarchy_component_node:
				entity_node.hierarchy_component_node.request_reparent_entity(null, attachment_id)


func _entity_ready() -> void:
	super._entity_ready()
	if not received_data:
		return
	if not is_multiplayer_authority():
		process_parenting()
	received_data = false
