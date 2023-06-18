# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# humanoid_data.gd
# SPDX-License-Identifier: MIT

@tool
class_name HumanoidData extends Resource

var _skeleton_node: Skeleton3D = null

enum { head, neck, shoulder_left, upper_arm_left, forearm_left, hand_left, shoulder_right, upper_arm_right, forearm_right, hand_right, upper_chest, chest, spine, hips, thigh_left, shin_left, foot_left, toe_left, thigh_right, shin_right, foot_right, toe_right, thumb_proximal_left, thumb_intermediate_left, thumb_distal_left, thumb_proximal_right, thumb_intermediate_right, thumb_distal_right, index_proximal_left, index_intermediate_left, index_distal_left, index_proximal_right, index_intermediate_right, index_distal_right, middle_proximal_left, middle_intermediate_left, middle_distal_left, middle_proximal_right, middle_intermediate_right, middle_distal_right, ring_proximal_left, ring_intermediate_left, ring_distal_left, ring_proximal_right, ring_intermediate_right, ring_distal_right, little_proximal_left, little_intermediate_left, little_distal_left, little_proximal_right, little_intermediate_right, little_distal_right, eye_left, eye_right, jaw }

const skeleton_mappings = ["head", "neck", "shoulder_left", "upper_arm_left", "forearm_left", "hand_left", "shoulder_right", "upper_arm_right", "forearm_right", "hand_right", "upper_chest", "chest", "spine", "hips", "thigh_left", "shin_left", "foot_left", "toe_left", "thigh_right", "shin_right", "foot_right", "toe_right", "thumb_proximal_left", "thumb_intermediate_left", "thumb_distal_left", "thumb_proximal_right", "thumb_intermediate_right", "thumb_distal_right", "index_proximal_left", "index_intermediate_left", "index_distal_left", "index_proximal_right", "index_intermediate_right", "index_distal_right", "middle_proximal_left", "middle_intermediate_left", "middle_distal_left", "middle_proximal_right", "middle_intermediate_right", "middle_distal_right", "ring_proximal_left", "ring_intermediate_left", "ring_distal_left", "ring_proximal_right", "ring_intermediate_right", "ring_distal_right", "little_proximal_left", "little_intermediate_left", "little_distal_left", "little_proximal_right", "little_intermediate_right", "little_distal_right", "eye_left", "eye_right", "jaw"]

# Head
var head_bone_name: String = ""
# Neck
var neck_bone_name: String = ""
# Left Arm
var shoulder_left_bone_name: String = ""
var upper_arm_left_bone_name: String = ""
var forearm_left_bone_name: String = ""
var hand_left_bone_name: String = ""
# Right Arm
var shoulder_right_bone_name: String = ""
var upper_arm_right_bone_name: String = ""
var forearm_right_bone_name: String = ""
var hand_right_bone_name: String = ""
# Spline
var upper_chest_bone_name: String = ""
var chest_bone_name: String = ""
var spine_bone_name: String = ""
# Hips
var hips_bone_name: String = ""
# Left Leg
var thigh_left_bone_name: String = ""
var shin_left_bone_name: String = ""
var foot_left_bone_name: String = ""
var toe_left_bone_name: String = ""
# Right Leg
var thigh_right_bone_name: String = ""
var shin_right_bone_name: String = ""
var foot_right_bone_name: String = ""
var toe_right_bone_name: String = ""

#Left Hand
var thumb_proximal_left_bone_name: String = ""
var thumb_intermediate_left_bone_name: String = ""
var thumb_distal_left_bone_name: String = ""

var index_proximal_left_bone_name: String = ""
var index_intermediate_left_bone_name: String = ""
var index_distal_left_bone_name: String = ""

var middle_proximal_left_bone_name: String = ""
var middle_intermediate_left_bone_name: String = ""
var middle_distal_left_bone_name: String = ""

var ring_proximal_left_bone_name: String = ""
var ring_intermediate_left_bone_name: String = ""
var ring_distal_left_bone_name: String = ""

var little_proximal_left_bone_name: String = ""
var little_intermediate_left_bone_name: String = ""
var little_distal_left_bone_name: String = ""

#Right Hand
var thumb_proximal_right_bone_name: String = ""
var thumb_intermediate_right_bone_name: String = ""
var thumb_distal_right_bone_name: String = ""

var index_proximal_right_bone_name: String = ""
var index_intermediate_right_bone_name: String = ""
var index_distal_right_bone_name: String = ""

var middle_proximal_right_bone_name: String = ""
var middle_intermediate_right_bone_name: String = ""
var middle_distal_right_bone_name: String = ""

var ring_proximal_right_bone_name: String = ""
var ring_intermediate_right_bone_name: String = ""
var ring_distal_right_bone_name: String = ""

