# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_editor_dialog.gd
# SPDX-License-Identifier: MIT

@tool
extends AcceptDialog
class_name VSKEditorDialog

func _ready() -> void:
	maximize_disabled = false
	minimize_disabled = false
	get_ok_button().hide()
