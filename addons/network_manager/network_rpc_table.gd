# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# network_rpc_table.gd
# SPDX-License-Identifier: MIT

class_name NetworkRPCTable extends "res://addons/entity_manager/component_node.gd"

var virtual_rpc_method_table: Dictionary = {}
var virtual_rpc_property_table: Dictionary = {}

var sender_id: int = -1


func get_remote_sender_id() -> int:
	return sender_id


func nm_rpc_called(p_sender_id: int, p_method_id: int, p_arg_array: Array):
	var original_sender_id: int = sender_id
	sender_id = p_sender_id

	var keys: Array = virtual_rpc_method_table.keys()
	if p_method_id < keys.size() and p_method_id >= 0:
		var method_name: String = keys[p_method_id]
		var rpc_mode: int = virtual_rpc_method_table[method_name].rpc_mode
		if rpc_mode == MultiplayerAPI.RPC_MODE_ANY_PEER:
			callv(method_name, p_arg_array)
		elif rpc_mode == MultiplayerAPI.RPC_MODE_AUTHORITY:
			callv("method_name", p_arg_array)
		else:
			NetworkLogger.error("Cannot call {method_name} from peer {sender_id}!".format({"method_name": method_name, "sender_id": str(p_sender_id)}))
	else:
		NetworkLogger.error("Cannot find method for id %s!" % str(p_method_id))

	sender_id = original_sender_id


func nm_rset_called(p_sender_id: int, p_property_id: int, p_value):
	var original_sender_id: int = sender_id
	sender_id = p_sender_id

	var keys: Array = virtual_rpc_property_table.keys()
	if p_property_id < keys.size() and p_property_id >= 0:
		var property_name: String = keys[p_property_id]
		var rpc_mode: int = virtual_rpc_property_table[property_name].rpc_mode
		if rpc_mode == MultiplayerAPI.RPC_MODE_ANY_PEER:
			set(property_name, p_value)
		elif rpc_mode == MultiplayerAPI.RPC_MODE_AUTHORITY:
			if p_sender_id == get_multiplayer_authority():
				set(property_name, p_value)
			else:
				NetworkLogger.error("Cannot set {property_name} from peer {sender_id}!".format({"property_name": property_name, "sender_id": str(p_sender_id)}))
	else:
		NetworkLogger.error("Cannot find property for id %s!" % str(p_property_id))

	sender_id = original_sender_id


func _nm_rpcp(p_peer_id: int, p_unreliable: bool, p_method: String, p_arg_array: Array):
	var keys: Array = virtual_rpc_method_table.keys()
	var method_id: int = -1
	for i in range(0, keys.size()):
		if keys[i] == p_method:
			var rpc_mode: int = virtual_rpc_method_table[p_method].rpc_mode
			if rpc_mode == MultiplayerAPI.RPC_MODE_ANY_PEER:
				callv(p_method, p_arg_array)
			method_id = i

	if method_id >= 0:
		if p_unreliable:
			NetworkManager.network_rpc_manager.queue_unreliable_rpc_call(get_entity_node(), p_peer_id, method_id, p_arg_array)
		else:
			NetworkManager.network_rpc_manager.queue_reliable_rpc_call(get_entity_node(), p_peer_id, method_id, p_arg_array)
	else:
		NetworkLogger.error("Could not find method id for %s!" % p_method)


func _nm_rsetp(p_peer_id: int, p_unreliable: bool, p_property: String, p_value):
	var keys: Array = virtual_rpc_property_table.keys()
	var property_id: int = -1
	for i in range(0, keys.size()):
		if keys[i] == p_property:
			var rpc_mode: int = virtual_rpc_property_table[p_property].rpc_mode
			if rpc_mode == MultiplayerAPI.RPC_MODE_ANY_PEER:
				set(p_property, p_value)
			property_id = i

	if property_id >= 0:
		if p_unreliable:
			NetworkManager.network_rpc_manager.queue_unreliable_rset_call(get_entity_node(), p_peer_id, property_id, p_value)
		else:
			NetworkManager.network_rpc_manager.queue_reliable_rset_call(get_entity_node(), p_peer_id, property_id, p_value)
	else:
		NetworkLogger.error("Could not find property id for %s!" % p_property)


func nm_rpc(p_method: String, p_arg_array: Array):
	_nm_rpcp(0, false, p_method, p_arg_array)


func nm_rpc_id(p_peer_id: int, p_method: String, p_arg_array: Array):
	_nm_rpcp(p_peer_id, false, p_method, p_arg_array)


func nm_rpc_unreliable(p_method: String, p_arg_array: Array):
	_nm_rpcp(0, true, p_method, p_arg_array)


func nm_rpc_unreliable_id(p_peer_id: int, p_method: String, p_arg_array: Array):
	_nm_rpcp(p_peer_id, true, p_method, p_arg_array)


func nm_rset(p_property: String, p_value):
	_nm_rsetp(0, false, p_property, p_value)


func nm_rset_id(p_peer_id: int, p_property: String, p_value):
	_nm_rsetp(p_peer_id, false, p_property, p_value)


func nm_rset_unreliable(p_property: String, p_value):
	_nm_rsetp(0, true, p_property, p_value)


func nm_rset_unreliable_id(peer_id: int, p_property: String, p_value):
	_nm_rsetp(peer_id, true, p_property, p_value)


func sanitise_rpc() -> void:
	pass
	#var method_list: Array = get_method_list()
	#for method in method_list:
	#	# FIXME: rpc_get_mode is missing
	#	var rpc_mode: int = rpc_get_mode(method.name)
	#	if rpc_mode != MultiplayerAPI.RPC_MODE_DISABLED: ##### FIXME: Missing method in godot master #
	#		virtual_rpc_method_table[method.name] = {"rpc_mode": rpc_mode}
	#		rpc_config(method.name, MultiplayerAPI.RPC_MODE_DISABLED)


func _ready():
	if !Engine.is_editor_hint() and get_tree().get_multiplayer().has_multiplayer_peer():
		sender_id = get_tree().get_multiplayer().get_unique_id()
	else:
		sender_id = -1


func _init():
	if !Engine.is_editor_hint():
		sanitise_rpc()
