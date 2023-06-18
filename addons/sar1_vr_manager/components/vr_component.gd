# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vr_component.gd
# SPDX-License-Identifier: MIT

extends Node3D

const vr_controller_tracker_const = preload("res://addons/sar1_vr_manager/vr_controller_tracker.gd")

signal trackers_changed

var head_tracker_module: Node3D = null

var hand_controllers: Array = []
var left_hand_controller: XRController3D = null
var right_hand_controller: XRController3D = null


func tracker_added(p_tracker: XRController3D) -> void:  # vr_controller_tracker_const
	var tracker_hand: int = p_tracker.get_tracker_hand()
	match tracker_hand:
		XRPositionalTracker.TRACKER_HAND_LEFT:
			# Attempt to add left controller
			if left_hand_controller == null:
				left_hand_controller = p_tracker
				hand_controllers.push_back(p_tracker)
		XRPositionalTracker.TRACKER_HAND_RIGHT:
			if right_hand_controller == null:
				right_hand_controller = p_tracker
				hand_controllers.push_back(p_tracker)
		_:
			pass

	trackers_changed.emit()


func tracker_removed(p_tracker: XRController3D) -> void:  # vr_controller_tracker_const
	var index: int = hand_controllers.find(p_tracker)
	if index != -1:
		hand_controllers.remove_at(index)

	if left_hand_controller == p_tracker:
		left_hand_controller = null

	if right_hand_controller == p_tracker:
		right_hand_controller = null

	trackers_changed.emit()


func post_add_setup() -> void:
	pass


func _enter_tree():
	set_name("VRComponent")
