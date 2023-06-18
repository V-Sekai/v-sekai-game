# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# string_util.gd
# SPDX-License-Identifier: MIT

@tool


static func string_ends_with(p_main_string: String, p_end_string: String) -> bool:
	var pos: int = p_main_string.rfind(p_end_string)
	if pos == -1:
		return false
	return pos + p_end_string.length() == p_main_string.length()


static func teststr(p_what: String, p_str: String) -> bool:
	if p_what.findn("$" + p_str) != -1:
		return true
	if string_ends_with(p_what.to_lower(), "-%s" % p_str):
		return true
	if string_ends_with(p_what.to_lower(), "_%s" % p_str):
		return true
	return false


static func fixstr(p_what: String, p_str: String) -> String:
	if p_what.findn("$%s" % p_str) != -1:
		return p_what.replace("$%s" % p_str, "")
	if p_what.to_lower().ends_with("-%s" % p_str):
		return p_what.substr(0, p_what.length() - (p_str.length() + 1))
	if p_what.to_lower().ends_with("_%s" % p_str):
		return p_what.substr(0, p_what.length() - (p_str.length() + 1))
	return p_what


static func convert_string_pool_array_into_hint_string(p_array: PackedStringArray) -> String:
	var result: String = ""

	for i in range(0, p_array.size()):
		if i != 0:
			result += ","
		result += p_array[i]

	return result
