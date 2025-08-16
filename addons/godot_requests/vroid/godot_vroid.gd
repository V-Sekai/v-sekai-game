# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# godot_vroid.gd
# SPDX-License-Identifier: MIT

@tool
extends GodotRequestService
class_name GodotVroid

var godot_vroid_api: GodotVroidAPI = null

func _load_api() -> void:
	if godot_vroid_api == null:
		godot_vroid_api = GodotVroidAPI.new(self)

func get_api() -> GodotVroidAPI:
	return godot_vroid_api

func get_service_name() -> String:
	return "vroid"
