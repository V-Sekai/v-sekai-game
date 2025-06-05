# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_editor_progress_dialog.gd
# SPDX-License-Identifier: MIT

@tool
extends Window
class_name VSKEditorProgressDialog

signal cancel_button_pressed

@export var progress_dialog_body: VSKEditorProgressDialogBody = null

func set_progress_bar_value(p_value: float) -> void:
	if progress_dialog_body:
		progress_dialog_body.set_progress_bar_value(p_value)

func set_progress_label_text(p_text: String) -> void:
	if progress_dialog_body:
		progress_dialog_body.set_progress_label_text(p_text)

func _on_cancel_button_pressed() -> void:
	cancel_button_pressed.emit()
