@tool
extends EditorScript

func get_direction_message(direction: Vector3) -> String:
	var constants = {
		"Center": Vector3.ZERO,
		"Full Zoom": Vector3.ONE,
		"Infinite Distance": Vector3(INF, INF, INF),
		"Move Left (West)": Vector3.LEFT,
		"Move Right (East)": Vector3.RIGHT,
		"Move Up": Vector3.UP,
		"Move Down": Vector3.DOWN,
		"Move Forward (North)": Vector3.FORWARD,
		"Move Backward (South)": Vector3.BACK
	}
	
	var closest_constant = ""
	var min_distance = INF
	
	for key in constants.keys():
		var distance = direction.distance_to(constants[key])
		if distance < min_distance:
			min_distance = distance
			closest_constant = key
			
	return closest_constant

func print_bone_report(targets, initial_global_poses):
	var skeletons: Array[Node] = get_editor_interface().get_edited_scene_root().find_children("*", "Skeleton3D")
	var num_bones_considered = 0
	var sum_squared_position_distances = 0.0

	for skeleton in skeletons:
		if skeleton == null:
			print("No Skeleton3D found.")
			return

		for bone_index in range(skeleton.get_bone_count()):
			var bone_name = skeleton.get_bone_name(bone_index)
			if not initial_global_poses.has(bone_name):
				continue
			
			if not targets.has(bone_name) and not config.has(bone_name):
				continue

			num_bones_considered += 1

			var action = ""

			var current_pose_global = skeleton.get_bone_global_pose(bone_index)

			var initial_pose_global = initial_global_poses[bone_name]

			var position_distance = initial_pose_global.origin.distance_to(current_pose_global.origin) * 1000  # Convert to mm
			var rotation_difference = (current_pose_global.basis.get_euler() - initial_pose_global.basis.get_euler()) * 180 / PI  # Convert to degrees

			var direction_vector = (current_pose_global.origin - initial_pose_global.origin).normalized()

			sum_squared_position_distances += position_distance * position_distance

			if position_distance < 5:
				action = "Good"
			elif (position_distance >= 5 and position_distance < 10):
				action = "Slightly out of range"
			elif (position_distance >= 10 and position_distance < 15):
				action = "Out of range"
			else:
				action = "Significantly out of range"

			var comment = ""
			if config.has(bone_name) and config[bone_name].has("comment"):
				comment = config[bone_name]["comment"]

			print("Bone: %s | Suggested Action: %s | Direction Vector: %s | Adjustment Vector & Distance: %s %smm | Comment: %s"  % [bone_name, action, direction_vector, get_direction_message(direction_vector), position_distance, comment])

	if num_bones_considered > 0:
		var rmse = sqrt(sum_squared_position_distances / num_bones_considered)
		print("RMSE: %.2fmm" % rmse)



