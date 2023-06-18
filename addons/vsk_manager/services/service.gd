# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# service.gd
# SPDX-License-Identifier: MIT

extends RefCounted

signal completed

var required_host_notify: bool = false


func load_scripts() -> bool:
	return true


func service_get_name() -> String:
	return ""


func service_setup_game() -> void:
	pass


func service_update_game(_delta: float) -> void:
	pass


func service_setup_editor() -> void:
	pass


func service_update_editor(_delta: float) -> void:
	pass


func service_shutdown_editor() -> void:
	pass


func service_shutdown_game() -> void:
	pass


func service_game_server_hosted(_port: int, _max_users: int, _map: String, _advertise: bool) -> String:
	completed.emit()
	return ""


func service_game_server_shutdown() -> int:
	completed.emit()
	return -1
