# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# ingame_menu.gd
# SPDX-License-Identifier: MIT

extends Node

@export var mute_button_path: NodePath = NodePath()
var mute_buton: Button = null

@export var fps_label_path: NodePath = NodePath()
var fps_label: Label = null


func update_mute_button_text() -> void:
	if VSKAudioManager.muted:
		mute_buton.set_text(tr("TR_MENU_UNMUTE"))
	else:
		mute_buton.set_text(tr("TR_MENU_MUTE"))


func _ready():
	mute_buton = get_node_or_null(mute_button_path)
	update_mute_button_text()

	fps_label = get_node_or_null(fps_label_path)


func _on_DisconnectButton_pressed() -> void:
	await VSKGameFlowManager.go_to_title(false)


func _on_MuteButton_pressed() -> void:
	VSKAudioManager.toggle_mute()
	update_mute_button_text()


func _process(_delta):
	if fps_label:
		fps_label.set_text("FPS: %s" % str(Engine.get_frames_per_second()))
