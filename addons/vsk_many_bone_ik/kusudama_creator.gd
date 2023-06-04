@tool
extends EditorScript

@export var targets: Dictionary

# This configuration dictionary defines joint constraints for a character rig.
# There are two types of constraints: "bone_name_from_to_range_forward_axis" and "bone_name_sequential_limit_cones".
# The text directions are from the camera looking at the skeleton.
@export var config: Dictionary = {
	# bone_name_sequential_limit_cones:
	# Each key is a bone name, and its value is a list of dictionaries.
	# Each dictionary in the list represents a limit cone with a "center" Vector3 and a "radius" (in radians). Radius cannot be 0.
	# The limit cones are applied sequentially and are connected to restrict the rotation of the joint.
	"bone_name_sequential_limit_cones":
	{
		# Has between 1 to 10 cones for each bone:
		"Hips": [
			{"center": Vector3(0, -1, 0), "radius": deg_to_rad(20)},
		],
		# Spine constraint allows a limited range of twisting motion (left-right).
		"Spine": [
			{"center": Vector3(-1, 0, 0), "radius": deg_to_rad(30)},
			{"center": Vector3(1, 0, 0), "radius": deg_to_rad(30)},
			{"center": Vector3(0, 1, 0), "radius": deg_to_rad(40)}, 
			{"center": Vector3(0, -1, 0), "radius": deg_to_rad(40)},
		],
		# Chest constraint allows a limited range of twisting motion (left-right).
		"Chest": [
			{"center": Vector3(-0.5, 0.5, 0), "radius": deg_to_rad(20)},
			{"center": Vector3(0.5, 0.5, 0), "radius": deg_to_rad(10)},
			{"center": Vector3(0, 0, -1), "radius": deg_to_rad(10)}
		],
		# UpperChest constraint allows a limited range of twisting motion (left-right).
		"UpperChest": [
			{"center": Vector3(-0.5, 0.5, 0), "radius": deg_to_rad(20)},
			{"center": Vector3(0.5, 0.5, 0), "radius": deg_to_rad(10)},
			{"center": Vector3(0, 0, -1), "radius": deg_to_rad(10)}
		],
		# Neck constraint allows a limited range of nodding motion (up-down).
		"Neck": [
			{"center": Vector3(0, 1, 0), "radius": deg_to_rad(50)},
			{"center": Vector3(0, 0, -1), "radius": deg_to_rad(40)}
		],
		# Head constraint allows a limited range of nodding motion (up-down).
		"Head": [
			{"center": Vector3(1, 0, 0), "radius": deg_to_rad(40)},
			{"center": Vector3(0, 0, -1), "radius": deg_to_rad(40)},
			{"center": Vector3(0, 1, 0), "radius": deg_to_rad(160)}
		],
		# LeftEye constraint allows a limited range of eye movement (up-down, left-right).
		"LeftEye": [
			{"center": Vector3(0, 1, 0), "radius": deg_to_rad(15)},
			{"center": Vector3(1, 0, 0), "radius": deg_to_rad(10)},
			{"center": Vector3(0, 0, -1), "radius": deg_to_rad(10)}
		],
		# LeftShoulder constraint allows a limited range of shoulder rotation (front-back, up-down).
		"LeftShoulder": [
			{"center": Vector3(0, 1, 0), "radius": deg_to_rad(15)},
			{"center": Vector3(1, 0, 0), "radius": deg_to_rad(10)},
			{"center": Vector3(0, 0, -1), "radius": deg_to_rad(10)}
		],
		# LeftUpperArm constraint allows a limited range of upper arm rotation (front-back, up-down).
		"LeftUpperArm": [
			{"center": Vector3(0.2, 1, -0.5), "radius": deg_to_rad(80)}, 
			{"center": Vector3(1, 0, 0), "radius": deg_to_rad(50)},
			{"center": Vector3(0, 0, -1), "radius": deg_to_rad(30)}
		],
		# LeftLowerArm constraint allows a limited range of lower arm rotation (front-back).
		"LeftLowerArm": [
			{"center": Vector3(0, 1, 0), "radius": deg_to_rad(10)},
			{"center": Vector3(0, 0, -1), "radius": deg_to_rad(130)},
			{"center": Vector3(1, 0, 0), "radius": deg_to_rad(10)}
		],
		# LeftHand constraint allows a limited range of hand rotation (up-down, left-right).
		"LeftHand": [ 
			{"center": Vector3(0, 1, 0), "radius": deg_to_rad(180)},
			{"center": Vector3(0, 0, -1), "radius": deg_to_rad(180)},
			{"center": Vector3(1, 0, 0), "radius": deg_to_rad(180)}	
		],
		# LeftUpperLeg constraint allows a limited range of upper leg rotation (front-back, up-down).
		"LeftUpperLeg": [
			{"center": Vector3(0, -1, 1), "radius": deg_to_rad(60)},
			{"center": Vector3(1, 0, 0), "radius": deg_to_rad(30)},
			{"center": Vector3(0, 0, -1), "radius": deg_to_rad(30)}
		],
		# LeftLowerLeg constraint allows a limited range of lower leg rotation (front-back).
		"LeftLowerLeg": [
			{"center": Vector3(0, 1, 0), "radius": deg_to_rad(10)},
			{"center": Vector3(0, 0, -1), "radius": deg_to_rad(90)},
			{"center": Vector3(1, 0, 0), "radius": deg_to_rad(10)}
		],
		# LeftFoot constraint allows a limited range of foot rotation (up-down, left-right).
		"LeftFoot": [
			{"center": Vector3(0, 1, 0), "radius": deg_to_rad(5)},
			{"center": Vector3(0, 0, -1), "radius": deg_to_rad(45)},
			{"center": Vector3(-1, 0, 0), "radius": deg_to_rad(90)} 
		],
		# LeftToes constraint allows a limited range of toe movement (up-down, left-right).
		"LeftToes": [
			{"center": Vector3(1, 0, 0), "radius": deg_to_rad(5)},
			{"center": Vector3(0, 1, 0), "radius": deg_to_rad(3)},
			{"center": Vector3(0, 0, -1), "radius": deg_to_rad(3)}
		],
		# Right side bones (mirror of left side)
		"RightEye": [
			{"center": Vector3(0, 1, 0), "radius": deg_to_rad(15)},
			{"center": Vector3(-1, 0, 0), "radius": deg_to_rad(10)},
			{"center": Vector3(0, 0, -1), "radius": deg_to_rad(10)}
		],
		"RightShoulder": [
			{"center": Vector3(0, 1, 0), "radius": deg_to_rad(15)},
			{"center": Vector3(-1, 0, 0), "radius": deg_to_rad(10)},
			{"center": Vector3(0, 0, -1), "radius": deg_to_rad(10)}
		],
		"RightUpperArm": [
			{"center": Vector3(-0.2, 1, -0.5), "radius": deg_to_rad(70)},
			{"center": Vector3(-1, 0, 0), "radius": deg_to_rad(45)},
			{"center": Vector3(0, 0, -1), "radius": deg_to_rad(25)}
		],
		"RightLowerArm": [
			{"center": Vector3(0, 1, 0), "radius": deg_to_rad(2)},
			{"center": Vector3(0, 0, -1), "radius": deg_to_rad(130)},
			{"center": Vector3(-1, 0, 0), "radius": deg_to_rad(2)}
		],
		"RightHand": [
			{"center": Vector3(0, 1, 0), "radius": deg_to_rad(180)},
			{"center": Vector3(0, 0, -1), "radius": deg_to_rad(180)},
			{"center": Vector3(-1, 0, 0), "radius": deg_to_rad(180)}
		],
		"RightUpperLeg": [
			{"center": Vector3(0, -1, 1), "radius": deg_to_rad(60)},
			{"center": Vector3(-1, 0, 0), "radius": deg_to_rad(30)},
			{"center": Vector3(0, 0, -1), "radius": deg_to_rad(30)}
		],
		"RightLowerLeg": [
			{"center": Vector3(0, 1, 0), "radius": deg_to_rad(5)},
			{"center": Vector3(0, 0, -1), "radius": deg_to_rad(90)},
			{"center": Vector3(-1, 0, 0), "radius": deg_to_rad(5)}
		],
		"RightFoot": [
			{"center": Vector3(0, 1, 0), "radius": deg_to_rad(5)},
			{"center": Vector3(0, 0, -1), "radius": deg_to_rad(45)},
			{"center": Vector3(1, 0, 0), "radius": deg_to_rad(90)} 
		],
		"RightToes": [
			{"center": Vector3(-1, 0, 0), "radius": deg_to_rad(5)},
			{"center": Vector3(0, 1, 0), "radius": deg_to_rad(3)},
			{"center": Vector3(0, 0, -1), "radius": deg_to_rad(3)}
		],
	},
	# Each key is a bone name, and its value is a Vector2.
	# Vector2.x represents the starting angle (in radians), and Vector2.y represents the range of angles from that starting point.
	"bone_name_from_to_range_forward_axis":
	{
		"Hips": Vector2(deg_to_rad(90), deg_to_rad(20)),
		"Spine": Vector2(deg_to_rad(185), deg_to_rad(20)),
		"Chest": Vector2(deg_to_rad(360), deg_to_rad(20)),
		"UpperChest": Vector2(deg_to_rad(360), deg_to_rad(20)),
		"Head": Vector2(deg_to_rad(0), deg_to_rad(120)),     
		"Neck": Vector2(deg_to_rad(355), deg_to_rad(20)),
		"LeftEye": Vector2(deg_to_rad(180), deg_to_rad(5)),
		"LeftShoulder": Vector2(deg_to_rad(110), deg_to_rad(40)),
		"LeftUpperArm": Vector2(deg_to_rad(240), deg_to_rad(80)),
		"LeftLowerArm": Vector2(deg_to_rad(0), deg_to_rad(20)),
		"LeftHand": Vector2(deg_to_rad(30), deg_to_rad(20)),
		"LeftUpperLeg": Vector2(deg_to_rad(270), deg_to_rad(20)),
		"LeftLowerLeg": Vector2(deg_to_rad(90), deg_to_rad(5)),
		"LeftFoot": Vector2(deg_to_rad(0), deg_to_rad(5)),
		"LeftToes": Vector2(deg_to_rad(0), deg_to_rad(5)),
		# Right side bones (mirror of left side)
		"RightEye": Vector2(deg_to_rad(180), deg_to_rad(5)),
		"RightShoulder": Vector2(deg_to_rad(250), deg_to_rad(40)),
		"RightUpperArm": Vector2(deg_to_rad(120), deg_to_rad(80)),
		"RightLowerArm": Vector2(deg_to_rad(75), deg_to_rad(110)),
		"RightHand": Vector2(deg_to_rad(330), deg_to_rad(20)),
		"RightUpperLeg": Vector2(deg_to_rad(270), deg_to_rad(20)),
		"RightLowerLeg": Vector2(deg_to_rad(0), deg_to_rad(5)),
		"RightFoot": Vector2(deg_to_rad(0), deg_to_rad(5)),
		"RightToes": Vector2(deg_to_rad(0), deg_to_rad(5)),
	},
}
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
	new_ik.constraint_mode = true
	skeleton.reset_bone_poses()
	var humanoid_profile: SkeletonProfileHumanoid = SkeletonProfileHumanoid.new()
	var humanoid_bones: PackedStringArray = []
	targets["Root"] = "ManyBoneIK3D"
	targets["Hips"] = "ManyBoneIK3D"
	targets["Head"] = "ManyBoneIK3D"
	targets["LeftLowerarm"] = "ManyBoneIK3D"
	targets["LeftHand"] = "ManyBoneIK3D"
	targets["RightLowerarm"] = "ManyBoneIK3D"
	targets["RightHand"] = "ManyBoneIK3D"
	targets["LeftLowerLeg"] = "ManyBoneIK3D"
	targets["LeftFoot"] = "ManyBoneIK3D"
	targets["RightLowerLeg"] = "ManyBoneIK3D"
	targets["RightFoot"] = "ManyBoneIK3D"

	var skeleton_profile = SkeletonProfileHumanoid.new()
	var human_bones: Array
	var bone_name_from_to_twist = config["bone_name_from_to_range_forward_axis"]
	var bone_name_cones = config["bone_name_sequential_limit_cones"]
	for bone_i in skeleton.get_bone_count():
		var bone_name = skeleton.get_bone_name(bone_i)
		if bone_name in ["Root", "UpperChest"]:
			new_ik.set_pin_passthrough_factor(bone_i, 1)
		else:
			new_ik.set_pin_passthrough_factor(bone_i, 0)
		var twist_keys: Array = bone_name_from_to_twist.keys()
		if twist_keys.has(bone_name):
			var twist: Vector2 = bone_name_from_to_twist[bone_name]
			new_ik.set_kusudama_twist(bone_i, twist)
			
		var cone_keys = bone_name_cones.keys()
		if cone_keys.has(bone_name):
			var cones: Array = bone_name_cones[bone_name]
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
	new_ik.set_pin_nodepath(bone_i, new_ik.get_path_to(node_3d))
