# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# canvas_utils.gd
# SPDX-License-Identifier: MIT

@tool

const UI_PIXELS_TO_METER = 1.0 / 1024


static func find_child_control(p_root: Node) -> Control:
	if not p_root:
		printerr("p_root is null.")
		return null

	var control_node: Control = null
	for child in p_root.get_children():
		if child is Control:
			control_node = child
			break

	return control_node


static func get_physcially_scaled_size_from_control(p_control: Control) -> Vector2:
	return p_control.get_size() * UI_PIXELS_TO_METER
