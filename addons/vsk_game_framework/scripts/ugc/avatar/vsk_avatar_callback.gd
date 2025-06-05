# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_avatar_callback.gd
# SPDX-License-Identifier: MIT

@tool
extends RefCounted
class_name VSKAvatarCallback

enum Result {
	AVATAR_OK,
	AVATAR_FAILED,
	AVATAR_COULD_NOT_CREATE_POINTS,
	ROOT_IS_NULL,
	SKELETON_IS_NULL,
	SKELETON_ZERO_BONES,
	ROOT_NOT_PARENT_OF_SKELETON,
	ROOT_NOT_PARENT_OF_VISEME_MESH,
	SKIN_MESH_INSTANCE_SIZE_MISMATCH,
	AVATAR_COULD_NOT_CLEAN,
	EXPORTER_NOT_LOADED,
}


static func get_error_str(p_err: int) -> String:
	var error_str: String = "Unknown error!"
	match p_err:
		Result.AVATAR_FAILED:
			error_str = "Generic avatar error! (complain to Saracen)"
		Result.AVATAR_COULD_NOT_CREATE_POINTS:
			error_str = "Could not create points required for IK remapping! (Probably missing humanoid data)"
		Result.ROOT_IS_NULL:
			error_str = "Root node is null!"
		Result.SKELETON_IS_NULL:
			error_str = "Humanoid avatar requires a skeleton to be assigned!"
		Result.ROOT_NOT_PARENT_OF_SKELETON:
			error_str = "Skeleton3D is not a child of the root node!"
		Result.ROOT_NOT_PARENT_OF_VISEME_MESH:
			error_str = "Viseme mesh is not a child of the root node!"
		Result.SKIN_MESH_INSTANCE_SIZE_MISMATCH:
			error_str = "The number of Skin resources do not match the number of MeshInstance3Ds!"
		Result.AVATAR_COULD_NOT_CLEAN:
			error_str = "Could not remove forbidden nodes in avatar!"
		Result.EXPORTER_NOT_LOADED:
			error_str = "Exporter not loaded!"

	return error_str


static func generic_error_check(p_root: Node3D, p_skeleton: Skeleton3D) -> int:
	if p_root == null:
		return Result.ROOT_IS_NULL

	if p_skeleton == null:
		return Result.SKELETON_IS_NULL

	if p_skeleton.get_bone_count() <= 0:
		return Result.SKELETON_ZERO_BONES

	if !p_root.is_ancestor_of(p_skeleton):
		return Result.ROOT_NOT_PARENT_OF_SKELETON

	return Result.AVATAR_OK
