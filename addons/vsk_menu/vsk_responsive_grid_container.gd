# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_responsive_grid_container.gd
# SPDX-License-Identifier: MIT

@tool
extends GridContainer

@export var width_min: float = 256.0:
	set(p_new):
		width_min = p_new
		update_columns()


func update_columns() -> void:
	var count: float = size.x / width_min
	var new_column_count: int = int(ceil(count))
	if new_column_count < 1:
		new_column_count = 1

	columns = new_column_count


func _notification(p_what: int) -> void:
	match p_what:
		NOTIFICATION_RESIZED:
			update_columns()
		NOTIFICATION_ENTER_TREE:
			update_columns()
