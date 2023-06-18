# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_progress_dialog_body.gd
# SPDX-License-Identifier: MIT

@tool
extends Control

signal cancel_button_pressed

@export var progress_label_nodepath: NodePath = NodePath()
@export var progress_bar_nodepath: NodePath = NodePath()
@export var cancel_button_nodepath: NodePath = NodePath()


func set_progress_label_text(p_text: String) -> void:
	get_node(progress_label_nodepath).set_text(p_text)


func set_progress_bar_value(p_value: float) -> void:
	get_node(progress_bar_nodepath).set_value(p_value)


func _on_CancelButton_pressed() -> void:
	cancel_button_pressed.emit()
