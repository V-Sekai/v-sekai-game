# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# player_character_body_3d.gd
# SPDX-License-Identifier: MIT

extends "res://addons/extended_kinematic_body/extended_kinematic_body.gd"

signal touched_by_body(p_body)


func send_touched_by_body(p_body):
	touched_by_body.emit(p_body)
