# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# humanoid_auto_mapper.gd
# SPDX-License-Identifier: MIT

@tool
extends Node

# Unused code

var HIP_NAMES = PackedStringArray(["hips", "hip", "pelvis"])
var SPINE_NAMES = PackedStringArray(["spine"])
var CHEST_NAMES = PackedStringArray(["chest"])
var NECK_NAMES = PackedStringArray(["neck", "collar"])
var HEAD_NAMES = PackedStringArray(["head"])
var EYE_NAMES = PackedStringArray(["eye"])

var UPPER_NAMES = PackedStringArray(["up", "upper"])
var LOWER_NAMES = PackedStringArray(["lower"])

var SHOULDER_NAMES = PackedStringArray(["shoulder", "clavicle"])
var ARM_NAMES = PackedStringArray(["arm"])
var UPPER_ARM_NAMES = PackedStringArray(["upperarm", "uparm", "bicep"])
var LOWER_ARM_NAMES = PackedStringArray(["lowerarm", "forearm", "elbow"])

var LEG_NAMES = PackedStringArray(["leg"])
var UPPER_LEG_NAMES = PackedStringArray(["upleg", "upperleg", "thigh"])
var LOWER_LEG_NAMES = PackedStringArray(["knee", "calf"])

var FOOT_NAMES = PackedStringArray(["foot", "ankle"])
var TOE_NAMES = PackedStringArray(["toe"])

var THUMB_NAMES = PackedStringArray(["thumb"])
var INDEX_FINGER_NAMES = PackedStringArray(["index"])
var MIDDLE_FINGER_NAMES = PackedStringArray(["middle"])
var RING_FINGER_NAMES = PackedStringArray(["ring"])
var PINKY_FINGER_NAMES = PackedStringArray(["pinky"])

var TWIST_BONE_NAME = PackedStringArray(["twist", "roll"])


static func get_sanitisied_bone_name_list(p_skeleton: Skeleton3D) -> PackedStringArray:
	var sanitised_names: PackedStringArray = PackedStringArray()
	for i in range(0, p_skeleton.get_bone_count()):
		sanitised_names.push_back(p_skeleton.get_bone_name(i))

	return sanitised_names


static func get_bone_children_ids(p_skeleton: Skeleton3D, p_id: int, p_children: PackedInt32Array = PackedInt32Array()) -> PackedInt32Array:
	var parent_id: int = p_skeleton.get_bone_parent(p_id)
	if parent_id != -1:
		p_children.push_back(parent_id)
		p_children = get_bone_children_ids(p_skeleton, parent_id, p_children)

	return p_children


class BoneInfo:
	extends RefCounted
	var bone_parent: int = -1
	var bone_name: String = ""
	var bone_length: float = 0.0
	var bone_direction: Vector3 = Vector3()


func gather_bone_info(p_skeleton: Skeleton3D) -> RefCounted:
	var bone_info_list: Array = []

	for i in range(0, p_skeleton.get_bone_count()):
		var bone_info: BoneInfo = BoneInfo.new()

		bone_info.bone_name = p_skeleton.get_bone_name(i)
		bone_info.bone_parent = p_skeleton.get_bone_parent(i)

		if bone_info.bone_parent != -1:
			bone_info.bone_length = p_skeleton.get_bone_rest(i).origin.distance_to(Vector3())
			bone_info.bone_direction = Vector3().direction_to(p_skeleton.get_bone_rest(i).origin)

		bone_info.push_back(bone_info)

	return null
