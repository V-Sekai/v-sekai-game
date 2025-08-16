# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# godot_uro.gd
# SPDX-License-Identifier: MIT

@tool
extends GodotRequestService
class_name GodotUro

var godot_uro_api: GodotUroAPI = null

func _load_api() -> void:
	if godot_uro_api == null:
		godot_uro_api = GodotUroAPI.new(self)

func get_api() -> GodotUroAPI:
	return godot_uro_api

func get_service_name() -> String:
	return "uro"

func create_requester(p_host: String, p_port: int) -> GodotUroRequester:
	if p_host == "localhost":
		p_host = GodotUroHelper.LOCALHOST_HOST
	
	var new_requester = GodotUroRequester.new(
		http_pool, p_host, p_port, not _is_host_localhost(p_host)
	)

	return new_requester
