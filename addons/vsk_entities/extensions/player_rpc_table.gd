# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# player_rpc_table.gd
# SPDX-License-Identifier: MIT

extends "res://addons/network_manager/network_rpc_table.gd"

signal avatar_path_updated(p_path)
signal did_teleport

@rpc("authority") func send_did_teleport() -> void:
	did_teleport.emit()


@rpc("authority") func send_set_avatar_path(p_path: String) -> void:
	avatar_path_updated.emit(p_path)
