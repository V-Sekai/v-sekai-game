# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_menu_audio.gd
# SPDX-License-Identifier: MIT

extends Node

@export var button_nodepath: NodePath = NodePath()

@export var focused_sound: AudioStream  # (AudioStream) = null
@export var pressed_sound: AudioStream  # (AudioStream) = null


func _on_pressed():
	VSKMenuManager.play_menu_sfx(pressed_sound)


func _on_focus_entered():
	VSKMenuManager.play_menu_sfx(focused_sound)


func _on_mouse_entered():
	var button_node = get_node_or_null(button_nodepath)
	if button_node and button_node.has_focus():
		VSKMenuManager.play_menu_sfx(focused_sound)


func clear_connections() -> void:
	var button_node = get_node_or_null(button_nodepath)
	if button_node:
		if button_node.pressed.is_connected(self._on_pressed):
			button_node.pressed.disconnect(self._on_pressed)
		if button_node.mouse_entered.is_connected(self._on_mouse_entered):
			button_node.mouse_entered.disconnect(self._on_mouse_entered)
		if button_node.focus_entered.is_connected(self._on_focus_entered):
			button_node.focus_entered.disconnect(self._on_focus_entered)


func setup_connections() -> void:
	var button_node = get_node_or_null(button_nodepath)
	if button_node:
		if button_node.pressed.connect(self._on_pressed) != OK:
			printerr("Could not connected 'pressed'!")
		if button_node.mouse_entered.connect(self._on_mouse_entered) != OK:
			printerr("Could not connected 'mouse_entered'!")
		if button_node.focus_entered.connect(self._on_focus_entered) != OK:
			printerr("Could not connected 'focus_entered'!")


func _exit_tree():
	clear_connections()


func _enter_tree() -> void:
	call_deferred("setup_connections")
