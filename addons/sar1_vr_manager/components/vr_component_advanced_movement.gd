# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vr_component_advanced_movement.gd
# SPDX-License-Identifier: MIT

extends "res://addons/sar1_vr_manager/components/vr_component.gd"  # vr_component.gd

const vr_advanced_movement_action = preload("actions/vr_advanced_movement_action.gd")


func _jump_pressed() -> void:
	var a: InputEventAction = InputEventAction.new()
	a.action = "jump"
	a.pressed = true
	Input.parse_input_event(a)


func _jump_released() -> void:
	var a: InputEventAction = InputEventAction.new()
	a.action = "jump"
	a.pressed = false
	Input.parse_input_event(a)


func tracker_added(p_tracker: XRController3D) -> void:
	super.tracker_added(p_tracker)

	var tracker_hand: int = p_tracker.get_tracker_hand()
	if tracker_hand == XRPositionalTracker.TRACKER_HAND_LEFT or tracker_hand == XRPositionalTracker.TRACKER_HAND_RIGHT:
		var action: Node3D = vr_advanced_movement_action.new()

		if action.jump_pressed.connect(self._jump_pressed) != OK:
			printerr("Could not connect jump_pressed signal!")
		if action.jump_released.connect(self._jump_released) != OK:
			printerr("Could not connect jump_released signal!")

		p_tracker.add_component_action(action)


func post_add_setup() -> void:
	super.post_add_setup()


func _enter_tree():
	set_name("AdvancedMovementComponent")
