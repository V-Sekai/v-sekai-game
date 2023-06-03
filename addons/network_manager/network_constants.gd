# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# network_constants.gd
# SPDX-License-Identifier: MIT

extends Node

const AUTHORITATIVE_SERVER_NAME = "authoritative"
const RELAY_SERVER_NAME = "relay"

const DEFAULT_PORT = 7777
const LOCALHOST_IP = "127.0.0.1"

const ALL_PEERS: int = 0
const SERVER_MASTER_PEER_ID: int = 1
const PEER_PENDING_TIMEOUT: int = 20


class validation_state_enum:
	const VALIDATION_STATE_NONE = 0
	const VALIDATION_STATE_CONNECTION = 1
	const VALIDATION_STATE_PEERS_SENT = 2
	const VALIDATION_STATE_INFO_SENT = 3
	const VALIDATION_STATE_AWAITING_STATE = 4
	const VALIDATION_STATE_STATE_SENT = 5
	const VALIDATION_STATE_SYNCED = 6


# A list of all the network commands which can be sent or received.
const UPDATE_ENTITY_COMMAND = 0
const SPAWN_ENTITY_COMMAND = 1
const DESTROY_ENTITY_COMMAND = 2
const REQUEST_ENTITY_MASTER_COMMAND = 3
const TRANSFER_ENTITY_MASTER_COMMAND = 4
const RELIABLE_ENTITY_RPC_COMMAND = 5
const RELIABLE_ENTITY_RSET_COMMAND = 6
const UNRELIABLE_ENTITY_RPC_COMMAND = 7
const UNRELIABLE_ENTITY_RSET_COMMAND = 8
const VOICE_COMMAND = 9
const INFO_REQUEST_COMMAND = 10
const STATE_REQUEST_COMMAND = 11
const READY_COMMAND = 12
const DISCONNECT_COMMAND = 13
const MAP_CHANGING_COMMAND = 14
const SESSION_MASTER_COMMAND = 15
const CALLBACK_SPAWN_ENTITY_COMMAND = 16

const COMMAND_STRING_TABLE: Dictionary = {
	UPDATE_ENTITY_COMMAND: "UpdateEntityCommand",
	SPAWN_ENTITY_COMMAND: "SpawnEntityCommand",
	DESTROY_ENTITY_COMMAND: "DestroyEntityCommand",
	REQUEST_ENTITY_MASTER_COMMAND: "RequestEntityMasterCommand",
	TRANSFER_ENTITY_MASTER_COMMAND: "TransferEntityMasterCommand",
	RELIABLE_ENTITY_RPC_COMMAND: "ReliableEntityRPCCommand",
	RELIABLE_ENTITY_RSET_COMMAND: "ReliableEntityRSetCommand",
	UNRELIABLE_ENTITY_RPC_COMMAND: "UnreliableEntityRPCCommand",
	UNRELIABLE_ENTITY_RSET_COMMAND: "UnreliableEntityRSetCommand",
	VOICE_COMMAND: "VoiceCommand",
	INFO_REQUEST_COMMAND: "InfoRequestCommand",
	STATE_REQUEST_COMMAND: "StateRequestCommand",
	READY_COMMAND: "ReadyCommand",
	MAP_CHANGING_COMMAND: "MapChangingCommand",
	SESSION_MASTER_COMMAND: "SessionMasterCommand",
	CALLBACK_SPAWN_ENTITY_COMMAND: "CallbackSpawnEntityCommand",
}


# Returns a string name for a corresponding network command
static func get_string_for_command(p_id: int) -> String:
	if COMMAND_STRING_TABLE.has(p_id):
		return COMMAND_STRING_TABLE[p_id]

	return ""
