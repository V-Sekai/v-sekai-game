# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# network_rpc_manager.gd
# SPDX-License-Identifier: MIT

@tool
extends Node

const ref_pool_const = preload("res://addons/gd_util/ref_pool.gd")
const connection_util_const = preload("res://addons/gd_util/connection_util.gd")

const network_constants_const = preload("network_constants.gd")
const network_writer_const = preload("network_writer.gd")

const MAXIMUM_RPC_PACKET_SIZE = 1024

var network_manager: Object


func _init(p_network_manager):
	network_manager = p_network_manager


var dummy_rpc_reliable_writer = network_writer_const.new(MAXIMUM_RPC_PACKET_SIZE)  # For debugging purposes
var rpc_reliable_writers = {}
var dummy_rpc_unreliable_writer = network_writer_const.new(MAXIMUM_RPC_PACKET_SIZE)  # For debugging purposes
var rpc_unreliable_writers = {}

var signal_table: Array = [
	{"singleton": "NetworkManager", "signal": "network_process", "method": "_network_manager_process"},
	{"singleton": "NetworkManager", "signal": "game_hosted", "method": "_game_hosted"},
	{"singleton": "NetworkManager", "signal": "connection_succeeded", "method": "_connected_to_server"},
	{"singleton": "NetworkManager", "signal": "server_peer_connected", "method": "_server_peer_connected"},
	{"singleton": "NetworkManager", "signal": "server_peer_disconnected", "method": "_server_peer_disconnected"},
]

var pending_rpc_reliable_calls: Array = []
var pending_rpc_unreliable_calls: Array = []
var pending_rset_reliable_calls: Array = []
var pending_rset_unreliable_calls: Array = []

##
##
##


func queue_reliable_rpc_call(p_entity: Node, p_target_id: int, p_method_id: int, p_args: Array):
	pending_rpc_reliable_calls.push_back({"entity": p_entity, "target_id": p_target_id, "method_id": p_method_id, "args": p_args})


func queue_reliable_rset_call(p_entity: Node, p_target_id: int, p_property_id: int, p_value):
	pending_rset_reliable_calls.push_back({"entity": p_entity, "target_id": p_target_id, "property_id": p_property_id, "value": p_value})


func queue_unreliable_rpc_call(p_entity: Node, p_target_id: int, p_method_id: int, p_args: Array):
	pending_rpc_unreliable_calls.push_back({"entity": p_entity, "target_id": p_target_id, "method_id": p_method_id, "args": p_args})


func queue_unreliable_rset_call(p_entity: Node, p_target_id: int, p_property_id: int, p_value):
	pending_rset_unreliable_calls.push_back({"entity": p_entity, "target_id": p_target_id, "property_id": p_property_id, "value": p_value})


func get_entity_root_node() -> Node:
	return network_manager.get_entity_root_node()


func write_entity_rpc_command(p_sender_id: int, p_call: Dictionary, p_network_writer: Object) -> Object:
	var network_entity_manager: Node = network_manager.network_entity_manager

	if !network_manager.is_relay():
		if network_manager.is_server():
			p_network_writer.put_32(p_sender_id)
		else:
			p_network_writer.put_32(p_call["target_id"])

	p_network_writer = network_entity_manager.write_entity_instance_id_for_entity(p_call["entity"], p_network_writer)

	p_network_writer.put_16(p_call["method_id"])
	p_network_writer.put_8(p_call["args"].size())
	for arg in p_call["args"]:
		p_network_writer.put_var(arg)

	return p_network_writer


func write_entity_rset_command(p_sender_id: int, p_call: Dictionary, p_network_writer: Object) -> Object:
	var network_entity_manager: Node = network_manager.network_entity_manager

	if !network_manager.is_relay():
		if network_manager.is_server():
			p_network_writer.put_32(p_sender_id)
		else:
			p_network_writer.put_32(p_call["target_id"])

	p_network_writer = network_entity_manager.write_entity_instance_id_for_entity(p_call.entity, p_network_writer)

	p_network_writer.put_16(p_call["method_id"])
	p_network_writer.put_var(p_call["value"])

	return p_network_writer


