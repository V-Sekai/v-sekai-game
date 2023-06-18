# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vr_component_teleport.gd
# SPDX-License-Identifier: MIT

extends "res://addons/sar1_vr_manager/components/vr_component.gd"  # vr_component.gd

var vr_teleport_action_const = load("res://addons/sar1_vr_manager/components/actions/vr_teleport_action.tscn")

var can_teleport_funcref: Callable = Callable()
var teleport_callback_funcref: Callable = Callable()


func _teleported(p_transform: Transform3D) -> void:
	if teleport_callback_funcref.is_valid():
		teleport_callback_funcref.call(p_transform)


func _can_teleport() -> bool:
	if can_teleport_funcref.is_valid():
		return can_teleport_funcref.call()

	return false


func tracker_added(p_tracker: XRController3D) -> void:  # vr_controller_tracker_const
	print("Component teleport: tracker_added")
	super.tracker_added(p_tracker)

	var tracker_hand: int = p_tracker.get_tracker_hand()
	if tracker_hand == XRPositionalTracker.TRACKER_HAND_LEFT or tracker_hand == XRPositionalTracker.TRACKER_HAND_RIGHT:
		var action: Node3D = vr_teleport_action_const.instantiate()

		### Assign callsbacks ###
		action.set_can_teleport_funcref(self, "_can_teleport")
		if action.teleported.connect(self._teleported) != OK:
			printerr("Could not connect teleported signal!")
		###

		p_tracker.add_component_action(action)


func tracker_removed(p_tracker: XRController3D) -> void:  # vr_controller_tracker_const
	super.tracker_removed(p_tracker)


func assign_teleport_callback_funcref(p_instance: Object, p_function: String) -> void:
	teleport_callback_funcref = Callable(p_instance, p_function)


func assign_can_teleport_funcref(p_instance: Object, p_function: String) -> void:
	can_teleport_funcref = Callable(p_instance, p_function)


func _enter_tree():
	set_name("TeleportComponent")
