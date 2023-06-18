# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_shard_manager.gd
# SPDX-License-Identifier: MIT

@tool
extends Node

signal shard_create_callback(p_result)
signal shard_delete_callback(p_result)
signal shard_list_callback(p_result)
signal shard_heartbeat_callback(p_result)
signal shard_update_player_count_callback(p_result)

var active_shards: Dictionary = {}


func create_shard(p_callback: RefCounted, p_port: int, p_map: String, p_server_name: String, p_player_count: int, p_max_players: int) -> void:
	var async_result = await (GodotUro.godot_uro_api.create_shard_async({"port": p_port, "map": p_map, "name": p_server_name, "max_users": p_max_players, "current_users": p_player_count}))

	if async_result["output"] is Dictionary:
		var data = async_result["output"].get("data")
		if data is Dictionary:
			var id = data.get("id")
			if id is String:
				active_shards[id] = {"port": p_port}
				shard_create_callback.emit({"result": OK, "data": data, "callback": p_callback})
				return

	active_shards[async_result] = {"port": p_port}
	shard_create_callback.emit({"result": FAILED, "data": null, "callback": p_callback})


func delete_shard(p_callback: RefCounted, p_id: String):
	var async_result = await GodotUro.godot_uro_api.delete_shard_async(p_id, {})

	var data = async_result["output"].get("data")
	if data is Dictionary:
		var id = data.get("id")
		if id is String:
			if active_shards.erase(id):
				shard_delete_callback.emit({"result": OK, "data": null, "callback": p_callback})
				return

	shard_delete_callback.emit({"result": FAILED, "data": null, "callback": p_callback})


func show_shards(p_callback: RefCounted) -> void:
	var async_result = await GodotUro.godot_uro_api.get_shards_async()

	if !async_result["output"]["data"].is_empty():
		shard_list_callback.emit({"result": OK, "data": async_result["output"]["data"], "callback": p_callback})
		return

	shard_list_callback.emit({"result": FAILED, "data": null, "callback": p_callback})


func shard_heartbeat(p_id: String) -> void:
	var async_result = await GodotUro.godot_uro_api.update_shard_async(p_id, {})

	var data = async_result["output"].get("data")
	if data is Dictionary:
		var id = data.get("id")
		if id is String:
			active_shards[id] = {}
			shard_heartbeat_callback.emit({"result": OK, "data": data, "callback": null})
			return

	active_shards[async_result] = {}
	shard_heartbeat_callback.emit({"result": FAILED, "data": null, "callback": null})


func shard_update_player_count(p_id: String, p_player_count: int) -> void:
	var async_result = await GodotUro.godot_uro_api.update_shard_async(p_id, {"current_users": p_player_count})

	var data = async_result.get("data")
	if data is Dictionary:
		var id = data.get("id")
		if id is String:
			active_shards[id] = {}
			shard_update_player_count_callback.emit({"result": OK, "data": data, "callback": null})
	else:
		active_shards[async_result] = {}
		shard_update_player_count_callback.emit({"result": FAILED, "data": null, "callback": null})


func setup() -> void:
	pass
