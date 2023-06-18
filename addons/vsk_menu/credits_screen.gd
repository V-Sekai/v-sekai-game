# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# credits_screen.gd
# SPDX-License-Identifier: MIT

extends "res://addons/vsk_menu/menu_view_controller.gd"  # menu_view_controller.gd

var audio_setup = load("res://addons/vsk_menu/main_menu/audio_setup.tscn")
var network_setup = load("res://addons/vsk_menu/main_menu/network_setup.tscn")
var vr_setup = load("res://addons/vsk_menu/main_menu/vr_setup.tscn")

@export var credits_label_nodepath: NodePath = NodePath()


func _on_BackButton_pressed():
	super.back_button_pressed()


func _ready():
	var credits_label: RichTextLabel = get_node_or_null(credits_label_nodepath)
	if credits_label:
		credits_label.add_text(VSKCreditsManager.get_credits_text())
