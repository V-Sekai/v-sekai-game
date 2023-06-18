# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vr_component_interaction.gd
# SPDX-License-Identifier: MIT

extends "res://addons/sar1_vr_manager/components/vr_component.gd"

const vr_pickup_action_const = preload("res://addons/sar1_vr_manager/components/actions/salvage/vr_interaction_action.gd")

var assign_left_pickup_callable: Callable = Callable(self, "_assign_right_pickup")
var assign_right_pickup_callable: Callable = Callable(self, "_assign_left_pickup")
var can_pickup_callable: Callable = Callable(self, "_can_pickup")


func _can_pickup(p_body: PhysicsBody3D) -> bool:
	if can_pickup_callable.is_valid():
		return can_pickup_callable.call(p_body)
	else:
		return false


func _assign_left_pickup(p_body: PhysicsBody3D) -> bool:
	if assign_left_pickup_callable.is_valid():
		return assign_left_pickup_callable.call(p_body)
	else:
		return false


func _assign_right_pickup(p_body: PhysicsBody3D) -> bool:
	if assign_right_pickup_callable.is_valid():
		return assign_right_pickup_callable.call(p_body)
	else:
		return false


func tracker_added(p_tracker: XRController3D) -> void:
	super.tracker_added(p_tracker)
	var tracker_hand: int = p_tracker.get_tracker_hand()
	if not (tracker_hand == XRPositionalTracker.TRACKER_HAND_LEFT or tracker_hand == XRPositionalTracker.TRACKER_HAND_RIGHT):
		return
	var action: Node3D = vr_pickup_action_const.new()
	action.can_pickup_callable = can_pickup_callable
	if tracker_hand == XRPositionalTracker.TRACKER_HAND_LEFT:
		action.assign_pickup_callable = assign_left_pickup_callable
	else:
		action.assign_pickup_callable = assign_right_pickup_callable
	p_tracker.add_component_action(action)


func tracker_removed(p_tracker: XRController3D) -> void:
	super.tracker_removed(p_tracker)


func _enter_tree():
	set_name("InteractionComponent")
