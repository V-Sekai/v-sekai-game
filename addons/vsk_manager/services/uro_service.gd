# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# uro_service.gd
# SPDX-License-Identifier: MIT

extends "res://addons/vsk_manager/services/service.gd"  # service.gd

var shard_id: String = ""


func service_get_name() -> String:
	return "Uro"


func service_setup_game() -> void:
	pass


func service_update_game(_delta: float) -> void:
	pass


func service_setup_editor() -> void:
	pass


func service_update_editor(_delta: float) -> void:
	pass


func service_game_server_hosted(p_port: int, p_max_users: int, p_map: String, p_advertise: bool) -> String:
	if p_advertise:
		var result = await GodotUro.godot_uro_api.create_shard(p_port, p_map, p_max_users)
		shard_id = result
	else:
		shard_id = ""

	completed.emit()
	return shard_id


func service_game_server_shutdown() -> int:
	return await GodotUro.godot_uro_api.delete_shard(shard_id)
