# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# hand_pose_extractor.gd
# SPDX-License-Identifier: MIT

extends Node


static func get_transform_for_humanoid_bone(p_skeleton: Skeleton3D, p_humanoid_bone_name: String) -> Transform3D:
	var bone_id: int = p_skeleton.find_bone(p_humanoid_bone_name)
	if bone_id != -1:
		return p_skeleton.get_bone_pose(bone_id)

	return Transform3D()


static func generate_hand_pose_from_skeleton(p_skeleton: Skeleton3D, p_right_hand: bool) -> Animation:
	var hand_pose_dict: Dictionary = {}

	var hand_prefix = "Right" if p_right_hand else "Left"
	hand_pose_dict["ThumbMetacarpal"] = get_transform_for_humanoid_bone(p_skeleton, hand_prefix + "ThumbMetacarpal")
	hand_pose_dict["ThumbProximal"] = get_transform_for_humanoid_bone(p_skeleton, hand_prefix + "ThumbProximal")
	hand_pose_dict["ThumbDistal"] = get_transform_for_humanoid_bone(p_skeleton, hand_prefix + "ThumbDistal")

	hand_pose_dict["IndexProximal"] = get_transform_for_humanoid_bone(p_skeleton, hand_prefix + "IndexProximal")
	hand_pose_dict["IndexIntermediate"] = get_transform_for_humanoid_bone(p_skeleton, hand_prefix + "IndexIntermediate")
	hand_pose_dict["IndexDistal"] = get_transform_for_humanoid_bone(p_skeleton, hand_prefix + "IndexDistal")

	hand_pose_dict["MiddleProximal"] = get_transform_for_humanoid_bone(p_skeleton, hand_prefix + "MiddleProximal")
	hand_pose_dict["MiddleIntermediate"] = get_transform_for_humanoid_bone(p_skeleton, hand_prefix + "MiddleIntermediate")
	hand_pose_dict["MiddleDistal"] = get_transform_for_humanoid_bone(p_skeleton, hand_prefix + "MiddleDistal")

	hand_pose_dict["RingProximal"] = get_transform_for_humanoid_bone(p_skeleton, hand_prefix + "RingProximal")
	hand_pose_dict["RingIntermediate"] = get_transform_for_humanoid_bone(p_skeleton, hand_prefix + "RingIntermediate")
	hand_pose_dict["RingDistal"] = get_transform_for_humanoid_bone(p_skeleton, hand_prefix + "RingDistal")

	hand_pose_dict["LittleProximal"] = get_transform_for_humanoid_bone(p_skeleton, hand_prefix + "LittleProximal")
	hand_pose_dict["LittleIntermediate"] = get_transform_for_humanoid_bone(p_skeleton, hand_prefix + "LittleIntermediate")
	hand_pose_dict["LittleDistal"] = get_transform_for_humanoid_bone(p_skeleton, hand_prefix + "LittleDistal")

	var hand_pose_anim: Animation = Animation.new()
	for finger_bone in hand_pose_dict:
		for this_hand_prefix in ["Left", "Right"]:
			var quat: Quaternion = hand_pose_dict[finger_bone]
			var euler: Vector3 = quat.get_euler()
			if this_hand_prefix == "Right":
				euler.z = -euler.z
				euler.y = -euler.y
			var track = hand_pose_anim.add_track(Animation.TYPE_ROTATION_3D)
			hand_pose_anim.track_set_path(track, NodePath("%GeneralSkeleton:" + this_hand_prefix + finger_bone))
			hand_pose_anim.rotation_track_insert_key(track, 0.0, Quaternion.from_euler(euler))

	return hand_pose_anim
