# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# avatar_setup.gd
# SPDX-License-Identifier: MIT

extends Node

const hand_pose_const = preload("hand_pose.gd")


static func create_pose_track_for_humanoid_bone(p_animation: Animation, p_base_path: String, p_skeleton: Skeleton3D, p_humanoid_bone_name: String, p_transform: Transform3D) -> Animation:
	if !p_skeleton:
		return p_animation

	var bone_index: int = p_skeleton.find_bone(p_humanoid_bone_name)
	if bone_index == -1:
		return p_animation

	var track_index = p_animation.add_track(Animation.TYPE_ROTATION_3D)
	var bone_name: String = p_skeleton.get_bone_name(bone_index)
	p_animation.track_set_path(track_index, p_base_path + ":" + bone_name)
	p_animation.rotation_track_insert_key(track_index, 0.0, p_transform.basis.get_rotation_quaternion())

	p_animation.track_set_enabled(track_index, true)
	p_animation.track_set_interpolation_type(track_index, Animation.INTERPOLATION_LINEAR)
	p_animation.track_set_interpolation_loop_wrap(track_index, true)

	return p_animation


static func create_animation_from_hand_pose(p_root_node: Node, p_skeleton: Skeleton3D, p_hand_pose: RefCounted) -> Animation:
	var animation: Animation = Animation.new()
	animation.length = 0.001
	for side in ["Left", "Right"]:
		for digit in ["Thumb", "Index", "Middle", "Ring", "Little"]:
			for joint in ["Metacarpal", "Proximal", "Intermediate", "Distal"]:
				if digit == "Thumb" and joint == "Intermediate":
					continue
				if digit != "Thumb" and joint == "Metacarpal":
					continue
				var transform: Transform3D = Transform3D()
				if side == "Left":
					transform = p_hand_pose.get("%s_%s" % [digit, joint])
				else:
					# TODO: clean this up
					var euler: Vector3 = p_hand_pose.get("%s_%s" % [digit, joint]).basis.get_euler()

					euler.z = -euler.z
					euler.y = -euler.y

					transform = Transform3D(Basis.from_euler(euler), Vector3())

				animation = create_pose_track_for_humanoid_bone(animation, p_root_node.get_path_to(p_skeleton), p_skeleton, "%s_%s_%s_bone_name" % [digit, joint, side], transform)
	return animation


static func setup_animation_from_hand_pose(p_animation_player: AnimationPlayer, p_root_node: Node, p_skeleton: Skeleton3D, p_hand_pose_name: String, p_hand_pose: RefCounted) -> void:
	var animation: Animation = create_animation_from_hand_pose(p_root_node, p_skeleton, p_hand_pose)
	var animation_library: AnimationLibrary = AnimationLibrary.new()
	animation_library.add_animation(p_hand_pose_name, animation)
	p_animation_player.add_animation_library("", animation_library)


static func setup_animation_from_hand_pose_dictionary(p_animation_player: AnimationPlayer, p_root_node: Node, p_skeleton: Skeleton3D, p_pose_dictionary: Dictionary) -> void:
	for key in p_pose_dictionary:
		setup_animation_from_hand_pose(p_animation_player, p_root_node, p_skeleton, key, p_pose_dictionary[key])


static func setup_default_hand_animations(p_animation_player: AnimationPlayer, p_root_node: Node, p_skeleton: Skeleton3D) -> AnimationPlayer:
	# Hand Animation
	var hand_pose_default_const = load("res://addons/vsk_avatar/hand_poses/hand_pose_default_pose.tres")
	var hand_pose_fist_const = load("res://addons/vsk_avatar/hand_poses/hand_pose_fist.tres")
	var hand_pose_gun_const = load("res://addons/vsk_avatar/hand_poses/hand_pose_gun.tres")
	var hand_pose_neutral_const = load("res://addons/vsk_avatar/hand_poses/hand_pose_neutral.tres")
	var hand_pose_ok_sign_const = load("res://addons/vsk_avatar/hand_poses/hand_pose_ok_sign.tres")
	var hand_pose_open_const = load("res://addons/vsk_avatar/hand_poses/hand_pose_open.tres")
	var hand_pose_point_const = load("res://addons/vsk_avatar/hand_poses/hand_pose_point.tres")
	var hand_pose_thumbs_up_const = load("res://addons/vsk_avatar/hand_poses/hand_pose_thumbs_up.tres")
	var hand_pose_victory_const = load("res://addons/vsk_avatar/hand_poses/hand_pose_victory.tres")

	setup_animation_from_hand_pose_dictionary(p_animation_player, p_root_node, p_skeleton, {"DefaultPose": hand_pose_default_const, "Neutral": hand_pose_neutral_const, "Fist": hand_pose_fist_const, "Point": hand_pose_point_const, "Gun": hand_pose_gun_const, "OKSign": hand_pose_ok_sign_const, "ThumbsUp": hand_pose_thumbs_up_const, "Victory": hand_pose_victory_const, "Open": hand_pose_open_const})

	return p_animation_player


static func setup_animation_tree_hand_blend_tree(p_animation_tree: AnimationTree, p_animation_player: AnimationPlayer, p_skeleton: Skeleton3D) -> AnimationTree:
	var default_avatar_tree_const = load("res://addons/vsk_avatar/animation/default_avatar_tree.tres")

	if !p_skeleton:
		return p_animation_tree

	p_animation_tree.anim_player = p_animation_tree.get_path_to(p_animation_player)
	p_animation_tree.tree_root = default_avatar_tree_const
	p_animation_tree.process_mode = Node.PROCESS_MODE_DISABLED
	p_animation_tree.active = true

	var left_hand_blend: AnimationNode = p_animation_tree.tree_root.get_node("LeftHandBlend")
	var right_hand_blend: AnimationNode = p_animation_tree.tree_root.get_node("RightHandBlend")

	left_hand_blend.filter_enabled = true
	right_hand_blend.filter_enabled = true

	var base_path: String = "%GeneralSkeleton"

	for digit in ["Thumb", "Index", "Middle", "Ring", "Little"]:
		for joint in ["Metacarpal", "Proximal", "Intermediate", "Distal"]:
			if digit == "Thumb" and joint == "Intermediate":
				continue
			if digit != "Thumb" and joint == "Metacarpal":
				continue
			# Left
			var left_bone_name: String = "Left%s%s" % [digit, joint]
			var left_bone_index: int = p_skeleton.find_bone(left_bone_name)
			if left_bone_index != -1:
				var filter_path: String = base_path + ":" + left_bone_name
				left_hand_blend.set_filter_path(filter_path, true)
			# Right
			var right_bone_name: String = "Right%s%s" % [digit, joint]
			var right_bone_index: int = p_skeleton.find_bone(right_bone_name)
			if right_bone_index != -1:
				var filter_path: String = base_path + ":" + right_bone_name
				right_hand_blend.set_filter_path(filter_path, true)

	return p_animation_tree
