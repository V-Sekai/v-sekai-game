@tool
extends EditorScript

enum Direction {
	RIGHT,
	LEFT,
	UP,
	DOWN,
	FRONT,
	BACK
}

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

	var right_name = "Right" + name.substr(4)
	entry[right_name] = {
		"swing_rotation_center_radius": [],
		"twist_rotation_range": {
			"from": deg_to_rad(twist_rotation_range_from),
			"range": deg_to_rad(twist_rotation_range_range)
		}
	}

	for center_radius in swing_rotation_center_radius:
		var center = center_radius["center"]
		var radius = center_radius["radius"]
		var new_center = Vector3()

		match center:
			Direction.RIGHT:
				new_center = Vector3(-center.x, center.y, center.z)
			Direction.LEFT:
				new_center = Vector3(-center.x, center.y, center.z)
			Direction.UP:
				new_center = Vector3(center.x, -center.y, center.z)
			Direction.DOWN:
				new_center = Vector3(center.x, -center.y, center.z)
			Direction.FRONT:
				new_center = Vector3(center.x, center.y, -center.z)
			Direction.BACK:
				new_center = Vector3(center.x, center.y, -center.z)

		entry[right_name]["swing_rotation_center_radius"].append({"center": new_center, "radius": radius})

	return entry
	
func generate_config():
	var config: Dictionary = {
		"Hips": {
			"swing_rotation_center_radius": [
				{"center": Vector3(0, -1, 0), "radius": deg_to_rad(10)}
			],
			"twist_rotation_range": {
				"from": deg_to_rad(90) + deg_to_rad(180),
				"range": deg_to_rad(5)
			}
		},
		"Spine": {
			"swing_rotation_center_radius": [
				{"center": Vector3(0, 1, 0), "radius": deg_to_rad(15)}
			],
			"twist_rotation_range": {
				"from": deg_to_rad(0),
				"range": deg_to_rad(2.5)
			}
		},
		"Chest": {
			"swing_rotation_center_radius": [
				{"center": Vector3(0, 1, 0), "radius": deg_to_rad(10)}
			],
			"twist_rotation_range": {
				"from": deg_to_rad(0),
				"range": deg_to_rad(15)
			}
		},
		"UpperChest": {
			"swing_rotation_center_radius": [
				{"center": Vector3(0, 1, 0), "radius": deg_to_rad(5)}
			],
			"twist_rotation_range": {
				"from": deg_to_rad(0),
				"range": deg_to_rad(10)
			}
		},
		"Neck": {
			"swing_rotation_center_radius": [
				{"center": Vector3(0, 1, 0), "radius": deg_to_rad(22.5)}
			],
			"twist_rotation_range": {
				"from": deg_to_rad(0),
				"range": deg_to_rad(2.5)
			}
		},
		"Head": {
			"swing_rotation_center_radius": [
				{"center": Vector3(0, 1, 0), "radius": deg_to_rad(2.5)}
			],
			"twist_rotation_range": {
				"from": deg_to_rad(0),
				"range": deg_to_rad(1.25)
			}
		},
	}

	var symmetric_entries = [
		["LeftEye", [{"center": Direction.RIGHT, "radius": deg_to_rad(2.5)}, {"center": Direction.UP, "radius": deg_to_rad(2.5)}], 0, 2.5],
		["LeftShoulder", [{"center": Direction.RIGHT, "radius": deg_to_rad(5)}, {"center": Direction.UP, "radius": deg_to_rad(5)}], 0, 5],
		["LeftUpperArm", [{"center": Direction.RIGHT, "radius": deg_to_rad(25)}, {"center": Direction.FRONT, "radius": deg_to_rad(25)}], 0, 15],
		["LeftLowerArm", [{"center": Direction.UP, "radius": deg_to_rad(30)}, {"center": Direction.RIGHT, "radius": deg_to_rad(30)}, {"center": Direction.BACK, "radius": deg_to_rad(30)}], 50, 10],
		["LeftHand", [{"center": Direction.UP, "radius": deg_to_rad(45)}], 0, 90],
		["LeftUpperLeg", [
			{"center": Direction.RIGHT, "radius": deg_to_rad(30)},
			{"center": Direction.FRONT, "radius": deg_to_rad(30)}], 90, 2.5],
		["LeftLowerLeg", [{"center": Direction.UP, "radius": deg_to_rad(40)}, {"center": Direction.RIGHT, "radius": deg_to_rad(40)}, {"center": Direction.BACK, "radius": deg_to_rad(40)}], 50, 10],
		["LeftFoot", [{"center": Direction.DOWN, "radius": deg_to_rad(45)}, {"center": Direction.FRONT, "radius": deg_to_rad(45)}], 0, 5],
		["LeftToes", [{"center": Direction.DOWN, "radius": deg_to_rad(20)}], 0, 5],
	]

	for entry in symmetric_entries:
		var new_entry = create_symmetric_entry(entry[0], entry[1], entry[2], entry[3])
		for key in new_entry.keys():
			config[key] = new_entry[key]

	return config

@export 
var config: Dictionary = generate_config()


# This configuration dictionary defines joint constraints for a character rig.
#
# The text directions are from the camera looking at the skeleton.
#
# bone_name_sequential_limit_cones:
# - Each key is a bone name, and its value is a list of dictionaries.
# - Each dictionary in the list represents a limit cone with a "center" Vector3 and a "radius" (in radians).
#     - Center is not axis locked. Center defaults to Vector3(0, @ , 0) 
#     - Radius cannot be 0.
# - The limit cones are applied sequentially and are connected to restrict the rotation of the joint.
#
# Has between 1 to 10 cones for each bone:
#
# | Joint Name          | Joint Type        | Constraint Description                      |
# |---------------------|-------------------|---------------------------------------------|
# | Root                | Free              | Any rotation and range                      |
# | Spine               | Hinge             | Limited twisting motion (left-right)        |
# | Chest               | Hinge             | Limited twisting motion (left-right)        |
# | UpperChest          | Hinge             | Limited twisting motion (left-right)        |
# | Neck                | Hinge             | Limited nodding motion (up-down)            |
# | Head                | Hinge             | Limited nodding motion (up-down)            |
# | LeftEye             | Ball and socket   | Limited eye movement (up-down, left-right)  |
# | LeftShoulder        | Ball and socket   | Limited shoulder rotation (front-back, up-down) |
# | LeftUpperArm        | Hinge             | Limited upper arm rotation (front-back, up-down) |
# | LeftLowerArm        | Hinge             | Limited lower arm rotation (front-back)    |
# | LeftHand            | Ball and socket   | Limited hand rotation (up-down, left-right) |
# | LeftUpperLeg        | Ball and socket   | Limited upper leg rotation (front-back, up-down) |
# | LeftLowerLeg        | Hinge             | Limited lower leg rotation (front-back)    |
# | LeftFoot            | Ball and socket   | Limited foot rotation (up-down, left-right) |
# | LeftToes            | Ball and socket   | Limited toe movement (up-down, left-right) |

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
	new_ik.queue_print_skeleton()
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
	if bone_name in ["LeftToes", "RightToes"]:
		new_ik.set_pin_weight(bone_i, 0)
	new_ik.set_pin_nodepath(bone_i, new_ik.get_path_to(node_3d))
