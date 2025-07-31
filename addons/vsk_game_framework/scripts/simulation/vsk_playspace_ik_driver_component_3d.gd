@tool
extends Node3D
class_name VskPlayspaceIKDriverComponent3D

const calibration_orchestrator = preload("res://addons/xr_rig_calibrator/calibration_orchestrator.gd")
const calibrated_tracker = preload("res://addons/xr_rig_calibrator/calibrated_tracker.gd")
const rig_to_rig_calibrator = preload("res://addons/xr_rig_calibrator/rig_to_rig_calibrator.gd")

## Base class for controlling a camera system for the player's simulation space.

var calibrated_tracker_cache: Dictionary[String, calibrated_tracker]

func _on_ik_created():
	avatar_calibrated_rig.target_skel = skeleton_ik_component._skeleton
	avatar_calibrated_rig.target_skel.show_rest_only = true
	player_calibrated_rig.skel.show_rest_only = true
	for bone_name in ["Hips", "LeftFoot", "RightFoot", "Head", "LeftHand", "RightHand"]:
		var node: Node3D = player_calibrated_rig.get_node_or_null(bone_name)
		if node != null:
			node.transform = player_calibrated_rig.skel.get_bone_global_rest(player_calibrated_rig.skel.find_bone(bone_name))
	var old_basis: Basis = player_calibrated_rig.global_basis

	# Calculate armspan factor for scaling
	var hips_player_xform: Transform3D = player_calibrated_rig.skel.get_bone_global_rest(player_calibrated_rig.skel.find_bone("Hips"))
	var hips_avatar_xform: Transform3D = avatar_calibrated_rig.target_skel.get_bone_global_rest(avatar_calibrated_rig.target_skel.find_bone("Hips"))
	var left_hand_player_xform: Transform3D = player_calibrated_rig.skel.get_bone_global_rest(player_calibrated_rig.skel.find_bone("LeftHand"))
	var right_hand_player_xform: Transform3D = player_calibrated_rig.skel.get_bone_global_rest(player_calibrated_rig.skel.find_bone("RightHand"))
	var left_hand_avatar_xform: Transform3D = avatar_calibrated_rig.target_skel.get_bone_global_rest(avatar_calibrated_rig.target_skel.find_bone("LeftHand"))
	var right_hand_avatar_xform: Transform3D = avatar_calibrated_rig.target_skel.get_bone_global_rest(avatar_calibrated_rig.target_skel.find_bone("RightHand"))
	var avatar_armspan: float = left_hand_avatar_xform.origin.distance_to(right_hand_avatar_xform.origin)
	var player_armspan: float = left_hand_player_xform.origin.distance_to(right_hand_player_xform.origin)
	var avatar_height: float = (left_hand_avatar_xform.origin + right_hand_avatar_xform.origin).length() / 2
	var player_height: float = (left_hand_player_xform.origin + right_hand_player_xform.origin).length() / 2
	var blended_height_ratio: float = lerpf(avatar_armspan / player_armspan, avatar_height / player_height, armspan_to_height)

	# Stilts / adjust y offset of rig.
	var y_offset_adjust: Vector3 = Vector3(0, blended_height_ratio * player_height - avatar_height, 0)
	avatar_calibrated_rig.stilts_offset_adjust = -y_offset_adjust * blended_height_ratio
	playspace.height_offset = (avatar_height / blended_height_ratio - player_height)

	avatar_calibrated_rig.aux_hip_tracker = skeleton_ik_component.foot_placement.hip_target_spatial
	avatar_calibrated_rig.apply_target_scale = true

	avatar_calibrated_rig.calibrate()
	player_calibrated_rig.global_basis = old_basis
	avatar_calibrated_rig.target_skel.show_rest_only = false
	player_calibrated_rig.skel.show_rest_only = false
	
	skeleton_ik_component.foot_placement.enable_hip_placement = false # true
	skeleton_ik_component.foot_placement.enable_left_foot_placement = false # true
	skeleton_ik_component.foot_placement.enable_right_foot_placement = false # true
	skeleton_ik_component.foot_placement.crouch_ratio = 1.0
	skeleton_ik_component.foot_placement.hunch_ratio = 0.2
	var calibrated_cache_copy := calibrated_tracker_cache.values()
	calibrated_tracker_cache.clear()
	for tracker in calibrated_cache_copy:
		var calibrated := tracker as calibrated_tracker
		if calibrated != null:
			_on_tracker_enabled(calibrated)

