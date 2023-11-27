# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_shard_manager.gd
# SPDX-License-Identifier: MIT

@tool
extends Node

var active_shards: Dictionary = {}

func create_shard(p_callback: Callable, p_port: int, p_map: String, p_server_name: String, p_player_count: int, p_max_players: int) -> Dictionary:
	var async_result = await (GodotUro.godot_uro_api.create_shard_async({"port": p_port, "map": p_map, "name": p_server_name, "max_users": p_max_players, "current_users": p_player_count}))

	if async_result["output"] is Dictionary:
		var data = async_result["output"].get("data")
		if data is Dictionary:
			var id = data.get("id")
			if id is String:
				active_shards[id] = {"port": p_port}
				if p_callback.is_valid():
					p_callback.call({"result": OK, "data": data})
				return {"result": OK, "data": data}

	active_shards[async_result] = {"port": p_port}
	if p_callback.is_valid():
		p_callback.call({"result": FAILED, "data": null})
	return {"result": FAILED, "data": null}

func delete_shard(p_callback: Callable, p_id: String) -> Dictionary:
	var async_result = await GodotUro.godot_uro_api.delete_shard_async(p_id, {})

	var data = async_result["output"].get("data")
	if data is Dictionary:
		var id = data.get("id")
		if id is String:
			if active_shards.erase(id):
				if p_callback.is_valid():
					p_callback.call({"result": OK, "data": null})
				return {"result": OK, "data": null}

	if p_callback.is_valid():
		p_callback.call({"result": OK, "data": null})
	return {"result": FAILED, "data": null}


func show_shards(p_callback: Callable) -> Dictionary:
	var async_result = await GodotUro.godot_uro_api.get_shards_async()

	if !async_result["output"]["data"].is_empty():
		if p_callback.is_valid():
			p_callback.call({"result": OK, "data": async_result["output"]["data"]})
		return {"result": OK, "data": async_result["output"]["data"]}

	if p_callback.is_valid():
		p_callback.call({"result": FAILED, "data": null})
	return {"result": FAILED, "data": null}


func shard_heartbeat(p_id: String) -> Dictionary:
	var async_result = await GodotUro.godot_uro_api.update_shard_async(p_id, {})

	var data = async_result["output"].get("data")
	if data is Dictionary:
		var id = data.get("id")
		if id is String:
			active_shards[id] = {}
			return {"result": OK, "data": data}

	active_shards[async_result] = {}
	return {"result": FAILED, "data": null, "callback": null}


func shard_update_player_count(p_callback: Callable, p_id: String, p_player_count: int) -> Dictionary:
	var async_result = await GodotUro.godot_uro_api.update_shard_async(p_id, {"current_users": p_player_count})
	
	var data = async_result.get("data")
	if data is Dictionary:
		var id = data.get("id")
		if id is String:
			active_shards[id] = {}
			if p_callback.is_valid():
				p_callback.call({"result": OK, "data": data})
			return {"result": OK, "data": data,}
	
	active_shards[async_result] = {}
	
	if p_callback.is_valid():
		p_callback.call({"result": FAILED, "data": null})
	return {"result": FAILED, "data": null}

func setup() -> void:
	pass # Nothing to setup
