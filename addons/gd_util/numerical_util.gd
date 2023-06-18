# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# numerical_util.gd
# SPDX-License-Identifier: MIT

@tool
extends Node


static func get_string_for_integer_with_group_seperator(p_integer: int, p_seperator: String, p_grouping_size: int) -> String:
	var formatted_string: String = str(p_integer)
	var formatted_string_length: int = formatted_string.length()
	var grouping_counter: int = 0

	var idx: int = formatted_string_length - 1
	while idx > 0:
		grouping_counter += 1
		if grouping_counter == p_grouping_size:
			formatted_string = formatted_string.insert(idx, p_seperator)
			grouping_counter = 0
		idx -= 1

	return formatted_string
