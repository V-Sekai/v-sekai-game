# Copyright 2023-present Lyuma and contributors
# Copyright 2022-2023 lox9973
#
# SPDX-License-Identifier: Apache-2.0
@tool
extends Node
class_name HumanoidDriver

const human_trait_const: Resource = preload("human_trait.gd")
const humanoid_transform_util_const: Resource = preload("transform_util.gd")

@export var reset_pose: bool = false

@export var active: bool = false
@export var skeleton: Skeleton3D = null
@export var hips_transform: Transform3D = Transform3D()
@export var root_motion: Transform3D = Transform3D()

@export var muscle_settings: Array[float] = []
@export var bone_swing_twists: Array[Vector3] = []
@export var bone_leftovers: Array[Quaternion] = []

func _init():
	muscle_settings.resize(human_trait_const.MuscleCount)
	muscle_settings.fill(0.0)
	bone_leftovers.resize(human_trait_const.BoneCount)
	bone_leftovers.fill(Quaternion.IDENTITY)

var humanoid_track_sets: Array[Array] = []

func update_muscle_values() -> void:
	var muscle_index_to_bone_and_axis: Array[Vector2i] = human_trait_const.muscle_index_to_bone_and_axis() # int -> Vector2i
		
	for i: int in range(human_trait_const.BoneCount + 1):
		if i == 0:
			humanoid_track_sets.append([null, null, null, null])
		else:
			humanoid_track_sets.append([null, null, null])
		
	for i: int in range(0, human_trait_const.MuscleCount):
		var muscle_bone_idx_axis: Vector2i = muscle_index_to_bone_and_axis[i]
		humanoid_track_sets[muscle_bone_idx_axis.x][muscle_bone_idx_axis.y] = muscle_settings[i]
	
		
	bone_swing_twists = []
	for i: int in range(0, human_trait_const.BoneCount):
		var new_vec: Vector3 = Vector3(0.0, 0.0, 0.0)
		if humanoid_track_sets[i][0] is float:
			new_vec.x = humanoid_track_sets[i][0]
		if humanoid_track_sets[i][1] is float:
			new_vec.y = humanoid_track_sets[i][1]
		if humanoid_track_sets[i][2] is float:
			new_vec.z = humanoid_track_sets[i][2]
			
		bone_swing_twists.append(new_vec)

func _process(_delta: float) -> void:
	if skeleton:
		if reset_pose:
			for i: int in range(0, skeleton.get_bone_count()):
				skeleton.set_bone_pose(i, skeleton.get_bone_rest(i))
			return # If resetting pose, do nothing else this frame

		if not active and Engine.is_editor_hint():
			return

		if skeleton:
			update_muscle_values()

			var target_root_bone_idx: int = -1 # This is the bone named "Root"
			var target_hips_bone_idx: int = -1 # This is the bone *named* Hips or GodotHumanNames[0]

			# Pass 1: Reset bones and find target Root and Hips bones
			for i: int in range(0, skeleton.get_bone_count()):
				skeleton.set_bone_pose(i, skeleton.get_bone_rest(i)) # Reset to rest pose
				var bone_name_check: String = skeleton.get_bone_name(i)

				# Check for Root bone (world-level motion)
				if bone_name_check == "Root" and target_root_bone_idx == -1:
					target_root_bone_idx = i
				# Check if this bone is mapped as Hips (humanoid_bone_id == 0)
				elif human_trait_const.GodotHumanNames.find(bone_name_check) == 0 and target_hips_bone_idx == -1:
					target_hips_bone_idx = i

			var bone_to_receive_hips_transform: int = -1
			if target_hips_bone_idx != -1:
				bone_to_receive_hips_transform = target_hips_bone_idx
			else:
				var default_hips_name = human_trait_const.GodotHumanNames[0] if human_trait_const.GodotHumanNames.size() > 0 else "Hips"
				push_warning("HumanoidDriver: Mapped '%s' bone not found in target skeleton." % default_hips_name)

			# Pass 2: Apply muscle and leftover rotations to all mapped bones
			# that are NOT receiving the full hips_transform.
			for i: int in range(0, skeleton.get_bone_count()):
				if i == bone_to_receive_hips_transform or i == target_root_bone_idx:
					continue # These bones get their transforms applied later

				var bone_name: String = skeleton.get_bone_name(i)
				var humanoid_bone_id: int = human_trait_const.GodotHumanNames.find(bone_name)

				# Process if it's a mapped bone (humanoid_bone_id >= 0).
				# This includes Hips (humanoid_bone_id == 0) if Hips is not the bone_to_receive_hips_transform.
				if humanoid_bone_id >= 0:
					if humanoid_bone_id < bone_swing_twists.size(): # Ensure index is valid
						var this_swing_twist: Vector3 = bone_swing_twists[humanoid_bone_id]
						var pre_value: Quaternion = Quaternion() 
						var value: Quaternion = humanoid_transform_util_const.calculate_humanoid_rotation(humanoid_bone_id, this_swing_twist)
						var leftover_compensation: Quaternion = Quaternion.IDENTITY
						if humanoid_bone_id < bone_leftovers.size(): 
							leftover_compensation = bone_leftovers[humanoid_bone_id]

						skeleton.set_bone_pose_rotation(i, pre_value * value * leftover_compensation)
					else:
						push_warning("HumanoidDriver: humanoid_bone_id %d out of bounds for bone_swing_twists (size %d) for bone '%s'" % [humanoid_bone_id, bone_swing_twists.size(), bone_name])

			# Pass 3: Apply root motion (world-level motion) to Root bone
			if target_root_bone_idx != -1:
				skeleton.set_bone_pose(target_root_bone_idx, root_motion)
			else:
				push_warning("HumanoidDriver: 'Root' bone not found in target skeleton for root motion.")

			# Pass 4: Apply hips transform (object-level motion) to Hips bone
			if bone_to_receive_hips_transform != -1:
				skeleton.set_bone_pose(bone_to_receive_hips_transform, hips_transform)

func _get_property_list() -> Array[Dictionary]:
	var properties: Array[Dictionary] = []
	for i: int in range(0, human_trait_const.MuscleCount):
		properties.append({
			"name": "muscle_settings/" + human_trait_const.MuscleName[i],
			"type": TYPE_FLOAT,
			"hint": PROPERTY_HINT_RANGE,
			"hint_string": "-1.0, 1.0",
		})
	return properties
	
func _get(property: StringName) -> Variant:
	var found_index: int = human_trait_const.MuscleName.find(property.lstrip("muscle_settings/"))
	if found_index >= 0:
		return muscle_settings[found_index]
		
	return null
	
func _set(property: StringName, value: Variant) -> bool:
	var found_index: int = human_trait_const.MuscleName.find(property.lstrip("muscle_settings/"))
	if found_index >= 0:
		if typeof(value) == TYPE_FLOAT:
			muscle_settings[found_index] = value as float
			return true
		
	return false

func _property_can_revert(p_property: StringName) -> bool:
	var found_index: int = human_trait_const.MuscleName.find(p_property.lstrip("muscle_settings/"))
	if found_index >= 0:
		return true
	
	return false
	
func _property_get_revert(p_property: StringName) -> Variant:
	var found_index: int = human_trait_const.MuscleName.find(p_property.lstrip("muscle_settings/"))
	if found_index >= 0:
		return 0.0
	
	return null
