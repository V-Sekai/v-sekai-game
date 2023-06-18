# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# avatar_constants.gd
# SPDX-License-Identifier: MIT

@tool
extends RefCounted

const LEFT_SIDE_NAME = "left"
const RIGHT_SIDE_NAME = "right"

const THUMB_NAME = "Thumb"
const INDEX_NAME = "Index"
const MIDDLE_NAME = "Middle"
const RING_NAME = "Ring"
const LITTLE_NAME = "Little"

const METACARPAL_NAME = "Proximal"
const PROXIMAL_NAME = "Proximal"
const INTERMEDIATE_NAME = "Intermediate"
const DISTAL_NAME = "Distal"

const digit_names: PackedStringArray = [THUMB_NAME, INDEX_NAME, MIDDLE_NAME, RING_NAME, LITTLE_NAME]
const digit_joint_names: PackedStringArray = [METACARPAL_NAME, PROXIMAL_NAME, INTERMEDIATE_NAME, DISTAL_NAME]

enum { DIGIT_JOINT_METACARPAL, DIGIT_JOINT_PROXIMAL, DIGIT_JOINT_INTERMEDIATE, DIGIT_JOINT_DISTAL }

enum { DIGIT_THUMB, DIGIT_INDEX, DIGIT_MIDDLE, DIGIT_RING, DIGIT_LITTLE }

enum { SIDE_LEFT, SIDE_RIGHT, SIDE_CENTER }


static func get_name_for_digit_joint(p_digit_joint: int) -> String:
	match p_digit_joint:
		DIGIT_JOINT_PROXIMAL:
			return PROXIMAL_NAME
		DIGIT_JOINT_INTERMEDIATE:
			return INTERMEDIATE_NAME  # not on thumb
		DIGIT_JOINT_DISTAL:
			return DISTAL_NAME
		DIGIT_JOINT_METACARPAL:
			return METACARPAL_NAME  # thumb
	return ""


static func get_name_for_digit(p_digit: int) -> String:
	match p_digit:
		DIGIT_THUMB:
			return THUMB_NAME
		DIGIT_INDEX:
			return INDEX_NAME
		DIGIT_MIDDLE:
			return MIDDLE_NAME
		DIGIT_RING:
			return RING_NAME
		DIGIT_LITTLE:
			return LITTLE_NAME
	return ""


static func get_name_for_side(p_side: int) -> String:
	match p_side:
		SIDE_LEFT:
			return LEFT_SIDE_NAME
		SIDE_RIGHT:
			return RIGHT_SIDE_NAME
		_:
			return ""