func create_rpc_command(p_sender_id: int, p_command: int, p_rpc_call: Dictionary) -> Object:
	var network_writer: Object = network_manager.network_entity_command_writer_cache
	network_writer.seek(0)

	network_writer.put_u8(p_command)
	match p_command:
		network_constants_const.RELIABLE_ENTITY_RPC_COMMAND:
			network_writer = write_entity_rpc_command(p_sender_id, p_rpc_call, network_writer)
		network_constants_const.UNRELIABLE_ENTITY_RPC_COMMAND:
			network_writer = write_entity_rpc_command(p_sender_id, p_rpc_call, network_writer)
		network_constants_const.RELIABLE_ENTITY_RPC_COMMAND:
			network_writer = write_entity_rset_command(p_sender_id, p_rpc_call, network_writer)
		network_constants_const.UNRELIABLE_ENTITY_RPC_COMMAND:
			network_writer = write_entity_rset_command(p_sender_id, p_rpc_call, network_writer)
		_:
			NetworkLogger.error("Unknown entity message")

	return network_writer


func flush() -> void:
	pending_rpc_reliable_calls = []
	pending_rpc_unreliable_calls = []
	pending_rset_reliable_calls = []
	pending_rset_unreliable_calls = []


func _network_manager_flush() -> void:
	flush()


func write_remote_command(p_sender_id: int, p_rpc_call: Dictionary, p_type: int, p_network_writer_state: Object) -> void:
	var remote_command_network_writer: Object = create_rpc_command(p_sender_id, p_type, p_rpc_call)
	p_network_writer_state.put_writer(remote_command_network_writer, remote_command_network_writer.get_position())


func _network_manager_process(p_id: int, _delta: float) -> void:
	if pending_rpc_reliable_calls.size() > 0 or pending_rpc_unreliable_calls.size() > 0 or pending_rset_reliable_calls.size() > 0 or pending_rset_unreliable_calls.size() > 0:
		# Debugging information
		# Debugging end

		var synced_peers: Array = network_manager.copy_valid_send_peers(p_id, false)

		for synced_peer in synced_peers:
			var network_reliable_writer_state: Object = null
			var network_unreliable_writer_state: Object = null

			if synced_peer != -1:
				network_reliable_writer_state = rpc_reliable_writers[synced_peer]
				network_unreliable_writer_state = rpc_unreliable_writers[synced_peer]
			else:
				network_reliable_writer_state = dummy_rpc_reliable_writer
				network_unreliable_writer_state = dummy_rpc_unreliable_writer

			network_reliable_writer_state.seek(0)
			network_unreliable_writer_state.seek(0)

			if network_manager.is_server() or network_manager.is_relay():
				for rpc_call in pending_rpc_reliable_calls:
					if rpc_call["target_id"] == synced_peer or rpc_call["target_id"] == 0:
						write_remote_command(p_id, rpc_call, network_constants_const.RELIABLE_ENTITY_RPC_COMMAND, network_reliable_writer_state)
				for rpc_call in pending_rset_reliable_calls:
					if rpc_call["target_id"] == synced_peer or rpc_call["target_id"] == 0:
						write_remote_command(p_id, rpc_call, network_constants_const.RELIABLE_ENTITY_RSET_COMMAND, network_reliable_writer_state)
				for rpc_call in pending_rpc_unreliable_calls:
					if rpc_call["target_id"] == synced_peer or rpc_call["target_id"] == 0:
						write_remote_command(p_id, rpc_call, network_constants_const.UNRELIABLE_ENTITY_RPC_COMMAND, network_unreliable_writer_state)
				for rpc_call in pending_rset_unreliable_calls:
					if rpc_call["target_id"] == synced_peer or rpc_call["target_id"] == 0:
						write_remote_command(p_id, rpc_call, network_constants_const.UNRELIABLE_ENTITY_RSET_COMMAND, network_unreliable_writer_state)
			else:
				if synced_peer == network_constants_const.SERVER_MASTER_PEER_ID:
					for rpc_call in pending_rpc_reliable_calls:
						write_remote_command(p_id, rpc_call, network_constants_const.RELIABLE_ENTITY_RPC_COMMAND, network_reliable_writer_state)
					for rpc_call in pending_rset_reliable_calls:
						write_remote_command(p_id, rpc_call, network_constants_const.RELIABLE_ENTITY_RSET_COMMAND, network_reliable_writer_state)
					for rpc_call in pending_rpc_unreliable_calls:
						write_remote_command(p_id, rpc_call, network_constants_const.UNRELIABLE_ENTITY_RPC_COMMAND, network_unreliable_writer_state)
					for rpc_call in pending_rset_unreliable_calls:
						write_remote_command(p_id, rpc_call, network_constants_const.UNRELIABLE_ENTITY_RSET_COMMAND, network_unreliable_writer_state)

			if network_reliable_writer_state.get_position() > 0:
				var raw_data: PackedByteArray = network_reliable_writer_state.get_raw_data(network_reliable_writer_state.get_position())
				network_manager.network_flow_manager.queue_packet_for_send(ref_pool_const.new(raw_data), synced_peer, MultiplayerPeer.TRANSFER_MODE_RELIABLE)

			if network_unreliable_writer_state.get_position() > 0:
				var raw_data: PackedByteArray = network_unreliable_writer_state.get_raw_data(network_unreliable_writer_state.get_position())
				network_manager.network_flow_manager.queue_packet_for_send(ref_pool_const.new(raw_data), synced_peer, MultiplayerPeer.TRANSFER_MODE_UNRELIABLE)

		# Flush the pending RPC queues
		flush()


