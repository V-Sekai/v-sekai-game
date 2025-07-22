@tool
extends SarSimulationComponentSkeletonIK3D
class_name VskSimulationComponentSkeletonIK3D


var spine_ik: RenIKSpineModifier3D
var chest_ik: RenIKSpineModifier3D
var left_hand_ik: RenIKLimbModifier3D
var right_hand_ik: RenIKLimbModifier3D
var left_foot_ik: RenIKLimbModifier3D
var right_foot_ik: RenIKLimbModifier3D
var foot_placement: RenIKPlacement3D

var foot_placement_left_leg_target: Node3D
var foot_placement_right_leg_target: Node3D
var foot_placement_hips_target: Node3D
var head_attachment_target: Node3D

func _get_motion_scale() -> float:
	return 1.0

func create_ik_modifiers():
	super.create_ik_modifiers()

	var uchest_bone: int = _skeleton.find_bone("UpperChest")
	var chest_bone: int
	# For models that do not have upper chest, we cannot use the Chest bone for chest tracking,
	# because the chest bone alone cannot correct for the rotation.
	if uchest_bone == -1:
		chest_bone = _skeleton.find_bone("Spine")
	else:
		chest_bone = _skeleton.find_bone("Chest")

	# This might create an incorrect chest offset on some models.
	# We might want to detect missing UpperChest in rig_to_rig_calibrator
	# and calibrate to the Spine bone
	print("Create IK Modifiers")

	foot_placement = _skeleton.get_node_or_null(^"RenIKPlacement3D")
	if foot_placement == null:
		var tmp := SkeletonModifier3D.new()
		tmp.script = RenIKPlacement3D
		foot_placement = ((tmp as Node3D) as RenIKPlacement3D)
		foot_placement.name = "RenIKPlacement3D"
		foot_placement_left_leg_target = Marker3D.new()
		foot_placement_left_leg_target.name = "LeftLegTarget"
		foot_placement_left_leg_target.transform = _skeleton.get_bone_global_pose(_skeleton.find_bone("LeftFoot"))
		foot_placement.add_child(foot_placement_left_leg_target)
		foot_placement_right_leg_target = Marker3D.new()
		foot_placement_right_leg_target.name = "RightLegTarget"
		foot_placement_right_leg_target.transform = _skeleton.get_bone_global_pose(_skeleton.find_bone("RightFoot"))
		foot_placement.add_child(foot_placement_right_leg_target)
		foot_placement_hips_target = Marker3D.new()
		foot_placement_hips_target.name = "HipsTarget"
		foot_placement_hips_target.transform = _skeleton.get_bone_global_pose(_skeleton.find_bone("Hips"))
		foot_placement.add_child(foot_placement_hips_target)
		foot_placement.skeleton = _skeleton
		foot_placement.armature_left_foot_target = ^"LeftLegTarget"
		foot_placement.armature_right_foot_target = ^"RightLegTarget"
		foot_placement.armature_hip_target = ^"HipsTarget"
		_skeleton.add_child(foot_placement)
		foot_placement.armature_skeleton_path = ^".."

	spine_ik = _skeleton.get_node_or_null(^"SpineIK")
	if spine_ik == null:
		spine_ik = RenIKSpineModifier3D.new()
		spine_ik.name = "SpineIK"
		spine_ik.chest_bone = _skeleton.get_bone_name(chest_bone)
		_skeleton.add_child(spine_ik)
		spine_ik.owner = _skeleton.owner
	chest_ik = _skeleton.get_node_or_null(^"ChestIK")
	if chest_ik == null:
		chest_ik = RenIKSpineModifier3D.new()
		chest_ik.name = "ChestIK"
		chest_ik.root_bone = _skeleton.get_bone_name(uchest_bone)
		_skeleton.add_child(chest_ik)
		chest_ik.owner = _skeleton.owner
	left_hand_ik = _skeleton.get_node_or_null(^"LeftHand")
	if left_hand_ik == null:
		left_hand_ik = RenIKLimbModifier3D.new()
		left_hand_ik.name = "LeftHand"
		left_hand_ik.preset = RenIKLimbModifier3D.LEFT_HAND
		left_hand_ik.assign_arm_defaults.call()
		left_hand_ik.stretchiness = 0.25
		_skeleton.add_child(left_hand_ik)
		left_hand_ik.owner = _skeleton.owner
	right_hand_ik = _skeleton.get_node_or_null(^"RightHand")
	print("Create IK Modifiers Right Hand " + str(right_hand_ik))
	if right_hand_ik == null:
		right_hand_ik = RenIKLimbModifier3D.new()
		right_hand_ik.name = "RightHand"
		right_hand_ik.preset = RenIKLimbModifier3D.RIGHT_HAND
		right_hand_ik.assign_arm_defaults.call()
		right_hand_ik.stretchiness = 0.25
		_skeleton.add_child(right_hand_ik)
		right_hand_ik.owner = _skeleton.owner
	left_foot_ik = _skeleton.get_node_or_null(^"LeftFoot")
	if left_foot_ik == null:
		left_foot_ik = RenIKLimbModifier3D.new()
		left_foot_ik.name = "LeftFoot"
		left_foot_ik.preset = RenIKLimbModifier3D.LEFT_FOOT
		left_foot_ik.assign_leg_defaults.call()
		_skeleton.add_child(left_foot_ik)
		left_foot_ik.owner = _skeleton.owner
	left_foot_ik.assign_leg_defaults.call()
	right_foot_ik = _skeleton.get_node_or_null(^"RightFoot")
	if right_foot_ik == null:
		right_foot_ik = RenIKLimbModifier3D.new()
		right_foot_ik.name = "RightFoot"
		right_foot_ik.preset = RenIKLimbModifier3D.RIGHT_FOOT
		right_foot_ik.assign_leg_defaults.call()
		_skeleton.add_child(right_foot_ik)
		right_foot_ik.owner = _skeleton.owner
	right_foot_ik.assign_leg_defaults.call()

### Reference to the simulation's motor component.
#@export var motor: SarSimulationComponentMotor3D = null
