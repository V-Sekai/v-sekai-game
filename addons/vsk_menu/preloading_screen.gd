# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# preloading_screen.gd
# SPDX-License-Identifier: MIT

extends "res://addons/vsk_menu/menu_view_controller.gd"  # menu_view_controller.gd

@export var progress_bar_path: NodePath = NodePath()
var progress_bar: ProgressBar = null

@export var loading_status_label_path: NodePath = NodePath()
var loading_status_label: Label = null


func will_appear() -> void:
	pass


func will_disappear() -> void:
	pass


func set_progress(p_progress: int) -> void:
	if progress_bar:
		var value: float = lerp(progress_bar.min_value, progress_bar.max_value, p_progress)
		progress_bar.set_value(value)


func set_loading_status(p_status_message: String) -> void:
	if loading_status_label:
		loading_status_label.set_text(p_status_message)


func _ready() -> void:
	if has_node(progress_bar_path):
		progress_bar = get_node(progress_bar_path)

	if has_node(loading_status_label_path):
		loading_status_label = get_node(loading_status_label_path)