func create_symmetric_entry(name, swing_spherical_coords, twist_rotation_range_from, twist_rotation_range_range):
	var entry = {
		name: {
			"swing_spherical_coords": swing_spherical_coords,
			"twist_rotation_range": {
				"from": deg_to_rad(twist_rotation_range_from),
				"range": deg_to_rad(twist_rotation_range_range)
			}
		}
	}
	var right_name = name.replace("Left", "Right")
	entry[right_name] = {
		"swing_spherical_coords": [],
		"twist_rotation_range": {
			"from": deg_to_rad(twist_rotation_range_from),
			"range": deg_to_rad(twist_rotation_range_range)
		}
	}

	for center_radius in swing_spherical_coords:
		var center = center_radius.get("center", Vector2(0, 1))
		var radius = center_radius["radius"]
		var new_center = Vector2(-center.x, center.y)

		entry[right_name]["swing_spherical_coords"].append({"center": new_center, "radius": radius})

	return entry

	# The `process_swing_spherical_coords` function takes three arguments: a configuration dictionary, a mode string, and an optional integer parameter. The purpose of this function is to process the swing spherical coordinates for each bone in the configuration dictionary based on the specified mode.

	# 1. It iterates through the keys of the configuration dictionary.
	# 2. For each key, it retrieves the swing spherical coordinates and initializes an empty list called `new_coords`.
	# 3. If the mode is "combine" and the parameter is less than 1, the parameter is set to 1.
	# 4. The `step` variable is set based on the mode. If the mode is "combine", the step is equal to the parameter plus 1; otherwise, the step is 1.
	# 5. The function then iterates through the range of coordinates with the given step.
	# 6. It calculates the average polar angle, azimuthal angle, and radius between the start and end coordinates.
	# 7. Depending on the mode, it either appends the start coordinate and new coordinate to `new_coords` or splits the coordinates into smaller segments based on the parameter value.
	# 8. If the mode is not "split" and the length of the coordinates is not divisible by the step, the last coordinate is appended to `new_coords`.
	# 9. Finally, the updated `new_coords` list is assigned back to the configuration dictionary for the current key.
	
	# The `increase_twist_rotation_range` function takes two arguments: a configuration dictionary and a float increment. The purpose of this function is to increase the twist rotation range for each bone in the configuration dictionary by the specified increment.
	
	# 1. It iterates through the keys of the configuration dictionary.
	# 2. For each key, it retrieves the twist rotation range.
	# 3. It calculates the new twist rotation range by subtracting the increment from the lower bound and adding the increment to the upper bound.
	# 4. The updated twist rotation range is assigned back to the configuration dictionary for the current key.
	# 5. Finally, the modified configuration dictionary is returned.

func spherical_to_cartesian(theta_phi: Vector2) -> Vector3:
	var theta = theta_phi.x
	var phi = theta_phi.y
	var x = sin(phi) * cos(theta)
	var y = sin(phi) * sin(theta)
	var z = cos(phi)
	return Vector3(x, y, z)

