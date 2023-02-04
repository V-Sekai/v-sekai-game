@tool
extends EditorScript


# The order of tuning human bodies.
# 0. Root
# 1. Root to Hips
# 2. Root to Head
# 3. UpperChest to Hands
# 4. Hips to Legs

var is_humanoid : bool = true
var is_thumbs_up : bool = false
	
@export var targets : Dictionary = {
	"Hips": "ManyBoneIK3D",
	"Head": "Hips",
	"LeftFoot": "Hips", 
	"RightFoot": "Hips", 
	"LeftHand": "Hips",
#	"LeftLowerArm": "Hips",
	"RightHand": "Hips",
#	"RightLowerArm": "Hips",
#	"LeftIndexDistal": "LeftHand",
#	"LeftLittleDistal": "LeftHand", 
#	"LeftMiddleDistal": "LeftHand", 
#	"LeftRingDistal": "LeftHand", 
#	"LeftThumbDistal": "LeftHand",
#	"RightIndexDistal": "RightHand", 
#	"RightLittleDistal": "RightHand", 
#	"RightMiddleDistal": "RightHand", 
#	"RightRingDistal": "RightHand", 
#	"RightThumbDistal": "RightHand", 
	}


static func copy_kusudama(p_bone_name_from : String, p_bone_name_to : PackedStringArray, p_ik : ManyBoneIK3D, p_mirror : Vector3):
	if is_zero_approx(p_mirror.length_squared()):
		p_mirror = Vector3(0, 1, 0)
	var from = p_ik.find_constraint(p_bone_name_from)
	for bone_name_to in p_bone_name_to:
		var to = p_ik.find_constraint(bone_name_to)
		var cone_count = p_ik.get_kusudama_limit_cone_count(from)
		p_ik.set_kusudama_limit_cone_count(to, cone_count)
		for cone_i in range(cone_count):
			p_ik.set_kusudama_limit_cone_center(to, cone_i, p_ik.get_kusudama_limit_cone_center(from, cone_i) * p_mirror)
			p_ik.set_kusudama_limit_cone_radius(to, cone_i, p_ik.get_kusudama_limit_cone_radius(from, cone_i))
		var twist = p_ik.get_kusudama_twist(from)
		p_ik.set_kusudama_twist(to, twist * p_mirror.normalized().sign().x)


@export	var config : Dictionary = {
		"bone_name_from_to_twist": {
			"Spine": Vector2(deg_to_rad(355), deg_to_rad(30)),
			"Chest":  Vector2(deg_to_rad(355), deg_to_rad(30)),
			"UpperChest": Vector2(deg_to_rad(355), deg_to_rad(30)),
			"Head": Vector2(deg_to_rad(0), deg_to_rad(10)),
			"Neck": Vector2(deg_to_rad(356), deg_to_rad(10)),
			"LeftShoulder": Vector2(deg_to_rad(-250), deg_to_rad(-40)),
			"LeftUpperArm": Vector2(deg_to_rad(-120), deg_to_rad(-60)),
			"LeftLowerArm": Vector2(deg_to_rad(-75), deg_to_rad(-60)),
			"LeftHand": Vector2(deg_to_rad(-275), deg_to_rad(-20)),
			"LeftUpperLeg": Vector2(deg_to_rad(160), deg_to_rad(40)),
			"LeftLowerLeg": Vector2(deg_to_rad(90), deg_to_rad(20)),
			"LeftFoot": Vector2(deg_to_rad(180), deg_to_rad(5)),
			"LeftEye": Vector2(deg_to_rad(180), deg_to_rad(5)),
		},
		"bone_name_cones": {
			"Hips": [{"center": Vector3(0, -1, 0), "radius": deg_to_rad(10)}],
			"Spine": [{"center": Vector3(0, 1, 0), "radius": deg_to_rad(10)}],
			"UpperChest": [{"center": Vector3(0, 1, 0), "radius": deg_to_rad(5)}],
			"Chest": [{"center": Vector3(0, 1, 0), "radius": deg_to_rad(10)}],
			"Neck": [{"center": Vector3(0, 1, 0), "radius": deg_to_rad(15)}],
			"Head": [{"center": Vector3(0, 1, 0), "radius": deg_to_rad(15)}],
			"LeftEye": [{"center": Vector3(0, 1, 0), "radius": deg_to_rad(10)}],
			"LeftShoulder": [{"center": Vector3(1, 0,  0), "radius": deg_to_rad(15)}],
			"LeftUpperArm":  [
				{"center": Vector3(0.2, 1, -0.5), "radius": deg_to_rad(40)},
				{"center": Vector3(1, 0, 0), "radius": deg_to_rad(20)},
			],
			"LeftLowerArm":  [
				{"center": Vector3(0, 0, 1), "radius": deg_to_rad(20)},
				{"center": Vector3(0, 0.8, 0), "radius": deg_to_rad(20)},
			],
			"LeftHand":  [{"center": Vector3(0, 1, 0), "radius": deg_to_rad(20)}],

			"LeftLowerLeg":  [
				{"center": Vector3(0, 1, 0), "radius": deg_to_rad(20)},
				{"center": Vector3(0, 0.8, -1), "radius": deg_to_rad(40)},
			],
			"LeftFoot":  [{"center": Vector3(0, -1, 0), "radius": deg_to_rad(20)}],
			"LeftToes":  [{"center": Vector3(1, 0, 0), "radius": deg_to_rad(5)}],
		},
	}

