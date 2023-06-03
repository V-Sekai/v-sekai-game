# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# network_spawn.gd
# SPDX-License-Identifier: MIT

class_name NetworkSpawn extends Marker3D


func _enter_tree() -> void:
	add_to_group("NetworkSpawnGroup")


func _exit_tree() -> void:
	remove_from_group("NetworkSpawnGroup")
