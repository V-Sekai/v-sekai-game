# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_user_content_test.gd
# SPDX-License-Identifier: MIT

extends Control


func export_data() -> Dictionary:
	return {}


func _ready():
	var vsk_editor: Node = get_node_or_null("/root/VSKEditor")
	if vsk_editor:
		vsk_editor.setup_editor(self, null, null)
	else:
		push_error("Could not load VSKEditor!")
