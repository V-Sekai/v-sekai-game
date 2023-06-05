@tool
extends EditorScript

@export 
var targets: Dictionary

@export 
var config: Dictionary = {
	"Hips": {
		"swing_rotation_center_radius": [
			{"center": Vector3(0, -1, 0), "radius": 0.1745329252}  # 10 degrees
		],
		"twist_rotation_range": {
			"from": 1.5707963268,  # 90 degrees
			"range": 0.0872664626  # 5 degrees
		}
	},
	"Spine": {
		"swing_rotation_center_radius": [
			{"center": Vector3(0, 1, 0), "radius": 0.2617993878}  # 15 degrees
		],
		"twist_rotation_range": {
			"from": 0,  # 0 degrees
			"range": 0.0436332313  # 2.5 degrees
		}
	},
	"Chest": {
		"swing_rotation_center_radius": [
			{"center": Vector3(0, 1, 0), "radius": 0.1745329252}  # 10 degrees
		],
		"twist_rotation_range": {
			"from": 0,  # 0 degrees
			"range": 0.2617993878  # 15 degrees
		}
	},
	"UpperChest": {
		"swing_rotation_center_radius": [
			{"center": Vector3(0, 1, 0), "radius": 0.0872664626}  # 5 degrees
		],
		"twist_rotation_range": {
			"from": 0,  # 0 degrees
			"range": 0.1745329252  # 10 degrees
		}
	},
	"Neck": {
		"swing_rotation_center_radius": [
			{"center": Vector3(0, 1, 0), "radius": 0.3926990817}  # 22.5 degrees
		],
		"twist_rotation_range": {
			"from": 0,  # 0 degrees
			"range": 0.0436332313  # 2.5 degrees
		}
	},
	"Head": {
		"swing_rotation_center_radius": [
			{"center": Vector3(0, 1, 0), "radius": 0.0436332313}  # 2.5 degrees
		],
		"twist_rotation_range": {
			"from": 0,  # 0 degrees
			"range": 0.02181661565  # 1.25 degrees
		}
	},	
	"LeftEye": {
		"swing_rotation_center_radius": [
			{"center": Vector3(1, 0, 0), "radius": 0.0436332313},  # 2.5 degrees
			{"center": Vector3(0, 1, 0), "radius": 0.0436332313}   # 2.5 degrees
		],
		"twist_rotation_range": {
			"from": 0,  # 0 degrees
			"range": 0.0436332313  # 2.5 degrees
		}
	},
	"LeftShoulder": {
		"swing_rotation_center_radius": [
			{"center": Vector3(1, 0.5, 0), "radius": 0.436332312},  # 25 degrees
			{"center": Vector3(0, 1, 0.5), "radius": 0.3490658504},   # 20 degrees
		],
		"twist_rotation_range": {
			"from": 0,  # 0 degrees
			"range": 0.3490658504  # 20 degrees
		}
	},
	"LeftUpperArm": {
		"swing_rotation_center_radius": [
			{"center": Vector3(1, 0, 0.25), "radius": 0.523598776},  # 30 degrees
			{"center": Vector3(0, -0.25, 1), "radius": 0.523598776}   # 30 degrees
		],
		"twist_rotation_range": {
			"from": 0,  # 0 degrees
			"range": 0.3490658504  # 20 degrees
		}
	},
	"LeftLowerArm": {
		"swing_rotation_center_radius": [
			{"center": Vector3(1, 0, 0), "radius": 0.3490658504},  # 20 degrees - Top segment
			{"center": Vector3(0, 1, 0), "radius": 0.3490658504}   # 20 degrees - Middle segment (flipped front to back)
		],
		"twist_rotation_range": {
			"from": 0,  # 0 degrees
			"range": 0.2617993878  # 15 degrees
		}
	},
	"LeftHand": {
		"swing_rotation_center_radius": [
			{"center": Vector3(0, 1, 0), "radius": 0.7853981634},  # 45 degrees
		],
		"twist_rotation_range": {
			"from": 0,  # 0 degrees
			"range": 1.5707963268  # 90 degrees
		}
	},
	"LeftUpperLeg": {
		"swing_rotation_center_radius": [
			{"center": Vector3(0, -1, 0), "radius": 1.308996939}, # 75 degrees
		],
		"twist_rotation_range": {
			"from": 0,            # 0 degrees
			"range": 0.1745329252  # 10 degrees
		}
	},
	"LeftLowerLeg": {
		"swing_rotation_center_radius": [
			{"center": Vector3(0, 1, -0.5), "radius": 0.698131701},  # 40 degrees - Top segment
			{"center": Vector3(1, 0, -0.5), "radius": 0.698131701},  # 40 degrees - Middle segment
			{"center": Vector3(0, 0, -1), "radius": 0.698131701}     # 40 degrees - Bottom segment
		],
		"twist_rotation_range": {
			"from": 0.872665,            # 50 degrees
			"range": 0.1745329252  # 10 degrees
		}
	},
	"LeftFoot": {
		"swing_rotation_center_radius": [
			{"center": Vector3(0, -1, 0), "radius": 0.7853981634},  # 45 degrees
			{"center": Vector3(0, 0, 1), "radius": 0.7853981634}  # 45 degrees
		],
		"twist_rotation_range": {
			"from": 0,  # 0 degrees
			"range": 0.0872664626  # 5 degrees
		}
	},
	"LeftToes": {
		"swing_rotation_center_radius": [
			{"center": Vector3(0, -1, 0), "radius": 0.3490658504}  # 20 degrees
		],
		"twist_rotation_range": {
			"from": 0,  # 0 degrees
			"range": 0.0872664626  # 5 degrees
		}
	},
	"RightEye": {
		"swing_rotation_center_radius": [
			{"center": Vector3(-1, 0, 0), "radius": 0.0436332313},  # 2.5 degrees
			{"center": Vector3(0, 1, 0), "radius": 0.0436332313}   # 2.5 degrees
		],
		"twist_rotation_range": {
			"from": 0,  # 0 degrees
			"range": 0.0436332313  # 2.5 degrees
		}
	},
	"RightShoulder": {
		"swing_rotation_center_radius": [
			{"center": Vector3(-1, 0.5, 0), "radius": 0.436332312},  # 25 degrees
			{"center": Vector3(0, 1, -0.5), "radius": 0.3490658504},   # 20 degrees
		],
		"twist_rotation_range": {
			"from": 0,  # 0 degrees
			"range": 0.3490658504  # 20 degrees
		}
	},
	"RightUpperArm": {
		"swing_rotation_center_radius": [
			{"center": Vector3(-0.25, 0, 1), "radius": 0.523598776},  # 30 degrees
			{"center": Vector3(-1, 0.25, 0), "radius": 0.523598776}   # 30 degrees
		],
		"twist_rotation_range": {
			"from": 0,  # 0 degrees
			"range": 0.3490658504  # 20 degrees
		}
	},
	"RightLowerArm": {
		"swing_rotation_center_radius": [
			{"center": Vector3(-1, 0, 0), "radius": 0.3490658504},  # 20 degrees - Top segment
			{"center": Vector3(0, 1, 0), "radius": 0.3490658504},   # 20 degrees - Middle segment
		],
		"twist_rotation_range": {
			"from": 0,  # 0 degrees
			"range": 0.2617993878  # 15 degrees
		}
	},
	"RightHand": {
		"swing_rotation_center_radius": [
			{"center": Vector3(0, 1, 0), "radius": 0.7853981634},  # 45 degrees
		],
		"twist_rotation_range": {
			"from": 0,  # 0 degrees
			"range": 1.5707963268  # 90 degrees
		}
	},
	"RightUpperLeg": {
		"swing_rotation_center_radius": [
			{"center": Vector3(0, -1, 0), "radius": 1.308996939}, # 75 degrees
		],
		"twist_rotation_range": {
			"from": 0,            # 0 degrees
			"range": 0.1745329252  # 10 degrees
		}
	},
	"RightLowerLeg": {
		"swing_rotation_center_radius": [
			{"center": Vector3(1, 0, -0.5), "radius": 0.698131701},  # 40 degrees - Top segment
			{"center": Vector3(0, 1, -0.5), "radius": 0.698131701},  # 40 degrees - Middle segment
			{"center": Vector3(0, 0, -1), "radius": 0.698131701}     # 40 degrees - Bottom segment
		],
		"twist_rotation_range": {
			"from": 0.872665,            # 50 degrees
			"range": 0.1745329252  # 10 degrees
		}
	},
	"RightFoot": {
		"swing_rotation_center_radius": [
			{"center": Vector3(0, -1, 0), "radius": 0.7853981634},  # 45 degrees
			{"center": Vector3(0, 0, 1), "radius": 0.7853981634}  # 45 degrees
		],
		"twist_rotation_range": {
			"from": 0,  # 0 degrees
			"range": 0.0872664626  # 5 degrees
		}
	},
	"RightToes": {
		"swing_rotation_center_radius": [
			{"center": Vector3(0, -1, 0), "radius": 0.3490658504}  # 20 degrees
		],
		"twist_rotation_range": {
			"from": 0,  # 0 degrees
			"range": 0.0872664626  # 5 degrees
		}
	},
}

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
	var targets: Dictionary = {}
	targets["Root"] = "ManyBoneIK3D"
	targets["Hips"] = "ManyBoneIK3D"
	targets["Head"] = "ManyBoneIK3D"
	# targets["LeftLowerArm"] = "ManyBoneIK3D"
	targets["LeftHand"] = "ManyBoneIK3D"
	# targets["RightLowerArm"] = "ManyBoneIK3D"
	targets["RightHand"] = "ManyBoneIK3D"
	targets["LeftFoot"] = "ManyBoneIK3D"
	targets["RightFoot"] = "ManyBoneIK3D"

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
