# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# bone_lib.gd
# SPDX-License-Identifier: MIT

extends RefCounted

const node_util_const = preload("res://addons/gd_util/node_util.gd")

const NO_BONE = -1


static func get_bone_global_transform(p_id: int, p_skeleton: Skeleton3D, p_local_transform_array: Array) -> Transform3D:
	var return_transform: Transform3D = Transform3D()
	var parent_id: int = p_skeleton.get_bone_parent(p_id)
	if parent_id != -1:
		return_transform = get_bone_global_transform(parent_id, p_skeleton, p_local_transform_array)

	for transform in p_local_transform_array:
		if p_id >= len(transform):
			push_error("Missing bone global transform: Transform " + JSON.stringify(transform) + " has length " + str(len(transform)) + " id " + str(p_id))
			return return_transform
		return_transform *= transform[p_id]

	return return_transform


static func get_bone_global_rest_transform(p_id: int, p_skeleton: Skeleton3D) -> Transform3D:
	var rest_local_transforms: Array = []
	for i in range(0, p_skeleton.get_bone_count()):
		rest_local_transforms.push_back(p_skeleton.get_bone_rest(i))

	return get_bone_global_transform(p_id, p_skeleton, [rest_local_transforms])


static func get_full_bone_chain(p_skeleton: Skeleton3D, p_first: int, p_last: int) -> PackedInt32Array:
	var bone_chain: PackedInt32Array = get_bone_chain(p_skeleton, p_first, p_last)
	bone_chain.push_back(p_last)

	return bone_chain


static func get_bone_chain(p_skeleton: Skeleton3D, p_first: int, p_last: int) -> PackedInt32Array:
	var bone_chain: Array = []

	if p_first != -1 and p_last != -1:
		var current_bone_index: int = p_last

		while 1:
			current_bone_index = p_skeleton.get_bone_parent(current_bone_index)
			bone_chain.push_front(current_bone_index)
			if current_bone_index == p_first:
				break
			elif current_bone_index == -1:
				return PackedInt32Array()

	return PackedInt32Array(bone_chain)


static func is_bone_parent_of(p_skeleton: Skeleton3D, p_parent_id: int, p_child_id: int) -> bool:
	var p: int = p_skeleton.get_bone_parent(p_child_id)
	while p != -1:
		if p == p_parent_id:
			return true
		p = p_skeleton.get_bone_parent(p)

	return false


static func is_bone_parent_of_or_self(p_skeleton: Skeleton3D, p_parent_id: int, p_child_id: int) -> bool:
	if p_parent_id == p_child_id:
		return true

	return is_bone_parent_of(p_skeleton, p_parent_id, p_child_id)


static func change_bone_rest(p_skeleton: Skeleton3D, bone_idx: int, bone_rest: Transform3D):
	var old_scale: Vector3 = p_skeleton.get_bone_pose_scale(bone_idx)
	var new_rotation: Quaternion = Quaternion(bone_rest.basis.orthonormalized())
	p_skeleton.set_bone_pose_position(bone_idx, bone_rest.origin)
	p_skeleton.set_bone_pose_scale(bone_idx, old_scale)
	p_skeleton.set_bone_pose_rotation(bone_idx, new_rotation)
	p_skeleton.set_bone_rest(bone_idx, Transform3D(Basis(new_rotation) * Basis(Vector3(1, 0, 0) * old_scale.x, Vector3(0, 1, 0) * old_scale.y, Vector3(0, 0, 1) * old_scale.z), bone_rest.origin))
