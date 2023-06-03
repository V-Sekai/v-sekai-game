# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# password_input.gd
# SPDX-License-Identifier: MIT

extends HBoxContainer

signal text_changed(p_text)

var text: String:
	set = set_text,
	get = get_text

var password_visible_off = load("res://addons/vsk_menu/textures/password_visible_off.svg")
var password_visible_on = load("res://addons/vsk_menu/textures/password_visible_on.svg")


func set_text(p_text: String) -> void:
	$PasswordLineEdit.text = p_text


func get_text() -> String:
	return $PasswordLineEdit.text


# Why doesn't this toggle signal work by itself?
func _on_password_hide_toggle_toggled(p_button_pressed: bool) -> void:
	$PasswordLineEdit.secret = !p_button_pressed
	$PasswordHideToggle.icon = password_visible_on if p_button_pressed else password_visible_off


func _on_password_line_edit_text_changed(p_text: String) -> void:
	text_changed.emit(p_text)


func _on_password_hide_toggle_pressed():
	_on_password_hide_toggle_toggled($PasswordHideToggle.button_pressed)