func decode_entity_remote_command(p_packet_sender_id: int, p_reliable: bool, p_rpc: bool, p_network_reader: Object) -> Object:
	var network_entity_manager: Node = network_manager.network_entity_manager
	var sender_id: int = p_packet_sender_id
	var target_id: int = get_tree().get_multiplayer().get_unique_id()

	if p_network_reader.is_eof():
		NetworkLogger.error("decode_entity_remote_command: eof!")
		return null

	if !network_manager.is_relay():
		if p_packet_sender_id == network_constants_const.SERVER_MASTER_PEER_ID:
			sender_id = p_network_reader.get_u32()
			if p_network_reader.is_eof():
				return null
		else:
			target_id = p_network_reader.get_u32()
			if p_network_reader.is_eof():
				return null

	var instance_id: int = network_entity_manager.read_entity_instance_id(p_network_reader)
	if instance_id <= network_entity_manager.NULL_NETWORK_INSTANCE_ID:
		NetworkLogger.error("decode_entity_remote_command: eof!")
		return null

	var method_id: int = p_network_reader.get_16()

	if p_network_reader.is_eof():
		NetworkLogger.error("decode_entity_remote_command: eof!")
		return null

	var arg_count: int = p_network_reader.get_8()

	if p_network_reader.is_eof():
		NetworkLogger.error("decode_entity_remote_command: eof!")
		return null

	var args: Array = []
	for _i in range(0, arg_count):
		var arg = p_network_reader.get_var()

		if p_network_reader.is_eof():
			NetworkLogger.error("decode_entity_remote_command: eof!")
			return null

		args.push_back(arg)

	if network_entity_manager.network_instance_ids.has(instance_id):
		var entity_instance: Node = network_entity_manager.network_instance_ids[instance_id].get_entity_node()
		if entity_instance:
			if target_id == get_tree().get_multiplayer().get_unique_id() or target_id == 0:
				var rpc_table: Node = entity_instance.get_rpc_table()
				if rpc_table:
					if p_rpc:
						rpc_table.nm_rpc_called(p_packet_sender_id, method_id, args)
					else:
						rpc_table.nm_rset_called(p_packet_sender_id, method_id, args)

			if target_id != get_tree().get_multiplayer().get_unique_id() or target_id == 0:
				if !network_manager.is_relay() and network_manager.is_server():
					var command_type: int
					if p_reliable:
						if p_rpc:
							command_type = network_constants_const.RELIABLE_ENTITY_RPC_COMMAND
						else:
							command_type = network_constants_const.RELIABLE_ENTITY_RSET_COMMAND
					else:
						if p_rpc:
							command_type = network_constants_const.UNRELIABLE_ENTITY_RPC_COMMAND
						else:
							command_type = network_constants_const.UNRELIABLE_ENTITY_RSET_COMMAND

					var rpc_call: Dictionary = {"method_id": method_id, "args": args, "entity": entity_instance}
					# Servers send remote command to any valid peers
					var synced_peers: Array = network_manager.copy_active_peers()
					if target_id == 0:
						# How should these behave in relation to syncing
						for synced_peer in synced_peers:
							var writer: Object = rpc_reliable_writers[synced_peer]
							writer.seek(0)

							write_remote_command(sender_id, rpc_call, command_type, writer)
							if writer.get_position() > 0:
								var raw_data: PackedByteArray = writer.get_raw_data(writer.get_position())
								network_manager.network_flow_manager.queue_packet_for_send(ref_pool_const.new(raw_data), synced_peer, MultiplayerPeer.TRANSFER_MODE_RELIABLE)
					else:
						if synced_peers.has(target_id):
							var writer: Object = rpc_unreliable_writers[target_id]
							writer.seek(0)

							write_remote_command(sender_id, rpc_call, command_type, writer)
							if writer.get_position() > 0:
								var raw_data: PackedByteArray = writer.get_raw_data(writer.get_position())
								network_manager.network_flow_manager.queue_packet_for_send(ref_pool_const.new(raw_data), target_id, MultiplayerPeer.TRANSFER_MODE_UNRELIABLE)
						else:
							printerr("RPC command has invalid target ID!")
		else:
			printerr("Could not find entity instantiate!")
	return p_network_reader


