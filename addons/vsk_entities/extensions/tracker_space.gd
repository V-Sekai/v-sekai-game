# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# tracker_space.gd
# SPDX-License-Identifier: MIT

extends Node3D

@export_category("Player XROrigin")
@export var xr_origin: XROrigin3D = null

@export_category("Sync Nodes")
@export var synced_head_tracker: Node3D = null
@export var synced_left_tracker: Node3D = null
@export var synced_right_tracker: Node3D = null

func _update_local_tracker(p_xr_node: XRNode3D, p_synced_node: Node3D) -> void:
	if p_synced_node:
		if p_xr_node:
			p_synced_node.show()
			p_synced_node.transform = transform.affine_inverse() * (xr_origin.transform * p_xr_node.transform)
		else:
			p_synced_node.hide()
			
func _process(_delta: float) -> void:
	if xr_origin:
		if is_multiplayer_authority():
			transform = Transform3D(Basis(), (xr_origin.transform * xr_origin.xr_camera.transform).origin)
			if synced_head_tracker:
				synced_head_tracker.transform = Transform3D(xr_origin.xr_camera.basis, Vector3())
			
			# Update Hands
			_update_local_tracker(xr_origin.left_hand_controller, synced_left_tracker)
			_update_local_tracker(xr_origin.right_hand_controller, synced_right_tracker)

func _ready() -> void:
	# Check if the PlayerXROrigin is a sibling of this node.
	assert(xr_origin.get_parent() == get_parent())
