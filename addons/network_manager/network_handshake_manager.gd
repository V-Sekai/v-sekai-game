# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# network_handshake_manager.gd
# SPDX-License-Identifier: MIT

@tool
extends Node

const ref_pool_const = preload("res://addons/gd_util/ref_pool.gd")

const network_constants_const = preload("network_constants.gd")
const network_writer_const = preload("network_writer.gd")
const connection_util_const = preload("res://addons/gd_util/connection_util.gd")

var signal_table: Array = [{"singleton": "NetworkManager", "signal": "server_state_ready", "method": "_server_state_ready"}]

var network_manager: Object


func _init(p_network_manager):
	network_manager = p_network_manager


##
##
##

var network_handshake_command_writer_cache = network_writer_const.new(1024)


func current_master_id():
	pass


func ready_command(p_id: int) -> void:
	var network_writer: Object = network_handshake_command_writer_cache
	network_writer.seek(0)

	network_writer.put_u8(network_constants_const.READY_COMMAND)

	if network_writer.get_position() > 0:
		var raw_data: PackedByteArray = network_writer.get_raw_data(network_writer.get_position())
		network_manager.network_flow_manager.queue_packet_for_send(ref_pool_const.new(raw_data), p_id, MultiplayerPeer.TRANSFER_MODE_RELIABLE)


func disconnect_command(p_disconnected_peer_id: int) -> void:
	var synced_peers: Array = network_manager.copy_active_peers()
	for synced_peer in synced_peers:
		if synced_peer == p_disconnected_peer_id:
			continue

		var network_writer: Object = network_handshake_command_writer_cache
		network_writer.seek(0)

		network_writer.put_u8(network_constants_const.DISCONNECT_COMMAND)
		network_writer.put_u32(p_disconnected_peer_id)

		if network_writer.get_position() > 0:
			var raw_data: PackedByteArray = network_writer.get_raw_data(network_writer.get_position())
			network_manager.network_flow_manager.queue_packet_for_send(ref_pool_const.new(raw_data), synced_peer, MultiplayerPeer.TRANSFER_MODE_RELIABLE)


func session_master_command(p_id: int, p_new_master: int) -> void:
	var network_writer: Object = network_handshake_command_writer_cache
	network_writer.seek(0)

	network_writer.put_u8(network_constants_const.SESSION_MASTER_COMMAND)
	network_writer.put_u32(p_new_master)

	if network_writer.get_position() > 0:
		var raw_data: PackedByteArray = network_writer.get_raw_data(network_writer.get_position())
		network_manager.network_flow_manager.queue_packet_for_send(ref_pool_const.new(raw_data), p_id, MultiplayerPeer.TRANSFER_MODE_RELIABLE)


func attempt_to_send_server_state_to_peer(p_peer_id: int):
	if network_manager.server_state_ready:
		if network_manager.peer_data[p_peer_id]["validation_state"] == network_constants_const.validation_state_enum.VALIDATION_STATE_AWAITING_STATE:
			network_manager.peer_data[p_peer_id]["validation_state"] = (network_constants_const.validation_state_enum.VALIDATION_STATE_STATE_SENT)
			network_manager.emit_requested_server_state(p_peer_id)


# Called by the client once the server has confirmed they have been validated
@rpc("any_peer") func requested_server_info(p_client_info: Dictionary) -> void:
	NetworkLogger.printl("requested_server_info...")
	var rpc_sender_id: int = get_tree().get_multiplayer().get_remote_sender_id()

	network_manager.received_peer_validation_state_update(rpc_sender_id, network_constants_const.validation_state_enum.VALIDATION_STATE_INFO_SENT)

	network_manager.emit_received_client_info(rpc_sender_id, p_client_info)
	network_manager.emit_requested_server_info(rpc_sender_id)


