# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_info_dialog.gd
# SPDX-License-Identifier: MIT

@tool
extends AcceptDialog


func set_info_text(p_text: String) -> void:
	$InfoLabel.set_text(p_text)

	set_size(Vector2())
