# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# interpolate_origin_to_zero_node_3d.gd
# SPDX-License-Identifier: MIT

extends Node3D

var origin_offset: Vector3 = Vector3()

func _process(_delta: float) -> void:
	var fraction: float = Engine.get_physics_interpolation_fraction()
	
	transform.origin = lerp(origin_offset, Vector3(), fraction)
