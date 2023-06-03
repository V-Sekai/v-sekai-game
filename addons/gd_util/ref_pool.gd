# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# ref_pool.gd
# SPDX-License-Identifier: MIT

@tool
extends RefCounted

# Stopgap, used until 4.0

var pool_byte_array: PackedByteArray = PackedByteArray()


func _init(p_pool_byte_array: PackedByteArray):
	pool_byte_array = p_pool_byte_array