var little_proximal_right_bone_name: String = ""
var little_intermediate_right_bone_name: String = ""
var little_distal_right_bone_name: String = ""

var eye_left_bone_name: String = ""
var eye_right_bone_name: String = ""
var jaw_bone_name: String = ""


func get_skeleton_bone_name(p_humanoid_bone_id: int) -> String:
	match p_humanoid_bone_id:
		head:
			return head_bone_name
		neck:
			return neck_bone_name
		shoulder_left:
			return shoulder_left_bone_name
		upper_arm_left:
			return upper_arm_left_bone_name
		forearm_left:
			return forearm_left_bone_name
		hand_left:
			return hand_left_bone_name
		shoulder_right:
			return shoulder_right_bone_name
		upper_arm_right:
			return upper_arm_right_bone_name
		forearm_right:
			return forearm_right_bone_name
		hand_right:
			return hand_right_bone_name
		upper_chest:
			return upper_chest_bone_name
		chest:
			return chest_bone_name
		spine:
			return spine_bone_name
		hips:
			return hips_bone_name
		thigh_left:
			return thigh_left_bone_name
		shin_left:
			return shin_left_bone_name
		foot_left:
			return foot_left_bone_name
		toe_left:
			return toe_left_bone_name
		thigh_right:
			return thigh_right_bone_name
		shin_right:
			return shin_right_bone_name
		foot_right:
			return foot_right_bone_name
		toe_right:
			return toe_right_bone_name
		thumb_proximal_left:
			return thumb_proximal_left_bone_name
		thumb_intermediate_left:
			return thumb_intermediate_left_bone_name
		thumb_distal_left:
			return thumb_distal_left_bone_name
		thumb_proximal_right:
			return thumb_proximal_right_bone_name
		thumb_intermediate_right:
			return thumb_intermediate_right_bone_name
		thumb_distal_right:
			return thumb_distal_right_bone_name
		index_proximal_left:
			return index_proximal_left_bone_name
		index_intermediate_left:
			return index_intermediate_left_bone_name
		index_distal_left:
			return index_distal_left_bone_name
		index_proximal_right:
			return index_proximal_right_bone_name
		index_intermediate_right:
			return index_intermediate_right_bone_name
		index_distal_right:
			return index_distal_right_bone_name
		middle_proximal_left:
			return middle_proximal_left_bone_name
		middle_intermediate_left:
			return middle_intermediate_left_bone_name
		middle_distal_left:
			return middle_distal_left_bone_name
		middle_proximal_right:
			return middle_proximal_right_bone_name
		middle_intermediate_right:
			return middle_intermediate_right_bone_name
		middle_distal_right:
			return middle_distal_right_bone_name
		ring_proximal_left:
			return ring_proximal_left_bone_name
		ring_intermediate_left:
			return ring_intermediate_left_bone_name
		ring_distal_left:
			return ring_distal_left_bone_name
		ring_proximal_right:
			return ring_proximal_right_bone_name
		ring_intermediate_right:
			return ring_intermediate_right_bone_name
		ring_distal_right:
			return ring_distal_right_bone_name
		little_proximal_left:
			return little_proximal_left_bone_name
		little_intermediate_left:
			return little_intermediate_left_bone_name
		little_distal_left:
			return little_distal_left_bone_name
		little_proximal_right:
			return little_proximal_right_bone_name
		little_intermediate_right:
			return little_intermediate_right_bone_name
		little_distal_right:
			return little_distal_right_bone_name
		eye_left:
			return eye_left_bone_name
		eye_right:
			return eye_right_bone_name
		jaw:
			return jaw_bone_name
		_:
			printerr("Invald index")
			return ""


func find_skeleton_bone_for_humanoid_bone(p_skeleton: Skeleton3D, p_humanoid_id: int) -> int:
	return p_skeleton.find_bone(get_skeleton_bone_name(p_humanoid_id))


func is_skeleton_bone_empty(p_humanoid_bone_id: int) -> bool:
	if not get_skeleton_bone_name(p_humanoid_bone_id).is_empty():
		return true
	else:
		return false


func _validate_bone_name_property(p_property: Dictionary, p_hintstring: String) -> Dictionary:
	if _skeleton_node:
		p_property["hint"] = PROPERTY_HINT_ENUM
		p_property["hint_string"] = p_hintstring
	else:
		p_property["hint"] = PROPERTY_HINT_NONE

	return p_property


