@tool
extends EditorScript

func calculate_constraint_progress(skeleton: Skeleton3D, bone_name: String) -> float:
	var progress: float = 0.0
	if config.has(bone_name):
		var bone_config = config[bone_name]
		var bone_index = skeleton.find_bone(bone_name)
		var current_pose_basis = skeleton.get_bone_global_pose_no_override(bone_index).basis
		var rest_pose_basis = skeleton.get_bone_rest(bone_index).basis

		if bone_config.has("twist_rotation_range"):
			var twist_from = bone_config["twist_rotation_range"][0]
			var twist_to = bone_config["twist_rotation_range"][1]
			var twist_diff = abs(current_pose_basis.get_euler().y - rest_pose_basis.get_euler().y)
			progress = max(progress, (twist_diff - twist_from) / (twist_to - twist_from))

		if bone_config.has("swing_spherical_coords"):
			for cone in bone_config["swing_spherical_coords"]:
				var center = spherical_to_cartesian(Vector2(cone[0], cone[1]))
				var radius = cone[2]
				var swing_diff_quat = current_pose_basis.get_rotation_quaternion().inverse() * rest_pose_basis.get_rotation_quaternion()
				var swing_diff_angle = swing_diff_quat.get_angle()
				progress = max(progress, (swing_diff_angle - center.length()) / radius)

	return progress


func print_bone_report():
	var skeletons: Array[Node] = get_editor_interface().get_edited_scene_root().find_children("*", "Skeleton3D")
	for skeleton in skeletons:
		if skeleton == null:
			print("No Skeleton3D found.")
			return

		for bone_index in range(skeleton.get_bone_count()):
			var bone_name = skeleton.get_bone_name(bone_index)
			if config.has(bone_name):
				var progress = calculate_constraint_progress(skeleton, bone_name)
				var action = ""

				var current_pose = skeleton.get_bone_global_pose_no_override(bone_index)
				var rest_pose = skeleton.get_bone_rest(bone_index)
				var position_distance = current_pose.origin.distance_to(rest_pose.origin) * 1000  # Convert to mm
				var rotation_difference = (current_pose.basis.get_euler() - rest_pose.basis.get_euler()) * 180 / PI  # Convert to degrees

				if progress < 0.25 and position_distance < 1000:
					action = "Good"
				elif progress < 0.5 or (position_distance >= 1000 and position_distance < 2000):
					action = "Slightly out of range"
				elif progress < 0.75 or (position_distance >= 2000 and position_distance < 3000):
					action = "Out of range"
				else:
					action = "Significantly out of range"

				print("Bone: %s | Progress: %.2f | Suggested Action: %s | Rotation Difference: %s° | Distance from Rest Pose: %.2fmm" % [bone_name, progress, action, rotation_difference, position_distance])

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

func spherical_to_cartesian(theta_phi: Vector2) -> Vector3:
	var theta = theta_phi.x
	var phi = theta_phi.y
	var x = sin(phi) * cos(theta)
	var y = sin(phi) * sin(theta)
	var z = cos(phi)
	return Vector3(x, y, z)
	
