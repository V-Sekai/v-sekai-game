# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_editor_progress_dialog_body.gd
# SPDX-License-Identifier: MIT

@tool
extends Control
class_name VSKEditorProgressDialogBody

signal cancel_button_pressed

@export var progress_label_nodepath: Label = null
@export var progress_bar_nodepath: ProgressBar = null
@export var cancel_button_nodepath: Button = null


func set_progress_label_text(p_text: String) -> void:
	if progress_label_nodepath:
		progress_label_nodepath.set_text(p_text)


func set_progress_bar_value(p_value: float) -> void:
	if progress_bar_nodepath:
		progress_bar_nodepath.set_value(p_value)


func _on_CancelButton_pressed() -> void:
	cancel_button_pressed.emit()
