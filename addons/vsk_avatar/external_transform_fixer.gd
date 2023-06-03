# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# external_transform_fixer.gd
# SPDX-License-Identifier: MIT

@tool
extends RefCounted

const avatar_callback_const = preload("avatar_callback.gd")
const bone_lib = preload("bone_lib.gd")


static func fix_external_transform(p_root: Node, p_skeleton: Skeleton3D, _p_undo_redo: UndoRedo) -> int:
	print("---Running ExternalTransform3DFixer---")

	var err: int = avatar_callback_const.generic_error_check(p_root, p_skeleton)
	if err != avatar_callback_const.AVATAR_OK:
		return err

	var skeleton_parent_array: Array = []
	var node: Node = p_skeleton
	while node != p_root:
		skeleton_parent_array.push_front(node)
		node = node.get_parent()

	var external_transform: Transform3D = Transform3D()
	for entry in skeleton_parent_array:
		external_transform *= entry.transform
		if entry is Node3D:
			entry.transform = Transform3D()
			for child in entry.get_children():
				if !skeleton_parent_array.has(child):
					# Do not apply transform to skeleton's bone attachments
					# but apply to its children
					if child is BoneAttachment3D and child.get_parent() == p_skeleton:
						printerr("BoneAttachments are still funky, complain to Saracen!")
						continue

					# Do not apply transform to any meshes with the skeleton
					# set the skeleton's who's parent's we're fixing
					if child is MeshInstance3D:
						if child.get_node_or_null(child.skeleton) == p_skeleton:
							continue

					if child is Node3D:
						child.transform = external_transform * child.transform

	var bone_rest: Transform3D = external_transform * p_skeleton.get_bone_rest(0)
	bone_lib.change_bone_rest(p_skeleton, 0, bone_rest)

	return avatar_callback_const.AVATAR_OK
