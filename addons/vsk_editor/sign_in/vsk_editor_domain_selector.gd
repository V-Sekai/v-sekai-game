# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_editor_domain_selector.gd
# SPDX-License-Identifier: MIT

@tool
extends ConfirmationDialog
class_name VSKEditorDomainSelector

@export var line_edit: LineEdit = null

func _update_confirm_button_state() -> void:
	if line_edit.text.is_empty():
		get_ok_button().disabled = true
	else:
		get_ok_button().disabled = false

func _on_line_edit_text_changed(_new_text: String) -> void:
	_update_confirm_button_state()

func _ready() -> void:
	if not get_tree().edited_scene_root:
		_update_confirm_button_state()
