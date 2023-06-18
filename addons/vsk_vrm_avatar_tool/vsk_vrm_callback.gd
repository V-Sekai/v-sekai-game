# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_vrm_callback.gd
# SPDX-License-Identifier: MIT

@tool
extends RefCounted

enum { VRM_OK, VRM_FAILED, VRM_INVALID_MENU_OPTION, VRM_COULD_NOT_SAVE, VRM_COULD_NOT_PACK, VRM_INVALID_NODE, VRM_NO_EDITOR_PLUGIN }


static func get_error_string(p_err: int) -> String:
	var error_str: String = "Unknown error!"
	match p_err:
		VRM_FAILED:
			error_str = "Generic VRM error! (complain to Saracen)"
		VRM_INVALID_MENU_OPTION:
			error_str = "Invalid menu option"
		VRM_COULD_NOT_SAVE:
			error_str = "Could not be saved"
		VRM_COULD_NOT_PACK:
			error_str = "Could not be packed"
		VRM_INVALID_NODE:
			error_str = "Invalid node"
		VRM_NO_EDITOR_PLUGIN:
			error_str = "No editor plugin found"

	return error_str


static func generic_error_check(p_root: Node3D) -> int:
	return VRM_OK
