# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# network_setup.gd
# SPDX-License-Identifier: MIT

extends "res://addons/vsk_menu/setup_menu.gd"  # setup_menu.gd

@export var name_input_nodepath: NodePath = NodePath()
@export var avatar_input_nodepath: NodePath = NodePath()

var name_input: LineEdit = null
var avatar_input: LineEdit = null


func _avatar_path_selected(p_path: String) -> void:
	avatar_input.text = p_path
	VSKPlayerManager.set_avatar_path(p_path)

	save_changes()


func set_controls_disabled(p_disabled: bool) -> void:
	name_input.set_editable(!p_disabled)


func _on_NameLineEdit_text_changed(new_text: String) -> void:
	VSKPlayerManager.set_display_name(new_text)


func _on_AvatarLineEdit_text_changed(new_text: String) -> void:
	VSKPlayerManager.set_avatar_path(new_text)


func _on_clear_cache_button_pressed() -> void:
	VSKAssetManager.clear_cache()


func _on_avatar_browse_button_pressed() -> void:
	$AvatarSelectorPopup.popup_centered_ratio()


func save_changes() -> void:
	super.save_changes()

	VSKPlayerManager.set_settings_values_and_save()


func _gameflow_state_changed(_p_state) -> void:
	pass


func will_appear() -> void:
	if VSKGameFlowManager.gameflow_state_changed.connect(self._gameflow_state_changed) != OK:
		printerr("Could not connect gameflow_state_changed!")


func will_disappear() -> void:
	if VSKGameFlowManager.gameflow_state_changed.is_connected(self._gameflow_state_changed):
		VSKGameFlowManager.gameflow_state_changed.disconnect(self._gameflow_state_changed)


func _ready() -> void:
	name_input = get_node_or_null(name_input_nodepath)
	avatar_input = get_node_or_null(avatar_input_nodepath)

	name_input.set_text(VSKPlayerManager.display_name)
	avatar_input.set_text(VSKPlayerManager.avatar_path)

	if $AvatarSelectorPopup.path_selected.connect(self._avatar_path_selected) != OK:
		push_error("Failed to connect path_selected signal")
		return
