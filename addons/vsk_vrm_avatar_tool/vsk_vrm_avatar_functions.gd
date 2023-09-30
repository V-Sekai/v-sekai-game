# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_vrm_avatar_functions.gd
# SPDX-License-Identifier: MIT

@tool
extends Node

const vrm_toplevel_const = preload("res://addons/vrm/vrm_toplevel.gd")

const vsk_avatar_definition_const = preload("res://addons/vsk_avatar/vsk_avatar_definition.gd")
const vsk_avatar_definition_runtime_const = preload("res://addons/vsk_avatar/vsk_avatar_definition_runtime.gd")

const node_util_const = preload("res://addons/gd_util/node_util.gd")
const bone_lib_const = preload("res://addons/vsk_avatar/bone_lib.gd")

const avatar_physics_const = preload("res://addons/vsk_avatar/avatar_physics.gd")
const avatar_springbone_const = preload("res://addons/vsk_avatar/physics/avatar_springbone.gd")
const avatar_collidergroup_const = preload("res://addons/vsk_avatar/physics/avatar_collidergroup.gd")


static func recursively_reassign_owner(p_instance: Node, p_owner: Node) -> void:
	if p_instance != p_owner:
		p_instance.set_owner(p_owner)

	for child in p_instance.get_children():
		recursively_reassign_owner(child, p_owner)


static func get_first_person_bone_id(p_skeleton: Skeleton3D) -> int:
	if p_skeleton:
		return p_skeleton.find_bone("Head")
	else:
		return -1


static func get_fallback_eye_offset(p_skeleton: Skeleton3D, eye_offset: Vector3) -> Vector3:
	if p_skeleton:
		var left_eye = p_skeleton.find_bone("LeftEye")
		var right_eye = p_skeleton.find_bone("RightEye")
		if left_eye != -1 and right_eye != -1:
			var interp: Vector3 = p_skeleton.get_bone_global_rest(left_eye).origin.lerp(p_skeleton.get_bone_global_rest(right_eye).origin, 0.5)
			interp.z += 0.5 * interp.distance_to(eye_offset)
			return interp
	return eye_offset


