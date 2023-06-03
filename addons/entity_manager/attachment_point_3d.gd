# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# attachment_point_3d.gd
# SPDX-License-Identifier: MIT

extends Node3D

var entity: Node = null:
	set = set_entity,
	get = get_entity


func set_entity(p_entity) -> void:
	entity = p_entity


func get_entity() -> Node:
	return entity
