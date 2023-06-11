@tool
extends EditorScript
const UtilityFunctions = preload("res://addons/vsk_many_bone_ik/utility_functions.gd")

# 
const NO_SWING_CONSTRAINT = [[Vector2(90, 90), 180]]
const HEAD_SWING_CONSTRAINT = [[Vector2(70, 110), 15]]
const NECK_SWING_CONSTRAINT = [[Vector2(85, 95), 12]]
const UPPER_CHEST_SWING_CONSTRAINT = UPPER_CHEST_TWIST_CONSTRAINT
const CHEST_SWING_CONSTRAINT = [[Vector2(85, 95), 18]]
const SPINE_SWING_CONSTRAINT = [[Vector2(85, 95), 12], [Vector2(-85, 95), 90]]
const HIPS_SWING_CONSTRAINT = NO_SWING_CONSTRAINT

const HEAD_TWIST_CONSTRAINT = [356, 6]
const NECK_TWIST_CONSTRAINT = [354, 6]
const UPPER_CHEST_TWIST_CONSTRAINT = [354, 11]
const CHEST_TWIST_CONSTRAINT = [354, 11]
const SPINE_TWIST_CONSTRAINT = [356, 7]
const HIPS_TWIST_CONSTRAINT = [356, 6]

const HAND_SWING_CONSTRAINT = [[Vector2(85, 95), 90]]
const LOWER_ARM_SWING_CONSTRAINT = [[Vector2(85, 95), 90]]
const UPPER_ARM_SWING_CONSTRAINT = [[Vector2(85, 95), 90]]
const SHOULDER_SWING_CONSTRAINT = NO_SWING_CONSTRAINT

const HAND_TWIST_CONSTRAINT = [354, 11]
const LOWER_ARM_TWIST_CONSTRAINT = [354, 11]
const UPPER_ARM_TWIST_CONSTRAINT = [354, 11]
const SHOULDER_TWIST_CONSTRAINT = [354, 11]

const FOOT_SWING_CONSTRAINT = [[Vector2(85, 95), 90]]
const LOWER_LEG_SWING_CONSTRAINT = [[Vector2(85, 50), 90]]
const UPPER_LEG_SWING_CONSTRAINT = [[Vector2(85, 95), 90], [Vector2(55, 125), 28], [Vector2(115, 65), 28]]

const UPPER_LEG_TWIST_CONSTRAINT = [354 + 90, 6]
const LOWER_LEG_TWIST_CONSTRAINT = [347 + 90, 13]
const FOOT_TWIST_CONSTRAINT = [354 + 90, 11]

const CONSTRAINTS = {
	"LeftUpperLeg": UPPER_LEG_SWING_CONSTRAINT,
	"RightUpperLeg": UPPER_LEG_SWING_CONSTRAINT,
	"LeftLowerLeg": LOWER_LEG_SWING_CONSTRAINT,
	"RightLowerLeg": LOWER_LEG_SWING_CONSTRAINT,
	"LeftFoot": FOOT_SWING_CONSTRAINT,
	"RightFoot": FOOT_SWING_CONSTRAINT,
	"LeftShoulder": SHOULDER_SWING_CONSTRAINT,
	"RightShoulder": SHOULDER_SWING_CONSTRAINT,
	"LeftUpperArm": UPPER_ARM_SWING_CONSTRAINT,
	"RightUpperArm": UPPER_ARM_SWING_CONSTRAINT,
	"LeftLowerArm": LOWER_ARM_SWING_CONSTRAINT,
	"RightLowerArm": LOWER_ARM_SWING_CONSTRAINT,
	"LeftHand": HAND_SWING_CONSTRAINT,
	"RightHand": HAND_SWING_CONSTRAINT,
}

