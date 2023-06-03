# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vr_component_render_tree.gd
# SPDX-License-Identifier: MIT

extends "res://addons/sar1_vr_manager/components/vr_component.gd"  # vr_component.gd

const vr_render_tree_const = preload("../vr_render_tree.gd")
const vr_render_tree_action_const = preload("actions/vr_render_tree_action.gd")

var left_render_tree_action: Node3D = null
var right_render_tree_action: Node3D = null


func tracker_added(p_tracker: XRController3D) -> void:  # vr_controller_tracker_const
	super.tracker_added(p_tracker)

	var tracker_hand: int = p_tracker.get_tracker_hand()
	if tracker_hand != XRPositionalTracker.TRACKER_HAND_LEFT and tracker_hand != XRPositionalTracker.TRACKER_HAND_RIGHT:
		return

	var vr_render_tree_action: Node3D = vr_render_tree_action_const.new()

	# instance our render model object
	var spatial_render_tree: Node3D = VRManager.create_render_tree()
	# hide to begin with
	vr_render_tree_action.visible = false

	var controller_name: String = str(p_tracker.tracker)
	if spatial_render_tree and !spatial_render_tree.load_render_tree(VRManager, controller_name):
		printerr("Could not load render tree")

	vr_render_tree_action.visible = true

	vr_render_tree_action.set_render_tree(spatial_render_tree)
	p_tracker.add_component_action(vr_render_tree_action)

	match tracker_hand:
		XRPositionalTracker.TRACKER_HAND_LEFT:
			if is_instance_valid(left_render_tree_action):
				return
			left_render_tree_action = vr_render_tree_action
		XRPositionalTracker.TRACKER_HAND_RIGHT:
			if is_instance_valid(right_render_tree_action):
				return
			right_render_tree_action = vr_render_tree_action


func tracker_removed(p_tracker: XRController3D) -> void:  # vr_controller_tracker_const
	super.tracker_removed(p_tracker)

	match p_tracker.get_tracker_hand():
		XRPositionalTracker.TRACKER_HAND_LEFT:
			p_tracker.remove_component_action(left_render_tree_action)
			left_render_tree_action = null
		XRPositionalTracker.TRACKER_HAND_RIGHT:
			p_tracker.remove_component_action(right_render_tree_action)
			right_render_tree_action = null


func _enter_tree():
	set_name("RenderTreeComponent")
