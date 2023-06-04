@tool
extends EditorScript

@export var targets: Dictionary

# This configuration dictionary defines joint constraints for a character rig.
# There are two types of constraints: "bone_name_from_to_range_forward_axis" and "bone_name_sequential_limit_cones".
# The text directions are from the camera looking at the skeleton.
@export var config: Dictionary = {
	# bone_name_sequential_limit_cones:
	# Each key is a bone name, and its value is a list of dictionaries.
	# Each dictionary in the list represents a limit cone with a "center" Vector3 and a "radius" (in radians). Centers can be any normalized Vector3. Radius cannot be 0.
	# The limit cones are applied sequentially and are connected to restrict the rotation of the joint.
	# Has between 1 to 10 cones for each bone.
	#	| No. | Joint Name          | Joint Type        | Constraint Description                      |
	#	|-----|---------------------|-------------------|---------------------------------------------|
	#	| 1   | Spine constraint    | Hinge joint       | Limited twisting motion (left-right)        |
	#	| 2   | Chest constraint    | Hinge joint       | Limited twisting motion (left-right)        |
	#	| 3   | UpperChest constraint | Hinge joint     | Limited twisting motion (left-right)        |
	#	| 4   | Neck constraint     | Hinge joint       | Limited nodding motion (up-down)            |
	#	| 5   | Head constraint     | Hinge joint       | Limited nodding motion (up-down)            |
	#	| 6   | LeftEye constraint  | Ball and socket joint | Limited eye movement (up-down, left-right) |
	#	| 7   | LeftShoulder constraint | Ball and socket joint | Limited shoulder rotation (front-back, up-down) |
	#	| 8   | LeftUpperArm constraint | Hinge joint   | Limited upper arm rotation (front-back, up-down) |
	#	| 9   | LeftLowerArm constraint | Hinge joint   | Limited lower arm rotation (front-back)    |
	#	| 10  | LeftHand constraint | Ball and socket joint | Limited hand rotation (up-down, left-right) |
	#	| 11  | LeftUpperLeg constraint | Ball and socket joint | Limited upper leg rotation (front-back, up-down) |
	#	| 12  | LeftLowerLeg constraint | Hinge joint   | Limited lower leg rotation (front-back)    |
	#	| 13  | LeftFoot constraint | Ball and socket joint | Limited foot rotation (up-down, left-right) |
	#	| 14  | LeftToes constraint | Ball and socket joint | Limited toe movement (up-down, left-right) |
	#   Use stubs. Repeat for the right side.
	"bone_name_sequential_limit_cones":
	{
		"Hips": [
			{"center": Vector3(0, -1, 0), "radius": deg_to_rad(30)},
		],
		"Spine": [
			{"center": Vector3(0, 0, 1), "radius": deg_to_rad(20)},
		],
		"Chest": [
			{"center": Vector3(1, 0, 0), "radius": deg_to_rad(20)},
		],
	},
	# Each key is a bone name, and its value is a Vector2.
	# Vector2.x represents the starting angle (in radians), and Vector2.y represents the range of angles from that starting point.
	"bone_name_from_to_range_forward_axis":
	{
		"Hips": Vector2(deg_to_rad(0), deg_to_rad(360)),
		"Spine": Vector2(deg_to_rad(0), deg_to_rad(20)),
		"Chest": Vector2(deg_to_rad(0), deg_to_rad(20)),
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
	new_ik.iterations_per_frame = 5
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
