# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# menu_view_controller.gd
# SPDX-License-Identifier: MIT

extends "res://addons/navigation_controller/view_controller.gd"

@export var default_focus: NodePath

func _input(_event):
	if Input.is_action_just_pressed("ui_cancel"):
		if has_navigation_controller() and get_navigation_controller().view_controller_stack.size() > 1:
			back_button_pressed()

func back_button_pressed():
	if has_navigation_controller():
		get_navigation_controller().pop_view_controller(true)