func decode_remote_buffer(p_packet_sender_id: int, p_network_reader: Object, p_command: int) -> Object:
	match p_command:
		network_constants_const.RELIABLE_ENTITY_RPC_COMMAND:
			p_network_reader = decode_entity_remote_command(p_packet_sender_id, true, true, p_network_reader)
		network_constants_const.UNRELIABLE_ENTITY_RPC_COMMAND:
			p_network_reader = decode_entity_remote_command(p_packet_sender_id, false, true, p_network_reader)
		network_constants_const.RELIABLE_ENTITY_RSET_COMMAND:
			p_network_reader = decode_entity_remote_command(p_packet_sender_id, true, false, p_network_reader)
		network_constants_const.UNRELIABLE_ENTITY_RSET_COMMAND:
			p_network_reader = decode_entity_remote_command(p_packet_sender_id, false, false, p_network_reader)
		_:
			NetworkLogger.error("Unknown Entity replication command")

	return p_network_reader


func _game_hosted() -> void:
	rpc_reliable_writers = {}
	rpc_unreliable_writers = {}


func _connected_to_server() -> void:
	rpc_reliable_writers = {}
	var network_reliable_writer: Object = network_writer_const.new(MAXIMUM_RPC_PACKET_SIZE)
	rpc_reliable_writers[network_constants_const.SERVER_MASTER_PEER_ID] = network_reliable_writer

	rpc_unreliable_writers = {}
	var network_unreliable_writer: Object = network_writer_const.new(MAXIMUM_RPC_PACKET_SIZE)
	rpc_unreliable_writers[network_constants_const.SERVER_MASTER_PEER_ID] = network_unreliable_writer


func _server_peer_connected(p_id: int) -> void:
	var rpc_reliable_writer: Object = network_writer_const.new(MAXIMUM_RPC_PACKET_SIZE)
	rpc_reliable_writers[p_id] = rpc_reliable_writer
	var rpc_unreliable_writer: Object = network_writer_const.new(MAXIMUM_RPC_PACKET_SIZE)
	rpc_unreliable_writers[p_id] = rpc_unreliable_writer


func _server_peer_disconnected(p_id: int) -> void:
	if !rpc_reliable_writers.erase(p_id):
		NetworkLogger.error("network_rpc_manager: attempted disconnect invalid peer!")
	if !rpc_unreliable_writers.erase(p_id):
		NetworkLogger.error("network_rpc_manager: attempted disconnect invalid peer!")


func is_command_valid(p_command: int) -> bool:
	if p_command == network_constants_const.RELIABLE_ENTITY_RPC_COMMAND or p_command == network_constants_const.RELIABLE_ENTITY_RSET_COMMAND or p_command == network_constants_const.UNRELIABLE_ENTITY_RPC_COMMAND or p_command == network_constants_const.UNRELIABLE_ENTITY_RSET_COMMAND:
		return true
	else:
		return false


func _ready() -> void:
	if !Engine.is_editor_hint():
		connection_util_const.connect_signal_table(signal_table, self)
