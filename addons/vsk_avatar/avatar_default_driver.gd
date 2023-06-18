# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# avatar_default_driver.gd
# SPDX-License-Identifier: MIT

extends Node

# Hardcoded nonsense until I figure out the customisable animation tree driver

@export var anim_tree: NodePath = NodePath():
	set = set_anim_tree

var cached_anim_tree: AnimationTree = null

@export var left_hand_gesture_id: int = 0
@export var right_hand_gesture_id: int = 0


func update(p_delta: float) -> void:
	if cached_anim_tree:
		cached_anim_tree.advance(p_delta)


func set_anim_tree(p_path: NodePath) -> void:
	if p_path != anim_tree:
		anim_tree = p_path
		_cache_anim_tree(anim_tree)


func _cache_anim_tree(p_path: NodePath) -> void:
	var node: Node = get_node_or_null(p_path)
	if node is AnimationTree:
		cached_anim_tree = node


func _physics_process(_p_delta: float):
	if cached_anim_tree and cached_anim_tree.tree_root:
		cached_anim_tree["parameters/LeftHandBlend/blend_amount"] = 1.0
		cached_anim_tree["parameters/RightHandBlend/blend_amount"] = 1.0

		cached_anim_tree["parameters/LeftHandStateMachine/conditions/point"] = (true if left_hand_gesture_id == VSKAvatarManager.HAND_POSE_POINT else false)
		cached_anim_tree["parameters/LeftHandStateMachine/conditions/fist"] = (true if left_hand_gesture_id == VSKAvatarManager.HAND_POSE_FIST else false)
		cached_anim_tree["parameters/LeftHandStateMachine/conditions/gun"] = (true if left_hand_gesture_id == VSKAvatarManager.HAND_POSE_GUN else false)
		cached_anim_tree["parameters/LeftHandStateMachine/conditions/neutral"] = (true if left_hand_gesture_id == VSKAvatarManager.HAND_POSE_NEUTRAL else false)
		cached_anim_tree["parameters/LeftHandStateMachine/conditions/ok_sign"] = (true if left_hand_gesture_id == VSKAvatarManager.HAND_POSE_OK_SIGN else false)
		cached_anim_tree["parameters/LeftHandStateMachine/conditions/open"] = (true if left_hand_gesture_id == VSKAvatarManager.HAND_POSE_OPEN else false)
		cached_anim_tree["parameters/LeftHandStateMachine/conditions/victory"] = (true if left_hand_gesture_id == VSKAvatarManager.HAND_POSE_VICTORY else false)
		cached_anim_tree["parameters/LeftHandStateMachine/conditions/thumbs_up"] = (true if left_hand_gesture_id == VSKAvatarManager.HAND_POSE_THUMBS_UP else false)

		cached_anim_tree["parameters/RightHandStateMachine/conditions/point"] = (true if right_hand_gesture_id == VSKAvatarManager.HAND_POSE_POINT else false)
		cached_anim_tree["parameters/RightHandStateMachine/conditions/fist"] = (true if right_hand_gesture_id == VSKAvatarManager.HAND_POSE_FIST else false)
		cached_anim_tree["parameters/RightHandStateMachine/conditions/gun"] = (true if right_hand_gesture_id == VSKAvatarManager.HAND_POSE_GUN else false)
		cached_anim_tree["parameters/RightHandStateMachine/conditions/neutral"] = (true if right_hand_gesture_id == VSKAvatarManager.HAND_POSE_NEUTRAL else false)
		cached_anim_tree["parameters/RightHandStateMachine/conditions/ok_sign"] = (true if right_hand_gesture_id == VSKAvatarManager.HAND_POSE_OK_SIGN else false)
		cached_anim_tree["parameters/RightHandStateMachine/conditions/open"] = (true if right_hand_gesture_id == VSKAvatarManager.HAND_POSE_OPEN else false)
		cached_anim_tree["parameters/RightHandStateMachine/conditions/victory"] = (true if right_hand_gesture_id == VSKAvatarManager.HAND_POSE_VICTORY else false)
		cached_anim_tree["parameters/RightHandStateMachine/conditions/thumbs_up"] = (true if right_hand_gesture_id == VSKAvatarManager.HAND_POSE_THUMBS_UP else false)
	pass


func _ready():
	_cache_anim_tree(anim_tree)
