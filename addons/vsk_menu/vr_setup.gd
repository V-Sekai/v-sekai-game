# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vr_setup.gd
# SPDX-License-Identifier: MIT

extends "res://addons/vsk_menu/setup_menu.gd"  # setup_menu.gd

@export var movement_orientation_nodepath: NodePath = NodePath()
var movement_orientation_button: MenuButton = null

@export var turning_mode_nodepath: NodePath = NodePath()
var turning_mode_button: MenuButton = null

@export var custom_player_height_nodepath: NodePath = NodePath()
var custom_player_height: SpinBox = null

@export var movement_type_nodepath: NodePath = NodePath()
var movement_type_button: MenuButton = null


func _ready() -> void:
	movement_orientation_button = get_node_or_null(movement_orientation_nodepath)
	setup_menu_button(movement_orientation_button, VRManager.vr_user_preferences.movement_orientation, VRManager.movement_orientation_names)
	if movement_orientation_button.get_popup().connect("id_pressed", self._on_movement_orientation_changed) != OK:
		printerr("Could not connect 'id_pressed'!")

	turning_mode_button = get_node_or_null(turning_mode_nodepath)
	setup_menu_button(turning_mode_button, VRManager.vr_user_preferences.turning_mode, VRManager.turning_mode_names)
	if turning_mode_button.get_popup().id_pressed.connect(self._on_turning_mode_changed) != OK:
		printerr("Could not connect 'id_pressed'!")

	custom_player_height = get_node_or_null(custom_player_height_nodepath)
	custom_player_height.value = VRManager.vr_user_preferences.custom_player_height

	movement_type_button = get_node_or_null(movement_type_nodepath)
	setup_menu_button(movement_type_button, VRManager.vr_user_preferences.movement_type, VRManager.movement_type_names)
	if movement_type_button.get_popup().id_pressed.connect(self._on_movement_type_changed) != OK:
		printerr("Could not connect 'id_pressed'!")

	unindicate_restart_required()


func _gameflow_state_changed(_p_state) -> void:
	pass


func will_appear() -> void:
	if VSKGameFlowManager.gameflow_state_changed.connect(self._gameflow_state_changed) != OK:
		printerr("Could not connect gameflow_state_changed!")


func will_disappear() -> void:
	if VSKGameFlowManager.gameflow_state_changed.is_connected(self._gameflow_state_changed):
		VSKGameFlowManager.gameflow_state_changed.disconnect(self._gameflow_state_changed)


func _on_movement_orientation_changed(p_id: int) -> void:
	VRManager.vr_user_preferences.movement_orientation = p_id
	update_menu_button_text(movement_orientation_button, VRManager.vr_user_preferences.movement_orientation, VRManager.movement_orientation_names)


func _on_turning_mode_changed(p_id: int) -> void:
	VRManager.vr_user_preferences.turning_mode = p_id
	update_menu_button_text(turning_mode_button, VRManager.vr_user_preferences.turning_mode, VRManager.turning_mode_names)


func _on_PlayerHeightSpinbox_value_changed(p_value: float) -> void:
	VRManager.vr_user_preferences.custom_player_height = p_value


func _on_movement_type_changed(p_id: int) -> void:
	VRManager.vr_user_preferences.movement_type = p_id
	update_menu_button_text(movement_type_button, VRManager.vr_user_preferences.movement_type, VRManager.movement_type_names)


func _on_VREnabled_pressed():
	VRManager.toggle_vr()


func save_changes() -> void:
	super.save_changes()

	VRManager.vr_user_preferences.set_settings_values_and_save()
