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
			var twist_from = bone_config["twist_rotation_range"]["from"]
			var twist_range = bone_config["twist_rotation_range"]["range"]
			var twist_diff = abs(current_pose_basis.get_euler().y - rest_pose_basis.get_euler().y)
			progress = max(progress, min((twist_diff - twist_from) / twist_range, 1.0))

		if bone_config.has("swing_rotation_center_radius"):
			var cones: Array = bone_config["swing_rotation_center_radius"]
			for cone_i in range(cones.size()):
				var cone: Dictionary = cones[cone_i]
				var center = cone["center"]
				var radius = cone["radius"]
				var swing_diff_quat = current_pose_basis.get_rotation_quaternion().inverse() * rest_pose_basis.get_rotation_quaternion()
				var swing_diff_angle = swing_diff_quat.get_angle()
				progress = max(progress, min((swing_diff_angle - center.length()) / radius, 1.0))
	
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

				if progress < 0.25:
					action = "Good"
				elif progress < 0.5:
					action = "Slightly out of range"
				elif progress < 0.75:
					action = "Out of range"
				else:
					action = "Significantly out of range"

				print("Bone: %s | Progress: %.2f | Suggested Action: %s" % [bone_name, progress, action])

func create_symmetric_entry(name, swing_rotation_center_radius, twist_rotation_range_from, twist_rotation_range_range):
	var entry = {
		name: {
			"swing_rotation_center_radius": swing_rotation_center_radius,
			"twist_rotation_range": {
				"from": deg_to_rad(twist_rotation_range_from),
				"range": deg_to_rad(twist_rotation_range_range)
			}
		}
	}
	var right_name = name.replace("Left", "Right")
	entry[right_name] = {
		"swing_rotation_center_radius": [],
		"twist_rotation_range": {
			"from": deg_to_rad(twist_rotation_range_from),
			"range": deg_to_rad(twist_rotation_range_range)
		}
	}

	for center_radius in swing_rotation_center_radius:
		var center = center_radius.get("center", Vector3(0, 1, 0))
		var radius = center_radius["radius"]
		var new_center = Vector3(-center.x, center.y, center.z)

		entry[right_name]["swing_rotation_center_radius"].append({"center": new_center, "radius": radius})

	return entry

func generate_config():
	var config: Dictionary = {
			"Hips": {
				"swing_rotation_center_radius": [
					{"center": Vector3.DOWN, "radius": deg_to_rad(10)}
				],
				"twist_rotation_range": {
					"from": deg_to_rad(90) + deg_to_rad(180),
					"range": deg_to_rad(5)
				}
			},
			"Spine": {
				"swing_rotation_center_radius": [
					{"center": Vector3.UP, "radius": deg_to_rad(15)}
				],
				"twist_rotation_range": {
					"from": deg_to_rad(0),
					"range": deg_to_rad(2.5)
				}
			},
			"Chest": {
				"swing_rotation_center_radius": [
					{"center": Vector3.UP, "radius": deg_to_rad(10)}
				],
				"twist_rotation_range": {
					"from": deg_to_rad(0),
					"range": deg_to_rad(15)
				}
			},
			"UpperChest": {
				"swing_rotation_center_radius": [
					{"center": Vector3.UP, "radius": deg_to_rad(5)}
				],
				"twist_rotation_range": {
					"from": deg_to_rad(0),
					"range": deg_to_rad(10)
				}
			},
			"Neck": {
				"swing_rotation_center_radius": [
					{"center": Vector3.UP, "radius": deg_to_rad(22.5)}
				],
				"twist_rotation_range": {
					"from": deg_to_rad(0),
					"range": deg_to_rad(2.5)
				}
			},
			"Head": {
				"swing_rotation_center_radius": [
					{"center": Vector3.UP, "radius": deg_to_rad(2.5)}
				],
				"twist_rotation_range": {
					"from": deg_to_rad(0),
					"range": deg_to_rad(1.25)
				}
			},
		}

	var symmetric_entries = [
		["LeftEye", [{"center": Vector3.RIGHT, "radius": deg_to_rad(2.5)}, {"center": Vector3.UP, "radius": deg_to_rad(2.5)}], 0, 2.5],
		["LeftShoulder", [{"center": Vector3.RIGHT, "radius": deg_to_rad(4)}, {"center": Vector3.UP, "radius": deg_to_rad(4)}], 0, 4],
		["LeftUpperArm", [{"center": Vector3.RIGHT, "radius": deg_to_rad(20)}, {"center": Vector3.BACK, "radius": deg_to_rad(20)}], 0, 12],
		["LeftLowerArm", [{"center": Vector3.UP, "radius": deg_to_rad(25)}, {"center": Vector3.FORWARD, "radius": deg_to_rad(25)}, {"center": Vector3.DOWN, "radius": deg_to_rad(25)}], 45, 8],
		["LeftHand", [{"center": Vector3.UP, "radius": deg_to_rad(40)}], 0, 80],
		["LeftUpperLeg", [
			{"center": Vector3.RIGHT, "radius": deg_to_rad(25)},
			{"center": Vector3.BACK, "radius": deg_to_rad(25)}], 85, 2],
		["LeftLowerLeg", [{"center": Vector3.UP, "radius": deg_to_rad(35)}, {"center": Vector3.RIGHT, "radius": deg_to_rad(35)}, {"center": Vector3.BACK, "radius": deg_to_rad(35)}], 45, 8],
		["LeftFoot", [{"center": Vector3.DOWN, "radius": deg_to_rad(40)}, {"center": Vector3.BACK, "radius": deg_to_rad(40)}], 0, 4],
		["LeftToes", [{"center": Vector3.DOWN, "radius": deg_to_rad(15)}], 0, 4],
	]

	for entry in symmetric_entries:
		var new_entry = create_symmetric_entry(entry[0], entry[1], entry[2], entry[3])
		for key in new_entry.keys():
			config[key] = new_entry[key]

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
				var twist: Vector2 = Vector2(bone_config["twist_rotation_range"]["from"], bone_config["twist_rotation_range"]["range"])
				new_ik.set_kusudama_twist(bone_i, twist)

			if bone_config.has("swing_rotation_center_radius"):
				var cones: Array = bone_config["swing_rotation_center_radius"]
				new_ik.set_kusudama_limit_cone_count(bone_i, cones.size())
				for cone_i in range(cones.size()):
					var cone: Dictionary = cones[cone_i]
					if cone.keys().has("center"):
						new_ik.set_kusudama_limit_cone_center(bone_i, cone_i, cone["center"])
					if cone.keys().has("radius"):
						new_ik.set_kusudama_limit_cone_radius(bone_i, cone_i, cone["radius"])

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
