@tool
extends EditorScript

@export var targets: Dictionary

@export var config: Dictionary = {
	"bone_name_from_to_twist":
	{
		# The Vector2 describes from and range limits.
		"Spine": Vector2(deg_to_rad(355), deg_to_rad(30)),
		"Chest": Vector2(deg_to_rad(355), deg_to_rad(30)),
		"UpperChest": Vector2(deg_to_rad(355), deg_to_rad(30)),
		"Head": Vector2(deg_to_rad(0), deg_to_rad(10)),
		"Neck": Vector2(deg_to_rad(355), deg_to_rad(10)),
		"LeftEye": Vector2(deg_to_rad(180), deg_to_rad(5)),
		"LeftShoulder": Vector2(deg_to_rad(110), deg_to_rad(40)),
		"LeftUpperArm": Vector2(deg_to_rad(240), deg_to_rad(60)),
		"LeftLowerArm": Vector2(deg_to_rad(285), deg_to_rad(120)),
		"LeftHand": Vector2(deg_to_rad(30), deg_to_rad(20)),
		"LeftUpperLeg": Vector2(deg_to_rad(270), deg_to_rad(20)),
		"LeftLowerLeg": Vector2(deg_to_rad(90), deg_to_rad(20)),
		"LeftFoot": Vector2(deg_to_rad(180), deg_to_rad(5)),
	},
	"bone_name_cones":
	{
		"Hips": [{"center": Vector3(0, 1, 0), "radius": deg_to_rad(10)}],
		"Spine": [{"center": Vector3(0, 1, 0), "radius": deg_to_rad(10)}],
		"Chest": [{"center": Vector3(0, 1, 0), "radius": deg_to_rad(10)}],
		"UpperChest": [{"center": Vector3(0, 1, 0), "radius": deg_to_rad(10)}],
		"Neck": [{"center": Vector3(0, 1, 0), "radius": deg_to_rad(30)}],
		"Head": [{"center": Vector3(0, 1, 0), "radius": deg_to_rad(15)}],
		"LeftEye": [{"center": Vector3(0, 1, 0), "radius": deg_to_rad(10)}],
		"LeftShoulder": [{"center": Vector3(1, 0, 0), "radius": deg_to_rad(45)}],
		"LeftUpperArm":
		[
			{"center": Vector3(0.2, 1, -0.5), "radius": deg_to_rad(45)},
			{"center": Vector3(1, 0, 0), "radius": deg_to_rad(30)},
		],
		"LeftLowerArm":
		[
			{"center": Vector3(0, 0, 1), "radius": deg_to_rad(45)},
			{"center": Vector3(0, 0.8, 0), "radius": deg_to_rad(30)},
		],
		"LeftHand": [{"center": Vector3(0, 1, 0), "radius": deg_to_rad(15)}],
		"LeftUpperLeg":
		[
			{"center": Vector3(0, -1, 1), "radius": deg_to_rad(45)},
		],
		"LeftLowerLeg":
		[
			{"center": Vector3(0, -1, 0), "radius": deg_to_rad(20)},
			{"center": Vector3(0, -0.8, 1), "radius": deg_to_rad(40)},
		],
		"LeftFoot": [{"center": Vector3(0, -1, 0), "radius": deg_to_rad(20)}],
		"LeftToes": [{"center": Vector3(1, 0, 0), "radius": deg_to_rad(5)}],
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
	new_ik.iterations_per_frame = 30
	new_ik.queue_print_skeleton()
	new_ik.stabilization_passes = 4
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
	var bone_name_from_to_twist = config["bone_name_from_to_twist"]
	var bone_name_cones = config["bone_name_cones"]
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
		else:
			new_ik.set_pin_weight(bone_i, 0)
			new_ik.set_pin_direction_priorities(bone_i, Vector3())
			new_ik.set_kusudama_limit_cone_count(bone_i, 1)
			new_ik.set_kusudama_limit_cone_radius(bone_i, 0, deg_to_rad(5))
			

	var keys = targets.keys()
	for target_i in keys.size():
		tune_bone(new_ik, skeleton, keys[target_i], targets[keys[target_i]], root)
		
	new_ik.copy_kusudama("LeftUpperArm", ["RightUpperArm"], Vector3(-1, 1, 1))
	new_ik.copy_kusudama("LeftShoulder", ["RightShoulder"], Vector3(-1, 1, 1))
	new_ik.copy_kusudama("LeftLowerArm", ["RightLowerArm"], Vector3(-1, 1, 1))
	new_ik.copy_kusudama("LeftHand", ["RightHand"], Vector3(-1, 1, 1))
	new_ik.copy_kusudama("LeftUpperLeg", ["RightUpperLeg"], Vector3(1, 1, 1))
	new_ik.copy_kusudama("LeftLowerLeg", ["RightLowerLeg"], Vector3(1, 1, 1))
	new_ik.copy_kusudama("LeftFoot", ["RightFoot"], Vector3(1, 1, 1))
	new_ik.copy_kusudama("LeftToes", ["RightToes"], Vector3(1, 1, 1))
	new_ik.copy_kusudama("LeftEye", ["RightEye"], Vector3(1, 1, 1))
	new_ik.copy_kusudama("Spine", ["Chest"], Vector3(1, 1, 1))
	new_ik.copy_kusudama("Spine", ["UpperChest"], Vector3(1, 1, 1))


func tune_bone(new_ik: ManyBoneIK3D, skeleton: Skeleton3D, bone_name: String, bone_name_parent: String, owner):
	var bone_i = skeleton.find_bone(bone_name)
	if bone_i == -1:
		return
	new_ik.set_kusudama_twist(bone_i, Vector2(deg_to_rad(180), deg_to_rad(1)))
	new_ik.set_kusudama_limit_cone_count(bone_i, 0)
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
	if bone_name.find("Hips") != -1:
		new_ik.set_pin_direction_priorities(bone_i, Vector3())
	node_3d.owner = new_ik.owner
	new_ik.set_pin_nodepath(bone_i, new_ik.get_path_to(node_3d))
