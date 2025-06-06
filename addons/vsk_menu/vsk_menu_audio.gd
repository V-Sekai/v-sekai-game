# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_menu_audio.gd
# SPDX-License-Identifier: MIT

extends Node

@export var button_nodepath: NodePath = NodePath()

@export var focused_sound: AudioStream  # (AudioStream) = null
@export var pressed_sound: AudioStream  # (AudioStream) = null

const anim_const_path = preload("res://addons/navigation_controller/navigation_controller.gd")
const transition_time: float = anim_const_path.anim_transition_time

var active_tween: Tween = null


func _on_pressed():
	VSKMenuManager.play_menu_sfx(pressed_sound)
	animate_click()


func _on_focus_entered():
	VSKMenuManager.play_menu_sfx(focused_sound)


func _on_mouse_entered():
	var button_node = get_node_or_null(button_nodepath)
	if button_node and button_node.has_focus():
		VSKMenuManager.play_menu_sfx(focused_sound)


func animate_click():
	var button_node = get_node_or_null(button_nodepath)

	# reset
	button_node.scale = Vector2(1.0, 1.0)
	button_node.pivot_offset = button_node.size / 2
	if active_tween:
		active_tween.kill()
		active_tween = null

	active_tween = button_node.create_tween().set_trans(Tween.TRANS_SINE).set_ease(
		Tween.EASE_IN_OUT
	)

	active_tween.tween_property(button_node, "scale", Vector2(0.9, 0.9), transition_time / 2)

	active_tween.chain().tween_property(
		button_node, "scale", Vector2(1.0, 1.0), transition_time / 2
	)

	await active_tween.finished

	button_node.release_focus()


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
			push_error("Could not connected 'pressed'!")
		if button_node.mouse_entered.connect(self._on_mouse_entered) != OK:
			push_error("Could not connected 'mouse_entered'!")
		if button_node.focus_entered.connect(self._on_focus_entered) != OK:
			push_error("Could not connected 'focus_entered'!")


func _exit_tree():
	clear_connections()


func _enter_tree() -> void:
	call_deferred("setup_connections")