# Called by the server
@rpc("authority") func received_server_info(p_server_info: Dictionary) -> void:
	NetworkLogger.printl("received_server_info...")

	if p_server_info.has("server_type"):
		var server_type = p_server_info["server_type"]
		if server_type is String:
			match p_server_info["server_type"]:
				network_constants_const.RELAY_SERVER_NAME:
					NetworkLogger.printl("Connected to a relay server...")
					network_manager.set_relay(true)
					network_manager.emit_received_server_info(p_server_info)
					return
				network_constants_const.AUTHORITATIVE_SERVER_NAME:
					NetworkLogger.printl("Connected to a authoritative server...")
					network_manager.set_relay(false)
					network_manager.emit_received_server_info(p_server_info)
					return
				_:
					NetworkLogger.error("Unknown server type")
		else:
			NetworkLogger.error("Server type is not a string")

	network_manager.request_network_kill()


@rpc("authority") func received_client_info(p_client: int, p_client_info: Dictionary) -> void:
	NetworkLogger.printl("received_client_info...")
	network_manager.emit_received_client_info(p_client, p_client_info)


# Called by client after the basic scene state for the client has been loaded and set up
@rpc("any_peer") func requested_server_state(_client_info: Dictionary) -> void:
	NetworkLogger.printl("requested_server_state...")
	var rpc_sender_id: int = get_tree().get_multiplayer().get_remote_sender_id()

	# This peer is waiting for the server state, but we may not be able to send it yet if the server has not fully loaded, so sit tight...
	network_manager.received_peer_validation_state_update(rpc_sender_id, network_constants_const.validation_state_enum.VALIDATION_STATE_AWAITING_STATE)

	attempt_to_send_server_state_to_peer(rpc_sender_id)


@rpc("authority") func received_server_state(p_server_state: Dictionary) -> void:
	NetworkLogger.printl("received_server_state...")
	network_manager.emit_received_server_state(p_server_state)


func decode_handshake_buffer(p_packet_sender_id: int, p_network_reader: Object, p_command: int) -> Object:
	match p_command:
		network_constants_const.INFO_REQUEST_COMMAND:
			pass
		network_constants_const.STATE_REQUEST_COMMAND:
			pass
		network_constants_const.READY_COMMAND:
			network_manager.peer_data[p_packet_sender_id].validation_state = (network_constants_const.validation_state_enum.VALIDATION_STATE_SYNCED)
		network_constants_const.DISCONNECT_COMMAND:
			if p_network_reader.is_eof():
				NetworkLogger.error("decode_handshake_buffer: eof!")
				return p_network_reader

			var id: int = p_network_reader.get_u32()

			if p_network_reader.is_eof():
				NetworkLogger.error("decode_handshake_buffer: eof!")
				return p_network_reader

			disconnect_peer(p_packet_sender_id, id)
		network_constants_const.MAP_CHANGING_COMMAND:
			pass

	return p_network_reader


# Called after all other clients have been registered to the new client
@rpc("authority") func peer_registration_complete() -> void:
	# Client does not have direct permission to access this method
	if not network_manager.is_server() and not network_manager.is_rpc_sender_id_server():
		return

	# FIXME(lyuma): the original code emitted this signal on the wrong object. emitting here might be unnecessary.
	network_manager.peer_registration_complete.emit()


func is_command_valid(p_command: int) -> bool:
	if p_command == network_constants_const.INFO_REQUEST_COMMAND or p_command == network_constants_const.STATE_REQUEST_COMMAND or p_command == network_constants_const.READY_COMMAND or p_command == network_constants_const.DISCONNECT_COMMAND or p_command == network_constants_const.MAP_CHANGING_COMMAND:
		return true
	else:
		return false


func disconnect_peer(p_packet_sender_id: int, p_id: int) -> void:
	# Client does not have direct permission to access this method
	if p_packet_sender_id == network_constants_const.SERVER_MASTER_PEER_ID:
		network_manager.unregister_peer(p_id)


func _server_state_ready() -> void:
	var peers: Array = network_manager.get_connected_peers()
	for peer in peers:
		attempt_to_send_server_state_to_peer(peer)


func _ready() -> void:
	if !Engine.is_editor_hint():
		connection_util_const.connect_signal_table(signal_table, self)
