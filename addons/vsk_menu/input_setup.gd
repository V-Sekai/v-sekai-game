# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# input_setup.gd
# SPDX-License-Identifier: MIT

extends "res://addons/vsk_menu/setup_menu.gd"  # setup_menu.gd

@export var mouse_sensitivity_nodepath: NodePath = NodePath()
var mouse_sensitivity_node: Control = null

@export var look_invert_nodepath: NodePath = NodePath()
var look_invert_node: Button = null


func _on_look_invert_toggled(button_pressed: bool) -> void:
	InputManager.invert_look_y = button_pressed


func _on_mouse_sensitivity_value_changed(p_value: float) -> void:
	InputManager.mouse_sensitivity = p_value


func _ready() -> void:
	mouse_sensitivity_node = get_node(mouse_sensitivity_nodepath)
	mouse_sensitivity_node.set_value(InputManager.mouse_sensitivity)

	look_invert_node = get_node(look_invert_nodepath)
	look_invert_node.button_pressed = InputManager.invert_look_y


func _gameflow_state_changed(_p_state) -> void:
	pass


func will_appear() -> void:
	if VSKGameFlowManager.gameflow_state_changed.connect(self._gameflow_state_changed) != OK:
		printerr("Could not connect gameflow_state_changed!")


func will_disappear() -> void:
	if VSKGameFlowManager.gameflow_state_changed.is_connected(self._gameflow_state_changed):
		VSKGameFlowManager.gameflow_state_changed.disconnect(self._gameflow_state_changed)


func save_changes() -> void:
	super.save_changes()

	VSKUserPreferencesManager.save_settings()
