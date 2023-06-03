# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# bitset.gd
# SPDX-License-Identifier: MIT

extends RefCounted

var bitset: PackedByteArray = PackedByteArray()
var first_available_index: int = 0


func is_empty() -> bool:
	for _i in range(0, bitset.size()):
		if bitset[0] != 0:
			return false

	return true


func get_bit(p_bit_index: int) -> bool:
	var byte_position: int = p_bit_index / 8
	var remainder: int = p_bit_index % 8

	return ((bitset[byte_position] & (1 << remainder)) >> remainder) == 1


func set_bit(p_bit_index: int, p_enable: bool) -> void:
	var byte_position: int = p_bit_index / 8
	var remainder: int = p_bit_index % 8

	if p_enable:
		bitset[byte_position] |= (1 << remainder)
	else:
		bitset[byte_position] &= ~(1 << remainder)


func _init(p_size: int, p_enabled: bool):
	bitset = PackedByteArray()
	bitset.resize(((p_size) - 1 / 8) + 1)
	if p_enabled:
		for i in range(0, bitset.size()):
			bitset[i] = 1
	else:
		for i in range(0, bitset.size()):
			bitset[i] = 0