func generate_config():
	var new_config = {
		"Hips": create_entry(HIPS_SWING_CONSTRAINT, HIPS_TWIST_CONSTRAINT, "The hips can tilt forward and backward, allowing the legs to swing in a wide arc during walking or running. They can also move side-to-side, enabling the legs to spread apart or come together."),
		"Head": create_entry(HEAD_SWING_CONSTRAINT, HEAD_TWIST_CONSTRAINT, "The head can tilt up (look up) and down (look down), and rotate side-to-side, enabling the character to look left and right."),
		"Neck": create_entry(NECK_SWING_CONSTRAINT, NECK_TWIST_CONSTRAINT, "The neck can tilt up and down, allowing the head to look up and down, and rotate side-to-side for looking left and right."),
		"UpperChest": create_entry(UPPER_CHEST_SWING_CONSTRAINT, UPPER_CHEST_TWIST_CONSTRAINT, "The upper chest can tilt forward and backward, allowing for natural breathing and posture adjustments."),
		"Chest": create_entry(CHEST_SWING_CONSTRAINT, CHEST_TWIST_CONSTRAINT, "The chest can tilt forward and backward, allowing for natural breathing and posture adjustments."),
		"Spine": create_entry(SPINE_SWING_CONSTRAINT, SPINE_TWIST_CONSTRAINT, "The spine can tilt forward and backward, allowing for bending and straightening of the torso.")
	}

	for side in ["Left", "Right"]:
		var mirror = side == "Right"
		new_config[side + "UpperLeg"] = create_entry(CONSTRAINTS[side + "UpperLeg"], UPPER_LEG_TWIST_CONSTRAINT, "The upper leg can swing forward and backward, allowing for steps during walking and running, and rotate slightly for sitting.", mirror)
		new_config[side + "LowerLeg"] = create_entry(CONSTRAINTS[side + "LowerLeg"], LOWER_LEG_TWIST_CONSTRAINT, "The knee can bend and straighten, allowing the lower leg to move towards or away from the upper leg during walking, running, and stepping.", mirror)
		new_config[side + "Foot"] = create_entry(CONSTRAINTS[side + "Foot"], FOOT_TWIST_CONSTRAINT, "The ankle can tilt up (dorsiflexion) and down (plantarflexion), allowing the foot to step and adjust during walking and running. It can also rotate slightly inward or outward (inversion and eversion) for balance.", mirror)
		new_config[side + "Shoulder"] = create_entry(CONSTRAINTS[side + "Shoulder"], SHOULDER_TWIST_CONSTRAINT, "The shoulder can tilt forward and backward, allowing the arms to swing in a wide arc. They can also move side-to-side, enabling the arms to extend outwards or cross over the chest.", mirror)
		new_config[side + "UpperArm"] = create_entry(CONSTRAINTS[side + "UpperArm"], UPPER_ARM_TWIST_CONSTRAINT, "The upper arm can swing forward and backward, allowing for reaching and swinging motions. It can also rotate slightly for more natural arm movement.", mirror)
		new_config[side + "LowerArm"] = create_entry(CONSTRAINTS[side + "LowerArm"], LOWER_ARM_TWIST_CONSTRAINT, "The elbow can bend and straighten, allowing the forearm to move towards or away from the upper arm during reaching and swinging motions.", mirror)
		new_config[side + "Hand"] = create_entry(CONSTRAINTS[side + "Hand"], HAND_TWIST_CONSTRAINT, "The wrist can tilt up and down, allowing the hand to move towards or away from the forearm. It can also rotate slightly, enabling the hand to twist inward or outward for grasping and gesturing.", mirror)
	return new_config

func create_entry(rotation_swing_constraint: Array, rotation_twist_constraint: Array = [90, 90], comment: String = "", mirror: bool = false) -> Dictionary:
	if mirror:
		var mirrored_directions = []
		for d in rotation_swing_constraint:
			var center: Vector3 = UtilityFunctions.spherical_to_cartesian(d[0])
			center.x = -center.x
			mirrored_directions.append([UtilityFunctions.cartesian_to_spherical(center), d[1]])
		rotation_swing_constraint = mirrored_directions

	var clamped_rotation_swing_constraint = []
	for constraint in rotation_swing_constraint:
		var radius = constraint[0].x
		var clamped_radius = min(radius, 89.9)
		clamped_rotation_swing_constraint.append([Vector2(clamped_radius, constraint[0].y), constraint[1]])

	return {
		"twist_angle_limits": rotation_twist_constraint,
		"swing_constraints_spherical": clamped_rotation_swing_constraint,
		"comment": comment
	}
	
@export
var config: Dictionary = generate_config()

func _run():
	var root: Node3D = get_editor_interface().get_edited_scene_root() as Node3D
	if root == null:
		return
	var properties: Array[Dictionary] = root.get_property_list()
	var iks: Array[Node] = root.find_children("*", "ManyBoneIK3D")
	var skeletons: Array[Node] = root.find_children("*", "Skeleton3D")
	if skeletons.is_empty():
		return
	var skeleton: Skeleton3D = skeletons[0]
	for ik in iks:
		ik.free()
	
	var initial_global_poses = UtilityFunctions.get_initial_global_poses(skeleton)
	var new_ik: ManyBoneIK3D = UtilityFunctions.create_new_ik(skeleton, root)
	UtilityFunctions.set_constraints(config, skeleton, new_ik)
	var targets: Dictionary = {
		"Root": "ManyBoneIK3D",
		"Hips": "ManyBoneIK3D",
		"Head": "ManyBoneIK3D",
		"LeftHand": "ManyBoneIK3D",
		"LeftFoot": "ManyBoneIK3D",
		"RightHand": "ManyBoneIK3D",
		"RightFoot": "ManyBoneIK3D",
	}	
	UtilityFunctions.setup_targets(targets, skeleton, new_ik)
	UtilityFunctions.print_bone_report(config, get_editor_interface().get_edited_scene_root().find_children("*", "Skeleton3D"), targets, initial_global_poses)