func generate_config():
	var config: Dictionary = {
		"LeftUpperLeg": {
			"swing_spherical_coords": [
				[PI / 2, -PI / 2, deg_to_rad(20)],
				[PI / 3, -2 * PI / 3, deg_to_rad(20)],
				[2 * PI / 3, -PI / 3, deg_to_rad(20)]
			],
			"twist_rotation_range": [deg_to_rad(-3), deg_to_rad(3)]
		},
		"RightUpperLeg": {
			"swing_spherical_coords": [
				[PI / 2, -PI / 2, deg_to_rad(20)],
				[PI / 3, -2 * PI / 3, deg_to_rad(20)],
				[2 * PI / 3, -PI / 3, deg_to_rad(20)]
			],
			"twist_rotation_range": [deg_to_rad(-3), deg_to_rad(3)]
		},
		"Hips": {
			"swing_spherical_coords": [
				[PI / 6, -(5 * PI / 6), deg_to_rad(3)],
				[PI / 2, -(PI / 2), deg_to_rad(3)],
				[5 * PI / 6, -(PI / 6), deg_to_rad(3)]
			],
			"twist_rotation_range": [deg_to_rad(270), deg_to_rad(8)]
		},
		"Head": {
			"swing_spherical_coords": [[PI / 2, PI / 2, deg_to_rad(15)]],
			"twist_rotation_range": [deg_to_rad(-3), deg_to_rad(8)]
		},
		"Neck": {
			"swing_spherical_coords": [[PI / 2, PI / 2, deg_to_rad(10)]],
			"twist_rotation_range": [deg_to_rad(-3), deg_to_rad(8)]
		},
		"UpperChest": {
			"swing_spherical_coords": [[PI / 2, PI / 2, deg_to_rad(10)]],
			"twist_rotation_range": [deg_to_rad(-3), deg_to_rad(8)]
		},
		"Chest": {
			"swing_spherical_coords": [[PI / 2, PI / 2, deg_to_rad(10)]],
			"twist_rotation_range": [deg_to_rad(-3), deg_to_rad(8)]
		},
		"Spine": {
			"swing_spherical_coords": [[PI / 2, PI / 2, deg_to_rad(7)]],
			"twist_rotation_range": [deg_to_rad(-1), deg_to_rad(4)]
		},
		"Root": {
			"swing_spherical_coords": [[PI / 2, PI / 2, deg_to_rad(7)]],
			"twist_rotation_range": [deg_to_rad(-1), deg_to_rad(4)]
		}
	}
	return config
	


@export 
var config: Dictionary = generate_config()

func _run():
	var root: Node3D = get_editor_interface().get_edited_scene_root()
	if root == null:
		return
	var properties: Array[Dictionary] = root.get_property_list()
	var iks: Array[Node] = root.find_children("*", "ManyBoneIK3D")
	var skeletons: Array[Node] = root.find_children("*", "Skeleton3D")
	var skeleton: Skeleton3D = skeletons[0]
	for ik in iks:
		ik.free()
	var new_ik: ManyBoneIK3D = ManyBoneIK3D.new()
	skeleton.add_child(new_ik, true)
	new_ik.skeleton_node_path = ".."
	new_ik.owner = root
	new_ik.iterations_per_frame = 10
	new_ik.stabilization_passes = 1
	skeleton.reset_bone_poses()
	var humanoid_profile: SkeletonProfileHumanoid = SkeletonProfileHumanoid.new()
	var humanoid_bones: PackedStringArray = []
	var targets: Dictionary = {
		"Root": "ManyBoneIK3D",
		"Hips": "ManyBoneIK3D",
		"Spine": "ManyBoneIK3D",
		"Chest": "ManyBoneIK3D",
		"UpperChest": "ManyBoneIK3D",
		"Neck": "ManyBoneIK3D",
		"Head": "ManyBoneIK3D",
		"LeftEye": "ManyBoneIK3D",
		"LeftShoulder": "ManyBoneIK3D",
		"LeftUpperArm": "ManyBoneIK3D",
		"LeftLowerArm": "ManyBoneIK3D",
		"LeftHand": "ManyBoneIK3D",
		"LeftUpperLeg": "ManyBoneIK3D",
		"LeftLowerLeg": "ManyBoneIK3D",
		"LeftFoot": "ManyBoneIK3D",
		"LeftToes": "ManyBoneIK3D",
		"RightEye": "ManyBoneIK3D",
		"RightShoulder": "ManyBoneIK3D",
		"RightUpperArm": "ManyBoneIK3D",
		"RightLowerArm": "ManyBoneIK3D",
		"RightHand": "ManyBoneIK3D",
		"RightUpperLeg": "ManyBoneIK3D",
		"RightLowerLeg": "ManyBoneIK3D",
		"RightFoot": "ManyBoneIK3D",
		"RightToes": "ManyBoneIK3D"
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

	print_bone_report()
	
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
			print(node.name)
			node.add_child(node_3d, true)
			node_3d.owner = owner
			parent = node
			break
	node_3d.global_transform = (
		skeleton.global_transform.affine_inverse() * skeleton.get_bone_global_pose_no_override(bone_i)
	)
	node_3d.owner = new_ik.owner
	new_ik.set_pin_nodepath(bone_i, new_ik.get_path_to(node_3d))