func _ready():
	# FIXME: I don't know how to fix this hardcoded path
	# because it's referencing a different scene.
	
	# GDScript bug: "Trying to assign value of type 'rig_to_rig_calibrator.gd' to  a variable of type 'rig_to_rig_calibrator.gd'"
	avatar_calibrated_rig = get_child(0)

	avatar_calibrated_rig.tracker_enabled.connect(_on_tracker_enabled)
	avatar_calibrated_rig.tracker_disabled.connect(_on_tracker_disabled)
	skeleton_ik_component = playspace.simulation.get_node(^"SkeletonIK3DComponent") as SarSimulationComponentSkeletonIK3D
	skeleton_ik_component.ik_created.connect(_on_ik_created)

func _process(p_delta: float):
	if avatar_calibrated_rig != null and playspace != null:
		playspace.height_offset = avatar_calibrated_rig.position.y
	if InputMap.has_action(&"jump") and Input.is_action_just_pressed(&"jump"):
		player_calibrated_rig.calibrate(true)

func _on_tracker_enabled(tracker_node: calibrated_tracker):
	if calibrated_tracker_cache.get(tracker_node.name) == tracker_node:
		return
	calibrated_tracker_cache[tracker_node.name] = tracker_node
	print("ON TRACKER ENABLED " + tracker_node.name)
	match tracker_node.name:
		"Head":
			skeleton_ik_component.spine_ik.head_target = tracker_node
			skeleton_ik_component.chest_ik.head_target = tracker_node
			skeleton_ik_component.foot_placement.armature_head_target = skeleton_ik_component.foot_placement.get_path_to(tracker_node)
			skeleton_ik_component.foot_placement.head_target_spatial = tracker_node
			skeleton_ik_component.foot_placement.enable_hip_placement = false # true
			skeleton_ik_component.foot_placement.enable_left_foot_placement = false # true
			skeleton_ik_component.foot_placement.enable_right_foot_placement = false # true
			if skeleton_ik_component.spine_ik.hip_target == null:
				skeleton_ik_component.spine_ik.hip_target = skeleton_ik_component.foot_placement.hip_target_spatial
			if skeleton_ik_component.spine_ik.hip_target == skeleton_ik_component.foot_placement.hip_target_spatial:
				skeleton_ik_component.foot_placement.enable_hip_placement = true
			if skeleton_ik_component.left_foot_ik.target == null:
				skeleton_ik_component.left_foot_ik.target = skeleton_ik_component.foot_placement.foot_left_target_spatial
			if skeleton_ik_component.left_foot_ik.target == skeleton_ik_component.foot_placement.foot_left_target_spatial:
				skeleton_ik_component.foot_placement.enable_left_foot_placement = true
			if skeleton_ik_component.right_foot_ik.target == null:
				skeleton_ik_component.right_foot_ik.target = skeleton_ik_component.foot_placement.foot_right_target_spatial
			if skeleton_ik_component.right_foot_ik.target == skeleton_ik_component.foot_placement.foot_right_target_spatial:
				skeleton_ik_component.foot_placement.enable_right_foot_placement = true
			#skeleton_ik_component.head_ik.target_node = skeleton_ik_component.head_ik.get_path_to(tracker_node)
			#skeleton_ik_component.head_ik.start()
		"Hips":
			skeleton_ik_component.foot_placement.enable_hip_placement = false
			skeleton_ik_component.spine_ik.hip_target = tracker_node
			skeleton_ik_component.foot_placement.hip_target_spatial = tracker_node
		"LeftFoot":
			skeleton_ik_component.foot_placement.enable_left_foot_placement = false
			skeleton_ik_component.left_foot_ik.target = tracker_node
			skeleton_ik_component.foot_placement.foot_left_target_spatial = tracker_node
		"RightFoot":
			skeleton_ik_component.foot_placement.enable_right_foot_placement = false
			skeleton_ik_component.right_foot_ik.target = tracker_node
			skeleton_ik_component.foot_placement.foot_right_target_spatial = tracker_node
		"Chest":
			skeleton_ik_component.spine_ik.chest_target = tracker_node
			skeleton_ik_component.chest_ik.hip_target = tracker_node
		"LeftHand":
			skeleton_ik_component.left_hand_ik.target = tracker_node
		"RightHand":
			skeleton_ik_component.right_hand_ik.target = tracker_node
		"LeftLowerArm":
			skeleton_ik_component.left_hand_ik.pole_target = tracker_node
		"RightLowerArm":
			skeleton_ik_component.right_hand_ik.pole_target = tracker_node
		"LeftLowerLeg":
			skeleton_ik_component.left_foot_ik.pole_target = tracker_node
		"RightLowerLeg":
			skeleton_ik_component.right_foot_ik.pole_target = tracker_node

