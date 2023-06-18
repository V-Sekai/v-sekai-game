# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# network_voice_manager.gd
# SPDX-License-Identifier: MIT

@tool
extends Node

var get_voice_buffers: Callable = Callable()
var get_sequence_id: Callable = Callable()
var should_send_audio: Callable = Callable()

const ref_pool_const = preload("res://addons/gd_util/ref_pool.gd")

const network_constants_const = preload("network_constants.gd")
const network_writer_const = preload("network_writer.gd")

const MAXIMUM_VOICE_PACKET_SIZE = 1024

var dummy_voice_writer = network_writer_const.new(MAXIMUM_VOICE_PACKET_SIZE)  # For debugging purposes
var voice_writers = {}

var network_manager: Object


func _init(p_network_manager):
	network_manager = p_network_manager


var signal_table: Array = [
	{"singleton": "NetworkManager", "signal": "network_process", "method": "_network_manager_process"},
	{"singleton": "NetworkManager", "signal": "game_hosted", "method": "_game_hosted"},
	{"singleton": "NetworkManager", "signal": "connection_succeeded", "method": "_connected_to_server"},
	{"singleton": "NetworkManager", "signal": "server_peer_connected", "method": "_server_peer_connected"},
	{"singleton": "NetworkManager", "signal": "server_peer_disconnected", "method": "_server_peer_disconnected"},
]

##
##
##


func encode_voice_packet(p_packet_sender_id: int, p_network_writer: Object, p_sequence_id: int, p_voice_buffer: Dictionary, p_encode_id: bool) -> Object:
	var voice_buffer_size: int = p_voice_buffer["buffer_size"]

	if p_encode_id:
		p_network_writer.put_u32(p_packet_sender_id)
	p_network_writer.put_u24(p_sequence_id)
	p_network_writer.put_u16(voice_buffer_size)
	if voice_buffer_size > 0:
		p_network_writer.put_ranged_data(p_voice_buffer["byte_array"], 0, voice_buffer_size)

	return p_network_writer


func decode_voice_command(p_packet_sender_id: int, p_network_reader: Object) -> Object:
	var encoded_voice_byte_array: PackedByteArray = PackedByteArray()
	var encoded_sequence_id: int = -1
	var encoded_size: int = -1
	var sender_id: int = -1

	if p_network_reader.is_eof():
		return null

	if !network_manager.is_relay() and p_packet_sender_id == network_constants_const.SERVER_MASTER_PEER_ID:
		sender_id = p_network_reader.get_u32()
		if p_network_reader.is_eof():
			return null
	else:
		sender_id = p_packet_sender_id

	encoded_sequence_id = p_network_reader.get_u24()
	if p_network_reader.is_eof():
		return null
	encoded_size = p_network_reader.get_u16()
	if p_network_reader.is_eof():
		return null

	if encoded_size > 0:
		encoded_voice_byte_array = p_network_reader.get_buffer(encoded_size)
		if p_network_reader.is_eof():
			return null

	if encoded_size != encoded_voice_byte_array.size():
		NetworkLogger.error("pool size mismatch!")

	# If you're the server, forward the packet to all the other peers
	if !network_manager.is_relay() and network_manager.is_server():
		var synced_peers: Array = network_manager.copy_active_peers()
		for synced_peer in synced_peers:
			if synced_peer != sender_id:
				var network_writer_state: Object = null

				if synced_peer != -1:
					network_writer_state = voice_writers[synced_peer]
				else:
					network_writer_state = dummy_voice_writer

				# Could seeking here cause an issue?
				network_writer_state.seek(0)

				var encoded_voice: Dictionary = Dictionary()
				encoded_voice["byte_array"] = encoded_voice_byte_array
				encoded_voice["buffer_size"] = encoded_voice_byte_array.size()

				# Voice commands
				network_writer_state = encode_voice_buffer(sender_id, network_writer_state, encoded_sequence_id, encoded_voice, true)

				if network_writer_state.get_position() > 0:
					var raw_data: PackedByteArray = network_writer_state.get_raw_data(network_writer_state.get_position())
					network_manager.network_flow_manager.queue_packet_for_send(ref_pool_const.new(raw_data), synced_peer, MultiplayerPeer.TRANSFER_MODE_UNRELIABLE)

	if not network_manager.server_dedicated:
		network_manager.voice_packet_compressed.emit(sender_id, encoded_sequence_id, encoded_voice_byte_array)

	return p_network_reader


func _network_manager_process(p_id: int, _delta: float) -> void:
	var synced_peers: Array = network_manager.copy_valid_send_peers(p_id, false)

	if get_voice_buffers.is_valid() and get_sequence_id.is_valid():
		var sequence_id: int = get_sequence_id.call()
		var voice_buffers: Array = get_voice_buffers.call()

		for voice_buffer in voice_buffers:
			# If muted or gated, give it an empty array
			if !should_send_audio.is_valid():
				voice_buffer = {"byte_array": PackedByteArray(), "buffer_size": 0}
			else:
				if !should_send_audio.call():
					voice_buffer = {"byte_array": PackedByteArray(), "buffer_size": 0}

			for synced_peer in synced_peers:
				var network_writer_state: Object = null

				if synced_peer != -1:
					network_writer_state = voice_writers[synced_peer]
				else:
					network_writer_state = dummy_voice_writer

				network_writer_state.seek(0)

				# Voice commands
				network_writer_state = encode_voice_buffer(p_id, network_writer_state, sequence_id, voice_buffer, !network_manager.is_relay() and (synced_peer != network_constants_const.SERVER_MASTER_PEER_ID))

				if network_writer_state.get_position() > 0:
					var raw_data: PackedByteArray = network_writer_state.get_raw_data(network_writer_state.get_position())
					network_manager.network_flow_manager.queue_packet_for_send(ref_pool_const.new(raw_data), synced_peer, MultiplayerPeer.TRANSFER_MODE_UNRELIABLE)
			sequence_id += 1


func encode_voice_buffer(p_packet_sender_id: int, p_network_writer: Object, p_index: int, p_voice_buffer: Dictionary, p_encode_id: bool) -> Object:
	p_network_writer.put_u8(network_constants_const.VOICE_COMMAND)
	p_network_writer = encode_voice_packet(p_packet_sender_id, p_network_writer, p_index, p_voice_buffer, p_encode_id)

	return p_network_writer


func decode_voice_buffer(p_packet_sender_id: int, p_network_reader: Object, p_command: int) -> Object:
	match p_command:
		network_constants_const.VOICE_COMMAND:
			p_network_reader = decode_voice_command(p_packet_sender_id, p_network_reader)

	return p_network_reader


func _game_hosted() -> void:
	voice_writers = {}


func _connected_to_server() -> void:
	voice_writers = {}
	var network_writer = network_writer_const.new(MAXIMUM_VOICE_PACKET_SIZE)
	voice_writers[network_constants_const.SERVER_MASTER_PEER_ID] = network_writer


func _server_peer_connected(p_id: int) -> void:
	var network_writer = network_writer_const.new(MAXIMUM_VOICE_PACKET_SIZE)
	voice_writers[p_id] = network_writer


func _server_peer_disconnected(p_id: int) -> void:
	if !voice_writers.erase(p_id):
		NetworkLogger.error("network_state_manager: attempted disconnect invalid peer!")


func is_command_valid(p_command: int) -> bool:
	if p_command == network_constants_const.VOICE_COMMAND:
		return true
	else:
		return false


func _ready() -> void:
	if !Engine.is_editor_hint():
		$"/root/ConnectionUtil".connect_signal_table(signal_table, self)