func generate_config():
	var config: Dictionary = {
		"Head": {
			"swing_spherical_coords": [[PI / 2, PI / 2, deg_to_rad(15)]],
			"twist_rotation_range": [deg_to_rad(-3), deg_to_rad(8)],
			"comment": "The head does not move much. Allows for limited rotation and tilt."
		},
		"Neck": {
			"swing_spherical_coords": [[PI / 2, PI / 2, deg_to_rad(10)]],
			"twist_rotation_range": [deg_to_rad(-3), deg_to_rad(8)],
			"comment": "Allows for moderate neck movement while maintaining a natural posture."
		},
		"LeftHand": {
			"swing_spherical_coords": [[PI / 2, PI / 2, deg_to_rad(15)]],
			"twist_rotation_range": [deg_to_rad(-3), deg_to_rad(8)],
			"comment": "Permits a wide range of motion for grasping and gesturing."
		},
		"LeftLowerArm": {
			"swing_spherical_coords": [[PI / 2, PI / 2, deg_to_rad(15)]],
			"twist_rotation_range": [deg_to_rad(-3), deg_to_rad(8)],
			"comment": "Allows for bending at the elbow and limited twisting."
		},
		"LeftUpperArm": {
			"swing_spherical_coords": [[PI / 2, PI / 2, deg_to_rad(15)]],
			"twist_rotation_range": [deg_to_rad(-3), deg_to_rad(8)],
			"comment": "Enables a wide range of shoulder movement while maintaining a natural appearance."
		},
		"LeftShoulder": {
			"swing_spherical_coords": [[PI / 2, PI / 2, deg_to_rad(15)]],
			"twist_rotation_range": [deg_to_rad(-3), deg_to_rad(8)],
			"comment": "Permits shoulder rotation and limited twisting for natural arm movement."
		},
		"RightHand": {
			"swing_spherical_coords": [[PI / 2, PI / 2, deg_to_rad(15)]],
			"twist_rotation_range": [deg_to_rad(-3), deg_to_rad(8)],
			"comment": "Permits a wide range of motion for grasping and gesturing."
		},
		"RightLowerArm": {
			"swing_spherical_coords": [[PI / 2, PI / 2, deg_to_rad(15)]],
			"twist_rotation_range": [deg_to_rad(-3), deg_to_rad(8)],
			"comment": "Allows for bending at the elbow and limited twisting."
		},
		"RightUpperArm": {
			"swing_spherical_coords": [[PI / 2, PI / 2, deg_to_rad(15)]],
			"twist_rotation_range": [deg_to_rad(-3), deg_to_rad(8)],
			"comment": "Enables a wide range of shoulder movement while maintaining a natural appearance."
		},
		"RightShoulder": {
			"swing_spherical_coords": [[PI / 2, PI / 2, deg_to_rad(15)]],
			"twist_rotation_range": [deg_to_rad(-3), deg_to_rad(8)],
			"comment": "Permits shoulder rotation and limited twisting for natural arm movement."
		},
		"UpperChest": {
			"swing_spherical_coords": [[PI / 2, PI / 2, deg_to_rad(10)]],
			"twist_rotation_range": [deg_to_rad(-3), deg_to_rad(8)],
			"comment": "Allows for moderate upper chest movement while maintaining a natural posture."
		},
		"Chest": {
			"swing_spherical_coords": [[PI / 2, PI / 2, deg_to_rad(10)]],
			"twist_rotation_range": [deg_to_rad(-3), deg_to_rad(8)],
			"comment": "Permits moderate chest movement for natural breathing and posture."
		},
		"Spine": {
			"swing_spherical_coords": [[PI / 2, PI / 2, deg_to_rad(7)]],
			"twist_rotation_range": [deg_to_rad(-1), deg_to_rad(4)],
			"comment": "Enables limited spine movement to maintain a natural and comfortable posture."
		},
		"LeftFoot": {
			"swing_spherical_coords": [[PI / 2, PI / 2, deg_to_rad(15)]],
			"twist_rotation_range": [deg_to_rad(-3), deg_to_rad(8)],
			"comment": "Allows for a wide range of foot movement for balance and walking."
		},
        "LeftLowerLeg": {
            "swing_spherical_coords": [[PI / 2, PI / 4, deg_to_rad(45)]],
            "twist_rotation_range": [deg_to_rad(-15), deg_to_rad(15)],
            "comment": "Permits bending at the knee and limited twisting for natural leg movement."
        },
		"LeftUpperLeg": {
			"swing_spherical_coords": [
				[PI / 2, -PI / 2, deg_to_rad(20)],
				[PI / 3, -2 * PI / 3, deg_to_rad(20)],
				[2 * PI / 3, -PI / 3, deg_to_rad(20)]
			],
			"twist_rotation_range": [deg_to_rad(-3), deg_to_rad(3)],
			"comment": "Enables a wide range of hip movement for walking and sitting."
		},
		"RightFoot": {
			"swing_spherical_coords": [[PI / 2, PI / 2, deg_to_rad(15)]],
			"twist_rotation_range": [deg_to_rad(-3), deg_to_rad(8)],
			"comment": "Allows for a wide range of foot movement for balance and walking."
		},
        "RightLowerLeg": {
            "swing_spherical_coords": [[PI / 2, PI / 4, deg_to_rad(45)]],
            "twist_rotation_range": [deg_to_rad(-15), deg_to_rad(15)],
            "comment": "Permits bending at the knee and limited twisting for natural leg movement."
        },
		"RightUpperLeg": {
			"swing_spherical_coords": [
				[PI / 2, -PI / 2, deg_to_rad(20)],
				[PI / 3, -2 * PI / 3, deg_to_rad(20)],
				[2 * PI / 3, -PI / 3, deg_to_rad(20)]
			],
			"twist_rotation_range": [deg_to_rad(-3), deg_to_rad(3)],
			"comment": "Enables a wide range of hip movement for walking and sitting."
		},
		"Hips": {
			"swing_spherical_coords": [
				[PI / 6, -(5 * PI / 6), deg_to_rad(3)],
				[PI / 2, -(PI / 2), deg_to_rad(3)],
				[5 * PI / 6, -(PI / 6), deg_to_rad(3)]
			],
			"twist_rotation_range": [deg_to_rad(270), deg_to_rad(8)],
			"comment": "Permits limited hip movement for stability and natural posture."
		},
		"Root": {
			"swing_spherical_coords": [[PI / 2, PI / 2, deg_to_rad(7)]],
			"twist_rotation_range": [deg_to_rad(-1), deg_to_rad(4)],
			"comment": "Allows for minimal root movement to maintain overall body balance and posture."
		},
	}
	return config