func _run():	
	var root : Node3D = get_editor_interface().get_edited_scene_root()
	if root == null:
		return
	var properties : Array[Dictionary] = root.get_property_list()
	for property in properties:
		if property["name"] == "update_in_editor":
			root.set("update_in_editor", true)
	var iks : Array[Node] = root.find_children("*", "ManyBoneIK3D")
	var skeletons : Array[Node] = root.find_children("*", "Skeleton3D")
	var skeleton : Skeleton3D = skeletons[0]
	for ik in iks:
		ik.free()
	var new_ik : ManyBoneIK3D = ManyBoneIK3D.new()
	skeleton.add_child(new_ik, true)
	new_ik.skeleton_node_path = ".."
	new_ik.owner = root
	new_ik.iterations_per_frame = 15
	new_ik.queue_print_skeleton()
#	new_ik.constraint_mode = true
	skeleton.reset_bone_poses()
	var humanoid_profile : SkeletonProfileHumanoid = SkeletonProfileHumanoid.new()
	var humanoid_bones : PackedStringArray = []
	for profile_i in humanoid_profile.bone_size:
		var bone_name : String = humanoid_profile.get_bone_name(profile_i)
		humanoid_bones.push_back(bone_name)
	
	var skeleton_profile = SkeletonProfileHumanoid.new()
	var human_bones : Array
	var bone_name_from_to_twist = config["bone_name_from_to_twist"]
	var bone_name_cones = config["bone_name_cones"]
	
	for bone_i in skeleton.get_bone_count():
		var bone_name : String = skeleton.get_bone_name(bone_i)
		new_ik.set_kusudama_twist(bone_i, Vector2(0, TAU))
		new_ik.set_kusudama_limit_cone_count(bone_i, 0)
		var twist_keys : Array = bone_name_from_to_twist.keys()
		if twist_keys.has(bone_name):
			new_ik.set_pin_weight(bone_i, 1)
			var twist : Vector2 = bone_name_from_to_twist[bone_name]
			new_ik.set_kusudama_twist(bone_i, twist)
		var cone_keys = bone_name_cones.keys()
		if cone_keys.has(bone_name):
			var cones : Array = bone_name_cones[bone_name]
			new_ik.set_kusudama_limit_cone_count(bone_i, cones.size())
			for cone_i in range(cones.size()):
				var cone : Dictionary = cones[cone_i]
				if cone.keys().has("center"):
					new_ik.set_kusudama_limit_cone_center(bone_i, cone_i, cone["center"])
				if cone.keys().has("radius"):
					new_ik.set_kusudama_limit_cone_radius(bone_i, cone_i, cone["radius"])
	var keys = targets.keys()
	for target_i in keys.size():
		tune_bone(new_ik, skeleton, keys[target_i], targets[keys[target_i]], root)

	copy_kusudama("LeftUpperArm", ["RightUpperArm"], new_ik, Vector3(-1, 1, 1))
	copy_kusudama("LeftShoulder", ["RightShoulder"], new_ik, Vector3(-1, 1, 1))
	copy_kusudama("LeftLowerArm", ["RightLowerArm"], new_ik, Vector3(-1, 1, 1))
	copy_kusudama("LeftHand", ["RightHand"], new_ik, Vector3(-1, 1, 1))
	copy_kusudama("LeftUpperLeg", ["RightUpperLeg"], new_ik, Vector3(-1, 1, 1))
	copy_kusudama("LeftLowerLeg", ["RightLowerLeg"], new_ik, Vector3(1, 1, 1))
	copy_kusudama("LeftFoot", ["RightFoot"], new_ik, Vector3(1, 1, 1))
	copy_kusudama("LeftToes", ["RightToes"], new_ik, Vector3(1, 1, 1))
	copy_kusudama("LeftEyes", ["RightEyes"], new_ik, Vector3(1, 1, 1))
	copy_kusudama("Spine", ["Chest"], new_ik, Vector3(1, 1, 1))
	copy_kusudama("Spine", ["UpperChest"], new_ik, Vector3(1, 1, 1))
	
func tune_bone(new_ik : ManyBoneIK3D, skeleton : Skeleton3D, bone_name : String, bone_name_parent : String, owner):
	var node_3d : Marker3D = Marker3D.new()
	node_3d.gizmo_extents = 0.01
	node_3d.name = bone_name
	var bone_i = skeleton.find_bone(bone_name)
	var children : Array[Node] = owner.find_children("*", "")
	var parent : Node = null
	for node in children:
		if str(node.name) == bone_name_parent:
			print(node.name)
			node.add_child(node_3d, true)
			parent = node
			node_3d.owner = owner
			break
	node_3d.global_transform = skeleton.global_transform.affine_inverse() * skeleton.get_bone_global_pose_no_override(bone_i)
	if not children.size():
		new_ik.add_child(node_3d, true)
	if bone_name in ["Head"]:
		# Move slightly higher to avoid the crunching into the body effect.
		node_3d.transform.origin = node_3d.get_parent_node_3d().global_transform.affine_inverse() * node_3d.global_transform.origin + Vector3(0, 0.1, 0)
	if bone_name in ["LeftHand"]:
		if is_thumbs_up:
			node_3d.global_transform.basis = Basis.from_euler(Vector3(0, 0, -PI / 2))
	if bone_name in ["RightHand"]:
		if is_thumbs_up:
			node_3d.global_transform.basis = Basis.from_euler(Vector3(0, 0, PI / 2))
	if bone_name.ends_with("Distal"):
		new_ik.set_pin_direction_priorities(bone_i, Vector3())
	if bone_name in ["LeftFoot", "RightFoot"]:
		node_3d.global_transform.origin = node_3d.global_transform.origin + Vector3(0, -0.1, 0)
		node_3d.global_transform.basis = Basis.from_euler(Vector3(0, PI, 0))
	node_3d.owner = new_ik.owner
	new_ik.set_pin_nodepath(bone_i, new_ik.get_path_to(node_3d))
