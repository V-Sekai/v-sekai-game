# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# player_movement_provider.gd
# SPDX-License-Identifier: MIT

extends Node

@export var enabled := true

func execute(_movement_controller: Node, _delta: float) -> bool:
	return enabled

func get_xr_origin(p_movement_controller: Node) -> XROrigin3D:
	return p_movement_controller.xr_origin
	
func get_xr_camera(p_movement_controller: Node) -> XRCamera3D:
	return p_movement_controller.xr_camera
	
func get_character_body(p_movement_controller: Node) -> CharacterBody3D:
	return p_movement_controller.character_body
