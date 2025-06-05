# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_map_callback.gd
# SPDX-License-Identifier: MIT

@tool
extends Node
class_name VSKMapCallback

enum Result {
	MAP_OK,
	MAP_FAILED,
	ROOT_IS_NULL,
	EXPORTER_NODE_LOADED,
	INVALID_NODE
}


static func get_error_string(p_err: int) -> String:
	var error_str: String = "Unknown error!"
	match p_err:
		Result.MAP_FAILED:
			error_str = "Generic map error! (complain to Saracen)"
		Result.ROOT_IS_NULL:
			error_str = "Root node is null!"
		Result.EXPORTER_NODE_LOADED:
			error_str = "Exporter not loaded!"
		Result.INVALID_NODE:
			error_str = "Invalid node!"

	return error_str
