# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# labelled_slider.gd
# SPDX-License-Identifier: MIT

extends HBoxContainer

signal value_changed(p_value)

@export var slider_path: NodePath = NodePath()
@export var label_path: NodePath = NodePath()

@export var padded_decimals: int = 1


func _update_label() -> void:
	var value: float = get_node(slider_path).value

	get_node(label_path).set_text(str(value).pad_decimals(padded_decimals))


func _on_slider_value_changed(value):
	_update_label()

	value_changed.emit(value)


func set_value(p_value: float) -> void:
	get_node(slider_path).value = p_value

	_update_label()


func _ready() -> void:
	_update_label()