static func convert_vrm_instance(p_vrm_instance: Node3D) -> Node3D:
	var vsk_avatar_root: Node3D = null

	if typeof(p_vrm_instance.get("vrm_meta")) != TYPE_NIL:
		var vrm_meta = p_vrm_instance.vrm_meta
		if vrm_meta:
			var eye_offset: Vector3 = vrm_meta.eye_offset
			var skeleton: Skeleton3D = p_vrm_instance.find_child("GeneralSkeleton", true, false)
			if skeleton:
				vsk_avatar_root = Node3D.new()
				vsk_avatar_root.set_name("Avatar")
				vsk_avatar_root.set_script(vsk_avatar_definition_const)

				vsk_avatar_root.set_owner(null)

				vsk_avatar_root.add_child(p_vrm_instance, true)
				p_vrm_instance.set_owner(vsk_avatar_root)
				vsk_avatar_root.set_editable_instance(p_vrm_instance, true)

				# Skeleton Path
				var skeleton_path: NodePath = vsk_avatar_root.get_path_to(skeleton)

				vsk_avatar_root.set_skeleton_path(skeleton_path)

				var fp_global_position: Vector3 = Vector3.ZERO
				var head_global_position: Vector3 = Vector3.ZERO

				var fp_bone_id: int = get_first_person_bone_id(skeleton)
				if fp_bone_id != -1:
					head_global_position = bone_lib_const.get_bone_global_rest_transform(fp_bone_id, skeleton).origin
					fp_global_position = ((bone_lib_const.get_bone_global_rest_transform(fp_bone_id, skeleton) * Transform3D(Basis(), eye_offset)).origin)

				if eye_offset.is_equal_approx(Vector3.ZERO):
					fp_global_position = get_fallback_eye_offset(skeleton, fp_global_position)

				fp_global_position = (node_util_const.get_relative_global_transform(vsk_avatar_root, skeleton) * fp_global_position)
				head_global_position = (node_util_const.get_relative_global_transform(vsk_avatar_root, skeleton) * head_global_position)

				# Avatar Physics
				var secondary: Node = p_vrm_instance.get_node_or_null(p_vrm_instance.vrm_secondary)

				if secondary:
					var avatar_physics: Node3D = Node3D.new()
					avatar_physics.set_script(avatar_physics_const)

					vsk_avatar_root.add_child(avatar_physics, true)
					avatar_physics.set_name("AvatarPhysics")
					avatar_physics.set_owner(vsk_avatar_root)

					var collider_group_map: Dictionary = {}
					var spring_bone_map: Dictionary = {}

					for collider_group in secondary.collider_groups:
						var vsk_collider_group: Resource = avatar_collidergroup_const.new()
						vsk_collider_group.skeleton_or_node = avatar_physics.get_path_to(skeleton)
						vsk_collider_group.bone = collider_group.bone
						vsk_collider_group.sphere_colliders = collider_group.sphere_colliders
						collider_group_map[collider_group] = vsk_collider_group

					for spring_bone in secondary.spring_bones:
						var vsk_spring_bone: Resource = avatar_springbone_const.new()
						vsk_spring_bone.stiffness_force = spring_bone.stiffness_force
						vsk_spring_bone.gravity_power = spring_bone.gravity_power
						vsk_spring_bone.gravity_dir = spring_bone.gravity_dir
						vsk_spring_bone.drag_force = spring_bone.drag_force
						vsk_spring_bone.skeleton = avatar_physics.get_path_to(skeleton)
						vsk_spring_bone.center_bone = spring_bone.center_bone
						vsk_spring_bone.center_node = avatar_physics.get_path_to(avatar_physics)
						vsk_spring_bone.hit_radius = spring_bone.hit_radius

						var root_bones: Array = []
						for root_bone in spring_bone.root_bones:
							root_bones.push_back(root_bone)
						vsk_spring_bone.root_bones = root_bones

						var collider_groups: Array = []
						for collider_group in spring_bone.collider_groups:
							collider_groups.push_back(collider_group_map[collider_group])
						vsk_spring_bone.collider_groups = collider_groups

						spring_bone_map[spring_bone] = vsk_spring_bone

					avatar_physics.collider_groups = collider_group_map.values()
					avatar_physics.spring_bones = spring_bone_map.values()

					vsk_avatar_root.avatar_physics_path = vsk_avatar_root.get_path_to(avatar_physics)

				# Eye position
				var eye_node: Marker3D = Marker3D.new()
				vsk_avatar_root.add_child(eye_node, true)
				eye_node.set_name("EyePosition")
				eye_node.set_owner(vsk_avatar_root)
				eye_node.transform *= Transform3D(Basis.IDENTITY, fp_global_position)
				vsk_avatar_root.set_eye_transform_path(vsk_avatar_root.get_path_to(eye_node))

				# Approx Mouth position
				var mouth_node: Marker3D = Marker3D.new()
				vsk_avatar_root.add_child(mouth_node, true)
				mouth_node.set_name("MouthPosition")
				mouth_node.set_owner(vsk_avatar_root)
				# quarter of the way between head (throat) and eyes? Maybe should be adjustable.
				mouth_node.transform *= Transform3D(Basis.IDENTITY, head_global_position.lerp(fp_global_position, 0.25))
				vsk_avatar_root.set_mouth_transform_path(vsk_avatar_root.get_path_to(mouth_node))

				# Use the VRM preview texture if it exists
				if vrm_meta.texture:
					vsk_avatar_root.editor_properties.vskeditor_preview_type = "Texture2D"
					vsk_avatar_root.editor_properties.vskeditor_preview_texture = vrm_meta.texture

	return vsk_avatar_root
