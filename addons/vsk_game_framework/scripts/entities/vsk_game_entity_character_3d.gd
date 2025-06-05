# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_game_entity_character_3d.gd
# SPDX-License-Identifier: MIT

@tool
extends SarGameEntityCharacter3D
class_name VSKGameEntityCharacter3D

func get_game_entity_valid_scene_path() -> String:
	return "res://addons/vsk_game_framework/scenes/entities/vsk_game_entity_character_3d.tscn"