@export 
var config: Dictionary = generate_config()

func _run():
	var root: Node3D = get_editor_interface().get_edited_scene_root() as Node3D
	if root == null:
		return
	var properties: Array[Dictionary] = root.get_property_list()
	var iks: Array[Node] = root.find_children("*", "ManyBoneIK3D")
	var skeletons: Array[Node] = root.find_children("*", "Skeleton3D")
	var skeleton: Skeleton3D = skeletons[0]
	for ik in iks:
		ik.free()
	
	var initial_global_poses = {}
	for bone_i in range(skeleton.get_bone_count()):
		var bone_name = skeleton.get_bone_name(bone_i)
		initial_global_poses[bone_name] = skeleton.get_bone_global_pose(bone_i)
	
	var new_ik: ManyBoneIK3D = ManyBoneIK3D.new()
	skeleton.add_child(new_ik, true)
	new_ik.skeleton_node_path = ".."
	new_ik.owner = root
	new_ik.iterations_per_frame = 10
	new_ik.stabilization_passes = 1
	new_ik.constraint_mode = true
	skeleton.reset_bone_poses()
	var humanoid_profile: SkeletonProfileHumanoid = SkeletonProfileHumanoid.new()
	var humanoid_bones: PackedStringArray = []
	var targets: Dictionary = {
		"Root": "ManyBoneIK3D",
		"Hips": "ManyBoneIK3D",
		"Head": "ManyBoneIK3D",
		"LeftHand": "ManyBoneIK3D",
		"LeftFoot": "ManyBoneIK3D",
		"RightHand": "ManyBoneIK3D",
		"RightFoot": "ManyBoneIK3D",
	}       

	for bone_i in skeleton.get_bone_count():
		var bone_name = skeleton.get_bone_name(bone_i)
	
		if config.has(bone_name):
			var bone_config = config[bone_name]
			if bone_config.has("twist_rotation_range"):
				var twist: Vector2 = Vector2(deg_to_rad(bone_config["twist_rotation_range"][0]), deg_to_rad(bone_config["twist_rotation_range"][1]))
				new_ik.set_kusudama_twist(bone_i, twist)
	
			if bone_config.has("swing_spherical_coords"):
				var cones: Array = bone_config["swing_spherical_coords"]
				new_ik.set_kusudama_limit_cone_count(bone_i, cones.size())
				for cone_i in range(cones.size()):
					var cone: Array = cones[cone_i]
					var center: Vector2 = Vector2(cone[0], cone[1])
					new_ik.set_kusudama_limit_cone_center(bone_i, cone_i, spherical_to_cartesian(center))
					new_ik.set_kusudama_limit_cone_radius(bone_i, cone_i, cone[2])

	var keys = targets.keys()
	for target_i in keys.size():
		tune_bone(new_ik, skeleton, keys[target_i], targets[keys[target_i]], root)

	print_bone_report(targets, initial_global_poses)
	
func tune_bone(new_ik: ManyBoneIK3D, skeleton: Skeleton3D, bone_name: String, bone_name_parent: String, owner):
	var bone_i = skeleton.find_bone(bone_name)
	if bone_i == -1:
		return
	var node_3d = Node3D.new()
	node_3d.name = bone_name
	var children: Array[Node] = owner.find_children("*", "")
	var parent: Node = null
	for node in children:
		if str(node.name) == bone_name_parent:
			node.add_child(node_3d, true)
			node_3d.owner = owner
			parent = node
			break
	node_3d.global_transform = (
		skeleton.global_transform.affine_inverse() * skeleton.get_bone_global_pose_no_override(bone_i)
	)
	node_3d.owner = new_ik.owner
	new_ik.set_pin_nodepath(bone_i, new_ik.get_path_to(node_3d))
