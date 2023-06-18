# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# options_screen.gd
# SPDX-License-Identifier: MIT

extends "res://addons/vsk_menu/menu_view_controller.gd"  # menu_view_controller.gd

var audio_setup = load("res://addons/vsk_menu/main_menu/audio_setup.tscn")
var network_setup = load("res://addons/vsk_menu/main_menu/network_setup.tscn")
var input_setup = load("res://addons/vsk_menu/main_menu/input_setup.tscn")
var vr_setup = load("res://addons/vsk_menu/main_menu/vr_setup.tscn")


func _on_BackButton_pressed():
	back_button_pressed()


func _on_AudioButton_pressed() -> void:
	if has_navigation_controller():
		get_navigation_controller().push_view_controller(audio_setup.instantiate(), true)


func _on_GraphicsButton_pressed():
	pass  # Replace with function body.


func _on_PlayerButton_pressed():
	if has_navigation_controller():
		get_navigation_controller().push_view_controller(network_setup.instantiate(), true)


func _on_InputButton_pressed():
	if has_navigation_controller():
		get_navigation_controller().push_view_controller(input_setup.instantiate(), true)


func _on_VRButton_pressed():
	if has_navigation_controller():
		get_navigation_controller().push_view_controller(vr_setup.instantiate(), true)
