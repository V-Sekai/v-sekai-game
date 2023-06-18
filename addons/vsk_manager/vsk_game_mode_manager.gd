# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_game_mode_manager.gd
# SPDX-License-Identifier: MIT

@tool
extends Node

const DEFAULT_GAME_MODE_PATH = ""

var current_game_mode_path: String = ""
var game_mode: Node = null


func get_current_game_mode_path() -> String:
	return current_game_mode_path


##
##
##


func on_game_mode_initalised() -> void:
	if game_mode:
		game_mode.on_game_mode_initalised()


func on_game_mode_shutdown() -> void:
	if game_mode:
		game_mode.on_game_mode_shutdown()


func on_peer_connected(p_id: int, p_client_info: Dictionary) -> Dictionary:
	if game_mode:
		return game_mode.on_peer_connected(p_id, p_client_info)
	else:
		return p_client_info


func on_peer_disconnected(p_id: int) -> void:
	if game_mode:
		game_mode.on_peer_disconnected(p_id)
