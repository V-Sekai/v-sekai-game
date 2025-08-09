# Copyright 2023-present Lyuma and contributors
# Copyright 2022-2023 lox9973
#
# SPDX-License-Identifier: Apache-2.0
@tool
extends Node
class_name HumanoidPoseCalculator

const human_trait: Resource = preload("human_trait.gd")
const humanoid_transform_util: Resource = preload("transform_util.gd")

@export var active: bool = false
@export var skeleton: Skeleton3D = null
@export var target: HumanoidDriver = null
@export var force_rest_pose: bool = false
@export var force_bicycle_pose: bool = false

var bone_and_axis_to_coefficent_mapping_table: Array[Array] = []
	
func precalculate_bone_axis_table() -> void:
	var muscle_index_to_bone_and_axis: Array[Vector2i] = human_trait.muscle_index_to_bone_and_axis() # int -> Vector2i
		
	bone_and_axis_to_coefficent_mapping_table = []
	for i: int in range(human_trait.BoneCount + 1):
		if i == 0:
			bone_and_axis_to_coefficent_mapping_table.append([null, null, null, null])
		else:
			bone_and_axis_to_coefficent_mapping_table.append([null, null, null])
			
	for i: int in range(0, human_trait.MuscleCount):
		var muscle_bone_idx_axis: Vector2i = muscle_index_to_bone_and_axis[i]
		bone_and_axis_to_coefficent_mapping_table[muscle_bone_idx_axis.x][muscle_bone_idx_axis.y] = i


func apply_pose_to_humanoid_driver_coefficents() -> void:
	if not active and Engine.is_editor_hint():
		return
	
	precalculate_bone_axis_table() # Should be efficient enough to call, or optimize to call once
	
	if not skeleton or not target:
		return

	if force_bicycle_pose or force_rest_pose:
		for bone_idx: int in range(0, skeleton.get_bone_count()):
			var rest_transform: Transform3D = skeleton.get_bone_rest(bone_idx)
			var new_pose: Transform3D = Transform3D(rest_transform.basis.orthonormalized(), rest_transform.origin)
			skeleton.set_bone_pose(bone_idx, new_pose)

	var source_hips_bone_name: String = ""
	var found_source_for_hips_transform: bool = false

	for bone_idx: int in range(0, skeleton.get_bone_count()):
		var bone_name_check: String = skeleton.get_bone_name(bone_idx)
		var humanoid_id_check: int = human_trait.GodotHumanNames.find(bone_name_check)
		if humanoid_id_check == human_trait.HumanBodyBones.Hips: # This is the mapped "Hips"
			target.hips_transform = skeleton.get_bone_pose(bone_idx)
			source_hips_bone_name = bone_name_check # Actual name of the Hips bone
			found_source_for_hips_transform = true
			break
	
	if not found_source_for_hips_transform:
		target.hips_transform = Transform3D() # Default to identity if neither found
		push_warning("HumanoidPoseCalculator: 'Hips' bone found in source skeleton.")

	# Initialize local leftovers array for inverse_calculate_humanoid_rotation
	var local_leftovers_array: Array[Quaternion] = []
	local_leftovers_array.resize(human_trait.BoneCount)
	local_leftovers_array.fill(Quaternion.IDENTITY)

	# Ensure target HumanoidDriver arrays are correctly sized (should be handled by HumanoidDriver._init or _ready)
	if target.bone_swing_twists.size() != human_trait.BoneCount:
		target.bone_swing_twists.resize(human_trait.BoneCount)
		target.bone_swing_twists.fill(Vector3.ZERO)
	if target.bone_leftovers.size() != human_trait.BoneCount:
		target.bone_leftovers.resize(human_trait.BoneCount)
		target.bone_leftovers.fill(Quaternion.IDENTITY)
	if target.muscle_settings.size() != human_trait.MuscleCount:
		target.muscle_settings.resize(human_trait.MuscleCount)
		target.muscle_settings.fill(0.0)

	# Pass 2: Process all bones for muscle/leftover calculation
	for bone_idx: int in range(0, skeleton.get_bone_count()):
		var bone_name: String = skeleton.get_bone_name(bone_idx)
		var humanoid_bone_id: int = human_trait.GodotHumanNames.find(bone_name)

		if bone_name == source_hips_bone_name:
			# This bone's full local transform was used for target.hips_transform.
			# Clear its potential muscle/leftover values in the target, as it's not driven by them.
			if humanoid_bone_id >= 0: # If it happens to be a mapped bone (e.g. Hips was used)
				target.bone_swing_twists[humanoid_bone_id] = Vector3.ZERO
				target.bone_leftovers[humanoid_bone_id] = Quaternion.IDENTITY
				var muscle_indices_for_this_bone: Array = bone_and_axis_to_coefficent_mapping_table[humanoid_bone_id]
				for i in range(0, 3):
					if muscle_indices_for_this_bone[i] is int:
						var muscle_idx: int = muscle_indices_for_this_bone[i]
						if muscle_idx >= 0 and muscle_idx < target.muscle_settings.size():
							target.muscle_settings[muscle_idx] = 0.0
			continue # Skip muscle/leftover calculation for this bone

		if humanoid_bone_id >= 0: # Process other mapped humanoid bones
			var current_bone_pose: Transform3D = skeleton.get_bone_pose(bone_idx)
			var custom_pose_rotation: Quaternion = current_bone_pose.basis.get_rotation_quaternion()

			if force_bicycle_pose:
				if humanoid_bone_id < human_trait.preQ_exported.size() and humanoid_bone_id < human_trait.postQ_inverse_exported.size():
					var reference_rotation: Quaternion = human_trait.preQ_exported[humanoid_bone_id] * human_trait.postQ_inverse_exported[humanoid_bone_id]
					skeleton.set_bone_pose_rotation(bone_idx, reference_rotation) # Apply bicycle pose rotation
					custom_pose_rotation = reference_rotation # Use this rotation for calculation
				else:
					push_warning("HumanoidPoseCalculator: Missing preQ/postQ for bone %s (ID: %d) for bicycle pose." % [bone_name, humanoid_bone_id])
			
			var muscle_triplet_vector: Vector3 = humanoid_transform_util.inverse_calculate_humanoid_rotation(local_leftovers_array, humanoid_bone_id, custom_pose_rotation)
			
			target.bone_swing_twists[humanoid_bone_id] = muscle_triplet_vector
			if humanoid_bone_id < local_leftovers_array.size():
				target.bone_leftovers[humanoid_bone_id] = local_leftovers_array[humanoid_bone_id]
			
			var muscle_from_bone_map: Array = bone_and_axis_to_coefficent_mapping_table[humanoid_bone_id]
			var muscle_values_for_bone: Array[float] = [muscle_triplet_vector.x, muscle_triplet_vector.y, muscle_triplet_vector.z]
			
			for i in range(0, 3):
				if muscle_from_bone_map[i] is int:
					var muscle_idx: int = muscle_from_bone_map[i]
					if muscle_idx >= 0 and muscle_idx < target.muscle_settings.size():
						target.muscle_settings[muscle_idx] = muscle_values_for_bone[i]

func _process(_delta: float) -> void:
	apply_pose_to_humanoid_driver_coefficents()