func _get_property_list() -> Array:
	var property_list: Array = []

	var names: String = ""
	if _skeleton_node:
		for i in range(0, _skeleton_node.get_bone_count()):
			if i > 0:
				names += ","
			names += _skeleton_node.get_bone_name(i)

	property_list.push_back(_validate_bone_name_property({"name": "head_bone_name", "type": TYPE_STRING, "hint": PROPERTY_HINT_NONE}, names))

	property_list.push_back(_validate_bone_name_property({"name": "neck_bone_name", "type": TYPE_STRING, "hint": PROPERTY_HINT_NONE}, names))

	property_list.push_back(_validate_bone_name_property({"name": "shoulder_left_bone_name", "type": TYPE_STRING, "hint": PROPERTY_HINT_NONE}, names))
	property_list.push_back(_validate_bone_name_property({"name": "upper_arm_left_bone_name", "type": TYPE_STRING, "hint": PROPERTY_HINT_NONE}, names))
	property_list.push_back(_validate_bone_name_property({"name": "forearm_left_bone_name", "type": TYPE_STRING, "hint": PROPERTY_HINT_NONE}, names))
	property_list.push_back(_validate_bone_name_property({"name": "hand_left_bone_name", "type": TYPE_STRING, "hint": PROPERTY_HINT_NONE}, names))

	property_list.push_back(_validate_bone_name_property({"name": "shoulder_right_bone_name", "type": TYPE_STRING, "hint": PROPERTY_HINT_NONE}, names))
	property_list.push_back(_validate_bone_name_property({"name": "upper_arm_right_bone_name", "type": TYPE_STRING, "hint": PROPERTY_HINT_NONE}, names))
	property_list.push_back(_validate_bone_name_property({"name": "forearm_right_bone_name", "type": TYPE_STRING, "hint": PROPERTY_HINT_NONE}, names))
	property_list.push_back(_validate_bone_name_property({"name": "hand_right_bone_name", "type": TYPE_STRING, "hint": PROPERTY_HINT_NONE}, names))

	property_list.push_back(_validate_bone_name_property({"name": "spine_bone_name", "type": TYPE_STRING, "hint": PROPERTY_HINT_NONE}, names))
	property_list.push_back(_validate_bone_name_property({"name": "chest_bone_name", "type": TYPE_STRING, "hint": PROPERTY_HINT_NONE}, names))
	property_list.push_back(_validate_bone_name_property({"name": "upper_chest_bone_name", "type": TYPE_STRING, "hint": PROPERTY_HINT_NONE}, names))

	property_list.push_back(_validate_bone_name_property({"name": "hips_bone_name", "type": TYPE_STRING, "hint": PROPERTY_HINT_NONE}, names))

	property_list.push_back(_validate_bone_name_property({"name": "thigh_left_bone_name", "type": TYPE_STRING, "hint": PROPERTY_HINT_NONE}, names))
	property_list.push_back(_validate_bone_name_property({"name": "shin_left_bone_name", "type": TYPE_STRING, "hint": PROPERTY_HINT_NONE}, names))
	property_list.push_back(_validate_bone_name_property({"name": "foot_left_bone_name", "type": TYPE_STRING, "hint": PROPERTY_HINT_NONE}, names))
	property_list.push_back(_validate_bone_name_property({"name": "toe_left_bone_name", "type": TYPE_STRING, "hint": PROPERTY_HINT_NONE}, names))

	property_list.push_back(_validate_bone_name_property({"name": "thigh_right_bone_name", "type": TYPE_STRING, "hint": PROPERTY_HINT_NONE}, names))
	property_list.push_back(_validate_bone_name_property({"name": "shin_right_bone_name", "type": TYPE_STRING, "hint": PROPERTY_HINT_NONE}, names))
	property_list.push_back(_validate_bone_name_property({"name": "foot_right_bone_name", "type": TYPE_STRING, "hint": PROPERTY_HINT_NONE}, names))
	property_list.push_back(_validate_bone_name_property({"name": "toe_right_bone_name", "type": TYPE_STRING, "hint": PROPERTY_HINT_NONE}, names))

	property_list.push_back(_validate_bone_name_property({"name": "thumb_proximal_left_bone_name", "type": TYPE_STRING, "hint": PROPERTY_HINT_NONE}, names))
	property_list.push_back(_validate_bone_name_property({"name": "thumb_intermediate_left_bone_name", "type": TYPE_STRING, "hint": PROPERTY_HINT_NONE}, names))
	property_list.push_back(_validate_bone_name_property({"name": "thumb_distal_left_bone_name", "type": TYPE_STRING, "hint": PROPERTY_HINT_NONE}, names))

	property_list.push_back(_validate_bone_name_property({"name": "index_proximal_left_bone_name", "type": TYPE_STRING, "hint": PROPERTY_HINT_NONE}, names))
	property_list.push_back(_validate_bone_name_property({"name": "index_intermediate_left_bone_name", "type": TYPE_STRING, "hint": PROPERTY_HINT_NONE}, names))
	property_list.push_back(_validate_bone_name_property({"name": "index_distal_left_bone_name", "type": TYPE_STRING, "hint": PROPERTY_HINT_NONE}, names))

	property_list.push_back(_validate_bone_name_property({"name": "middle_proximal_left_bone_name", "type": TYPE_STRING, "hint": PROPERTY_HINT_NONE}, names))
	property_list.push_back(_validate_bone_name_property({"name": "middle_intermediate_left_bone_name", "type": TYPE_STRING, "hint": PROPERTY_HINT_NONE}, names))
	property_list.push_back(_validate_bone_name_property({"name": "middle_distal_left_bone_name", "type": TYPE_STRING, "hint": PROPERTY_HINT_NONE}, names))

	property_list.push_back(_validate_bone_name_property({"name": "ring_proximal_left_bone_name", "type": TYPE_STRING, "hint": PROPERTY_HINT_NONE}, names))
	property_list.push_back(_validate_bone_name_property({"name": "ring_intermediate_left_bone_name", "type": TYPE_STRING, "hint": PROPERTY_HINT_NONE}, names))
	property_list.push_back(_validate_bone_name_property({"name": "ring_distal_left_bone_name", "type": TYPE_STRING, "hint": PROPERTY_HINT_NONE}, names))

	property_list.push_back(_validate_bone_name_property({"name": "little_proximal_left_bone_name", "type": TYPE_STRING, "hint": PROPERTY_HINT_NONE}, names))
	property_list.push_back(_validate_bone_name_property({"name": "little_intermediate_left_bone_name", "type": TYPE_STRING, "hint": PROPERTY_HINT_NONE}, names))
	property_list.push_back(_validate_bone_name_property({"name": "little_distal_left_bone_name", "type": TYPE_STRING, "hint": PROPERTY_HINT_NONE}, names))

	property_list.push_back(_validate_bone_name_property({"name": "thumb_proximal_right_bone_name", "type": TYPE_STRING, "hint": PROPERTY_HINT_NONE}, names))
	property_list.push_back(_validate_bone_name_property({"name": "thumb_intermediate_right_bone_name", "type": TYPE_STRING, "hint": PROPERTY_HINT_NONE}, names))
	property_list.push_back(_validate_bone_name_property({"name": "thumb_distal_right_bone_name", "type": TYPE_STRING, "hint": PROPERTY_HINT_NONE}, names))

	property_list.push_back(_validate_bone_name_property({"name": "index_proximal_right_bone_name", "type": TYPE_STRING, "hint": PROPERTY_HINT_NONE}, names))
	property_list.push_back(_validate_bone_name_property({"name": "index_intermediate_right_bone_name", "type": TYPE_STRING, "hint": PROPERTY_HINT_NONE}, names))
	property_list.push_back(_validate_bone_name_property({"name": "index_distal_right_bone_name", "type": TYPE_STRING, "hint": PROPERTY_HINT_NONE}, names))

	property_list.push_back(_validate_bone_name_property({"name": "middle_proximal_right_bone_name", "type": TYPE_STRING, "hint": PROPERTY_HINT_NONE}, names))
	property_list.push_back(_validate_bone_name_property({"name": "middle_intermediate_right_bone_name", "type": TYPE_STRING, "hint": PROPERTY_HINT_NONE}, names))
	property_list.push_back(_validate_bone_name_property({"name": "middle_distal_right_bone_name", "type": TYPE_STRING, "hint": PROPERTY_HINT_NONE}, names))

	property_list.push_back(_validate_bone_name_property({"name": "ring_proximal_right_bone_name", "type": TYPE_STRING, "hint": PROPERTY_HINT_NONE}, names))
	property_list.push_back(_validate_bone_name_property({"name": "ring_intermediate_right_bone_name", "type": TYPE_STRING, "hint": PROPERTY_HINT_NONE}, names))
	property_list.push_back(_validate_bone_name_property({"name": "ring_distal_right_bone_name", "type": TYPE_STRING, "hint": PROPERTY_HINT_NONE}, names))

	property_list.push_back(_validate_bone_name_property({"name": "little_proximal_right_bone_name", "type": TYPE_STRING, "hint": PROPERTY_HINT_NONE}, names))
	property_list.push_back(_validate_bone_name_property({"name": "little_intermediate_right_bone_name", "type": TYPE_STRING, "hint": PROPERTY_HINT_NONE}, names))
	property_list.push_back(_validate_bone_name_property({"name": "little_distal_right_bone_name", "type": TYPE_STRING, "hint": PROPERTY_HINT_NONE}, names))

	property_list.push_back(_validate_bone_name_property({"name": "eye_left_bone_name", "type": TYPE_STRING, "hint": PROPERTY_HINT_NONE}, names))
	property_list.push_back(_validate_bone_name_property({"name": "eye_right_bone_name", "type": TYPE_STRING, "hint": PROPERTY_HINT_NONE}, names))
	property_list.push_back(_validate_bone_name_property({"name": "jaw_bone_name", "type": TYPE_STRING, "hint": PROPERTY_HINT_NONE}, names))

	return property_list
