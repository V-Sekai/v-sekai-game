# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# avatar_callback.gd
# SPDX-License-Identifier: MIT

@tool
extends RefCounted

enum {
	AVATAR_OK,
	AVATAR_FAILED,
	AVATAR_COULD_NOT_CREATE_POINTS,
	ROOT_IS_NULL,
	SKELETON_IS_NULL,
	SKELETON_ZERO_BONES,
	ROOT_NOT_PARENT_OF_SKELETON,
	ROOT_NOT_PARENT_OF_VISEME_MESH,
	NO_MUSCLE_DATA,
	SKIN_MESH_INSTANCE_SIZE_MISMATCH,
	AVATAR_COULD_NOT_SANITISE,
	AVATAR_SPINE_ROOT_MISSING,
	AVATAR_SPINE_TIP_MISSING,
	AVATAR_SPINE_BONES_MISORDERED,
	AVATAR_NECK_ROOT_MISSING,
	AVATAR_NECK_TIP_MISSING,
	AVATAR_NECK_BONES_MISORDERED,
	AVATAR_ARM_LEFT_ROOT_MISSING,
	AVATAR_ARM_LEFT_TIP_MISSING,
	AVATAR_ARM_LEFT_BONES_MISORDERED,
	AVATAR_ARM_RIGHT_ROOT_MISSING,
	AVATAR_ARM_RIGHT_TIP_MISSING,
	AVATAR_ARM_RIGHT_BONES_MISORDERED,
	AVATAR_LEG_LEFT_ROOT_MISSING,
	AVATAR_LEG_LEFT_TIP_MISSING,
	AVATAR_LEG_LEFT_BONES_MISORDERED,
	AVATAR_LEG_RIGHT_ROOT_MISSING,
	AVATAR_LEG_RIGHT_TIP_MISSING,
	AVATAR_LEG_RIGHT_BONES_MISORDERED,
	AVATAR_COULD_NOT_EXPORT_HANDS,
	EXPORTER_NOT_LOADED,
}


static func get_error_str(p_err: int) -> String:
	var error_str: String = "Unknown error!"
	match p_err:
		AVATAR_FAILED:
			error_str = "Generic avatar error! (complain to Saracen)"
		AVATAR_COULD_NOT_CREATE_POINTS:
			error_str = "Could not create points required for IK remapping! (Probably missing humanoid data)"
		ROOT_IS_NULL:
			error_str = "Root node is null!"
		SKELETON_IS_NULL:
			error_str = "Humanoid avatar requires a skeleton to be assigned!"
		ROOT_NOT_PARENT_OF_SKELETON:
			error_str = "Skeleton3D is not a child of the root node!"
		ROOT_NOT_PARENT_OF_VISEME_MESH:
			error_str = "Viseme mesh is not a child of the root node!"
		NO_MUSCLE_DATA:
			error_str = "Humanoid avatars require MuscleData resource!"
		SKIN_MESH_INSTANCE_SIZE_MISMATCH:
			error_str = "The number of Skin resources do not match the number of MeshInstance3Ds!"
		AVATAR_COULD_NOT_SANITISE:
			error_str = "Could not remove forbidden nodes in avatar!"

		AVATAR_SPINE_ROOT_MISSING:
			error_str = "Spine root missing!"
		AVATAR_SPINE_TIP_MISSING:
			error_str = "Spine tip missing!"
		AVATAR_SPINE_BONES_MISORDERED:
			error_str = "Spine chain misordered!"

		AVATAR_NECK_ROOT_MISSING:
			error_str = "Neck root missing!"
		AVATAR_NECK_TIP_MISSING:
			error_str = "Neck tip missing!"
		AVATAR_NECK_BONES_MISORDERED:
			error_str = "Neck chain misordered!"

		AVATAR_ARM_LEFT_ROOT_MISSING:
			error_str = "Arm Left root missing!"
		AVATAR_ARM_LEFT_TIP_MISSING:
			error_str = "Arm Left tip missing!"
		AVATAR_ARM_LEFT_BONES_MISORDERED:
			error_str = "Arm Left chain misordered!"

		AVATAR_ARM_RIGHT_ROOT_MISSING:
			error_str = "Arm Right root missing!"
		AVATAR_ARM_RIGHT_TIP_MISSING:
			error_str = "Arm Right tip missing!"
		AVATAR_ARM_RIGHT_BONES_MISORDERED:
			error_str = "Arm Right chain misordered!"

		AVATAR_LEG_LEFT_ROOT_MISSING:
			error_str = "Leg Left root missing!"
		AVATAR_LEG_LEFT_TIP_MISSING:
			error_str = "Leg Left tip missing!"
		AVATAR_LEG_LEFT_BONES_MISORDERED:
			error_str = "Leg Left chain misordered!"

		AVATAR_LEG_RIGHT_ROOT_MISSING:
			error_str = "Leg Right root missing!"
		AVATAR_LEG_RIGHT_TIP_MISSING:
			error_str = "Leg Right tip missing!"
		AVATAR_LEG_RIGHT_BONES_MISORDERED:
			error_str = "Leg Right chain misordered!"
		AVATAR_COULD_NOT_EXPORT_HANDS:
			error_str = "Could not export hands!"

		EXPORTER_NOT_LOADED:
			error_str = "Exporter not loaded!"

	return error_str


static func generic_error_check(p_root: Node3D, p_skeleton: Skeleton3D) -> int:
	if p_root == null:
		return ROOT_IS_NULL

	if p_skeleton == null:
		return SKELETON_IS_NULL

	if p_skeleton.get_bone_count() <= 0:
		return SKELETON_ZERO_BONES

	if !p_root.is_ancestor_of(p_skeleton):
		return ROOT_NOT_PARENT_OF_SKELETON

	return AVATAR_OK