func _on_tracker_disabled(tracker_node: calibrated_tracker):
	if calibrated_tracker_cache[tracker_node.name] == tracker_node:
		calibrated_tracker_cache[tracker_node.name] = null
	else:
		push_warning("Mismatched tracker cache " + str(tracker_node.name) + ": " + str(calibrated_tracker_cache[tracker_node.name]) + " vs " + str(tracker_node))
	print("ON TRACKER DISABLED " + tracker_node.name)
	match tracker_node.name:
		"Head":
			skeleton_ik_component.spine_ik.head_target = null
			skeleton_ik_component.foot_placement.head_target_spatial = null
			skeleton_ik_component.foot_placement.enable_hip_placement = false # true
			skeleton_ik_component.foot_placement.enable_left_foot_placement = false # true
			skeleton_ik_component.foot_placement.enable_right_foot_placement = false # true
			if skeleton_ik_component.spine_ik.hip_target == skeleton_ik_component.foot_placement.hip_target_spatial:
				skeleton_ik_component.spine_ik.hip_target = null
			if skeleton_ik_component.left_foot_ik.target == skeleton_ik_component.foot_placement.foot_left_target_spatial:
				skeleton_ik_component.left_foot_ik.target = null
			if skeleton_ik_component.right_foot_ik.target == skeleton_ik_component.foot_placement.foot_right_target_spatial:
				skeleton_ik_component.right_foot_ik.target = null
		"Hips":
			if skeleton_ik_component.foot_placement.head_target_spatial != null:
				skeleton_ik_component.foot_placement.armature_hip_target = skeleton_ik_component.foot_placement.armature_hip_target
				skeleton_ik_component.foot_placement.enable_hip_placement = true
				skeleton_ik_component.spine_ik.hip_target = skeleton_ik_component.foot_placement.hip_target_spatial
			else:
				skeleton_ik_component.spine_ik.hip_target = null
		"LeftFoot":
			if skeleton_ik_component.foot_placement.head_target_spatial != null:
				skeleton_ik_component.foot_placement.armature_left_foot_target = skeleton_ik_component.foot_placement.armature_left_foot_target
				skeleton_ik_component.foot_placement.enable_left_foot_placement = true
				skeleton_ik_component.left_foot_ik.target = skeleton_ik_component.foot_placement.foot_left_target_spatial
			else:
				skeleton_ik_component.left_foot_ik.hip_target = null
		"RightFoot":
			if skeleton_ik_component.foot_placement.head_target_spatial != null:
				skeleton_ik_component.foot_placement.armature_right_foot_target = skeleton_ik_component.foot_placement.armature_right_foot_target
				skeleton_ik_component.foot_placement.enable_right_foot_placement = true
				skeleton_ik_component.right_foot_ik.target = skeleton_ik_component.foot_placement.foot_right_target_spatial
			else:
				skeleton_ik_component.right_foot_ik.hip_target = null

## The camera container we want to be able to modify.
@export var playspace: SarPlayerSimulationPlayspaceComponent3D = null

@export var player_calibrated_rig: calibration_orchestrator = null

@export var avatar_calibrated_rig: rig_to_rig_calibrator = null

@export var armspan_to_height: float = 0.0

var skeleton_ik_component: SarSimulationComponentSkeletonIK3D = null

### The camera associated with this playspace.
#@export var calibrated_rig: Node3D = null
