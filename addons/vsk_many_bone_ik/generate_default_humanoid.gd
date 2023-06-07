@tool
extends EditorScript

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
			
			if not targets.has(bone_name):
				continue

			num_bones_considered += 1

			var action = ""

			var current_pose_global = skeleton.get_bone_global_pose(bone_index)

			var initial_pose_global = initial_global_poses[bone_name]

			var position_distance = current_pose_global.origin.distance_to(initial_pose_global.origin) * 1000  # Convert to mm
			var rotation_difference = (current_pose_global.basis.get_euler() - initial_pose_global.basis.get_euler()) * 180 / PI  # Convert to degrees

			sum_squared_position_distances += position_distance * position_distance

			if position_distance < 5:
				action = "Good"
			elif (position_distance >= 5 and position_distance < 10):
				action = "Slightly out of range"
			elif (position_distance >= 10 and position_distance < 15):
				action = "Out of range"
			else:
				action = "Significantly out of range"

			print("Bone: %s | Suggested Action: %s | Distance from Initial Pose: %.2fmm" % [bone_name, action, position_distance])

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
