# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# avatar_physics.gd
# SPDX-License-Identifier: MIT

@tool
extends Node3D

const springbone_class: GDScript = preload("res://addons/vrm/vrm_springbone.gd")
const collidergroup_class: GDScript = preload("res://addons/vrm/vrm_collidergroup.gd")

# Based on Tokage's VRM physics implementation

@export var spring_bones: Array
@export var collider_groups: Array

# Props
var spring_bones_internal: Array = []
var collider_groups_internal: Array = []


class CachedSkeletonPolyfill:
	extends RefCounted
	var skel: Skeleton3D
	var bone_to_children: Dictionary = {}.duplicate()
	var overrides: Array = [].duplicate()
	var override_weights: Array = [].duplicate()

	func _init(p_skel: Skeleton3D):
		self.skel = p_skel
		for i in range(skel.get_bone_count()):
			overrides.push_back(Transform3D.IDENTITY)
			override_weights.push_back(0.0)
			var par: int = skel.get_bone_parent(i)
			if par != -1:
				if not self.bone_to_children.has(par):
					self.bone_to_children[par] = [].duplicate()
				self.bone_to_children[par].push_back(i)

	func clear_bones_global_pose_override():
		skel.clear_bones_global_pose_override()
		for i in range(skel.get_bone_count()):
			overrides[i] = Transform3D.IDENTITY
			override_weights[i] = 0.0

	func set_bone_global_pose_override(bone_idx: int, transform: Transform3D, weight: float, _overide_persistent: bool = false) -> void:
		# persistent makes no sense - it seems to reset weight unless it is true
		# so we ignore the default and always pass true in.
		skel.set_bone_global_pose_override(bone_idx, transform, weight, true)
		overrides[bone_idx] = transform
		override_weights[bone_idx] = weight

	func get_bone_global_pose(bone_idx: int, lvl: int = 0) -> Transform3D:
		if lvl == 128:
			return Transform3D.IDENTITY
		if override_weights[bone_idx] == 1.0:
			return overrides[bone_idx]
		var transform: Transform3D = skel.get_bone_pose(bone_idx)
		transform = (transform * (1.0 - override_weights[bone_idx]) + overrides[bone_idx] * override_weights[bone_idx])
		var par_bone: int = skel.get_bone_parent(bone_idx)
		if par_bone == -1:
			return transform
		return get_bone_global_pose(par_bone, lvl + 1) * transform

	func get_bone_children(bone_idx) -> Array[int]:
		return self.bone_to_children.get(bone_idx, [])

	func get_bone_global_pose_without_override(bone_idx: int, _force_update: bool = false) -> Transform3D:
		var par_bone: int = bone_idx
		var transform: Transform3D = skel.get_bone_pose(par_bone)
		var par: int = skel.get_bone_parent(bone_idx)
		if par == -1:
			return transform
		return skel.get_bone_global_pose(par) * transform


# Called when the node enters the scene tree for the first time.
func _ready():
	return  # FIX LATER
	collider_groups_internal.clear()
	spring_bones_internal.clear()
	var skel_to_polyfill: Dictionary = {}.duplicate()
	if true or not Engine.is_editor_hint():
		for collider_group in collider_groups:
			var new_collider_group = collider_group.manual_duplicate()
			var parent: Node3D = get_node_or_null(new_collider_group.skeleton_or_node)
			var parent_polyfill: Object = parent
			if parent != null:
				if skel_to_polyfill.has(parent):
					parent_polyfill = skel_to_polyfill.get(parent)
				elif parent.get_class() == "Skeleton3D":
					parent_polyfill = CachedSkeletonPolyfill.new(parent)
					skel_to_polyfill[parent] = parent_polyfill
				new_collider_group._ready(parent, parent_polyfill)
				collider_groups_internal.append(new_collider_group)
		for spring_bone in spring_bones:
			var new_spring_bone = spring_bone.manual_duplicate()
			var tmp_colliders: Array = []
			for i in range(collider_groups.size()):
				if new_spring_bone.collider_groups.has(collider_groups[i]):
					tmp_colliders.append_array(collider_groups_internal[i].colliders)
			var skel: Skeleton3D = get_node_or_null(new_spring_bone.skeleton)
			var parent_polyfill: Object = skel
			if skel != null:
				if skel_to_polyfill.has(skel):
					parent_polyfill = skel_to_polyfill.get(skel)
				else:
					parent_polyfill = CachedSkeletonPolyfill.new(skel)
					skel_to_polyfill[skel] = parent_polyfill
				new_spring_bone._ready(skel, parent_polyfill, tmp_colliders)
				spring_bones_internal.append(new_spring_bone)
	return


func update(delta):
	if not Engine.is_editor_hint():
		# force update skeleton
		for spring_bone in spring_bones_internal:
			if spring_bone.skel_polyfill != null:
				spring_bone.skel_polyfill.get_bone_global_pose_without_override(0, true)
		for collider_group in collider_groups_internal:
			collider_group._process()
		for spring_bone in spring_bones_internal:
			spring_bone._process(delta)
	return
