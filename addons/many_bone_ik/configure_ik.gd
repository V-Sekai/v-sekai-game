# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# configure_ik.gd
# SPDX-License-Identifier: MIT

@uid("uid://d32516hkodad7") # Generated automatically, do not modify.
@tool
extends EditorScript


func euclidean_distance(p1, p2):
	return p1.distance_to(p2)

func chamfer_distance(set_A, set_B):
	var total_distance = 0.0

	for point_A in set_A:
		var min_distance = INF
		for point_B in set_B:
			var distance = euclidean_distance(point_A, point_B)
			if distance < min_distance:
				min_distance = distance
		total_distance += min_distance

	for point_B in set_B:
		var min_distance = INF
		for point_A in set_A:
			var distance = euclidean_distance(point_B, point_A)
			if distance < min_distance:
				min_distance = distance
		total_distance += min_distance

	return total_distance / (set_A.size() + set_B.size())


func test_chamfer_distance():
	var set_A = [Vector2(1, 2), Vector2(3, 4), Vector2(5, 6)]
	var set_B = [Vector2(7, 8), Vector2(9, 10), Vector2(11, 12)]
	print(chamfer_distance(set_A, set_B))


class LimitCone:
	var direction: Vector3
	var angle: float

	func _init(direction: Vector3, angle: float):
		self.direction = direction
		self.angle = angle

class BoneConstraint:
	var twist_from: float
	var twist_range: float
	var swing_limit_cones: Array
	var resistance: float

	func _init(twist_from: float = 0, twist_range : float = TAU, swing_limit_cones: Array = [], resistance: float = 0):
		self.twist_from = twist_from
		self.twist_range = twist_range
		self.swing_limit_cones = swing_limit_cones
		self.resistance = resistance

var bone_names = ["Root", "Hips", "Spine", "Chest", "UpperChest", "Neck", "Head", "LeftUpperLeg", "RightUpperLeg", "LeftLowerLeg", "RightLowerLeg", "LeftFoot", "RightFoot", "LeftShoulder", "RightShoulder", "LeftUpperArm", "RightUpperArm", "LeftLowerArm", "RightLowerArm", "LeftHand", "RightHand", "LeftThumb", "RightThumb"]
# **Rotation Twist**
# | Body Part       | Description                                                                                                                                                                                                                   |
# |-----------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
# | Head            | The head can rotate side-to-side up to 60-70 degrees, enabling the character to look left and right.                                                                                                   |
# | Neck            | The neck can rotate side-to-side up to 50-60 degrees for looking left and right.                                                                                                       |
# | [Side]UpperLeg  | The upper leg can rotate slightly up to 5-10 degrees for sitting.                                                                                                  |
# | [Side]UpperArm  | The upper arm can also rotate slightly up to 30-40 degrees for more natural arm movement.                                                                             |
# | [Side]Hand      | The wrist can also rotate slightly up to 20-30 degrees, enabling the hand to twist inward or outward for grasping and gesturing.                             |
# | Hips            | The hips can rotate up to 45-55 degrees, allowing for twisting and turning movements.                                                                                                      |
# | Spine           | The spine can rotate up to 20-30 degrees, providing flexibility for bending and twisting.                                                                                                 |
# | Chest           | The chest can rotate up to 15-25 degrees, contributing to the twisting motion of the upper body.                                                                                       |
# | UpperChest      | The upper chest can rotate up to 10-20 degrees, aiding in the overall rotation of the torso.
# | [Side]UpperLeg  | The upper leg can rotate up to 30-40 degrees, allowing for movements such as kicking or stepping.                                                                                                  |
# | [Side]LowerLeg  | The lower leg can rotate slightly up to 10-15 degrees, providing flexibility for running or jumping.                                                                                                 |
# | [Side]Foot      | The foot can rotate inward or outward (inversion and eversion) up to 20-30 degrees, enabling balance and various stances.         |
# | [Side]Shoulder  | The shoulder can rotate up to 90 degrees in a normal range of motion. This allows for movements such as lifting an arm or throwing. However, with forced movement, it can rotate beyond this limit. |
#
# **Rotation Swing**
# | Body Part       | Description                                                                                                                                                                                                                   |
# |-----------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
# | Hips            | The hips can tilt forward and backward up to 20-30 degrees, allowing the legs to swing in a wide arc during walking or running. They can also move side-to-side up to 10-20 degrees, enabling the legs to spread apart or come together.                               |
# | UpperChest      | The upper chest can tilt forward and backward up to 10-20 degrees, allowing for natural breathing and posture adjustments.                                                                                                                         |
# | Chest           | The chest can tilt forward and backward up to 10-20 degrees, allowing for natural breathing and posture adjustments.                                                                                                                               |
# | Spine           | The spine can tilt forward and backward up to 35-45 degrees, allowing for bending and straightening of the torso.                                                                                                                                  |
# | [Side]UpperLeg  | The upper leg can swing forward and backward up to 80-90 degrees, allowing for steps during walking and running.                                                                                                  |
# | [Side]LowerLeg  | The knee can bend and straighten up to 110-120 degrees, allowing the lower leg to move towards or away from the upper leg during walking, running, and stepping.                                                                                     |
# | [Side]Foot      | The ankle can tilt up (dorsiflexion) up to 10-20 degrees and down (plantarflexion) up to 35-40 degrees, allowing the foot to step and adjust during walking and running.          |
# | [Side]Shoulder  | The shoulder can tilt forward and backward up to 160 degrees, allowing the arms to swing in a wide arc. They can also move side-to-side up to 40-50 degrees, enabling the arms to extend outwards or cross over the chest.                                       |
# | [Side]UpperArm  | The upper arm can swing forward and backward up to 110-120 degrees, allowing for reaching and swinging motions.                                                                             |
# | [Side]LowerArm  | The elbow can bend and straighten up to 120-130 degrees, allowing the forearm to move towards or away from the upper arm during reaching and swinging motions.                                                                                       |
# | [Side]Hand      | The wrist can tilt up and down up to 50-60 degrees, allowing the hand to move towards or away from the forearm.
	
func _run():
	var root: Node = get_scene()
	var nodes : Array[Node] = root.find_children("*", "ManyBoneIK3D")
	if nodes.is_empty():
		return
	var many_bone_ik: ManyBoneIK3D = nodes[0]
	var markers: Array[Node] = many_bone_ik.find_children("*", "Marker3D")
	for marker in markers:
		marker.free()

	many_bone_ik.set_process_thread_group(Node.PROCESS_THREAD_GROUP_SUB_THREAD)
	many_bone_ik.set_process_thread_group_order(100)

	var skeleton: Skeleton3D = many_bone_ik.get_node_or_null(many_bone_ik.get_skeleton_node_path()) as Skeleton3D

	skeleton.show_rest_only = true
	skeleton.reset_bone_poses()
	many_bone_ik.set_constraint_count(0)
	var skeleton_profile: SkeletonProfileHumanoid = SkeletonProfileHumanoid.new()
	for bone_name_i in skeleton.get_bone_count():
		var bone_name = skeleton.get_bone_name(bone_name_i)
		var swing_limit_cones = []
		var bone_i = skeleton_profile.find_bone(bone_name)
		if bone_i == -1:
			continue
		var twist_range = PI * 2
		var twist_from = 0
		var resistance = 0
		if bone_name == "Root":
			twist_from = deg_to_rad(0.0)
			twist_range = deg_to_rad(5)
			swing_limit_cones.append(LimitCone.new(Vector3.MODEL_REAR, deg_to_rad(3.0)))
			# Cannot use resistance on root bones.
		elif bone_name == "Hips":
			twist_from = deg_to_rad(0.0)
			twist_range = deg_to_rad(5)
			swing_limit_cones.append(LimitCone.new(Vector3.MODEL_REAR, deg_to_rad(3.0)))
			# Cannot use resistance on root bones.
		elif bone_name == "Spine":
			twist_from = deg_to_rad(4.0)
			twist_range = deg_to_rad(10)
			swing_limit_cones.append(LimitCone.new(Vector3.MODEL_FRONT, deg_to_rad(3.0)))
			resistance = 0.5
		elif bone_name == "Chest":
			twist_from = deg_to_rad(5.0)
			twist_range = deg_to_rad(-10.0)
			swing_limit_cones.append(LimitCone.new(Vector3.MODEL_FRONT, deg_to_rad(3.0)))
			resistance = 0.5
		elif bone_name == "UpperChest":
			twist_from = deg_to_rad(10.0)
			twist_range = deg_to_rad(40.0)
			swing_limit_cones.append(LimitCone.new(Vector3.MODEL_FRONT, deg_to_rad(10.0)))
			resistance = 0.6
		elif bone_name == "Neck":
			twist_from = deg_to_rad(15.0)
			twist_range = deg_to_rad(15.0)
			swing_limit_cones.append(LimitCone.new(Vector3.MODEL_FRONT, deg_to_rad(10.0)))
			resistance = 0.6
		elif bone_name == "Head":
			twist_from = deg_to_rad(15.0)
			twist_range = deg_to_rad(15.0)
			swing_limit_cones.append(LimitCone.new(Vector3.MODEL_FRONT, deg_to_rad(15.0)))
			resistance = 0.7
		elif bone_name.ends_with("Eye"):
			continue
		elif bone_name == "LeftLowerLeg":
			twist_from = deg_to_rad(-45.0)
			twist_range = deg_to_rad(2.0)
			swing_limit_cones.append(LimitCone.new(Vector3.MODEL_FRONT, deg_to_rad(2.5)))
			swing_limit_cones.append(LimitCone.new(Vector3.MODEL_TOP, deg_to_rad(2.5)))
			swing_limit_cones.append(LimitCone.new(Vector3.MODEL_REAR, deg_to_rad(2.5)))
			resistance = 0.8
		elif bone_name == "RightLowerLeg":
			twist_from = deg_to_rad(-45.0)
			twist_range = deg_to_rad(2.0)
			swing_limit_cones.append(LimitCone.new(Vector3.MODEL_FRONT, deg_to_rad(2.5)))
			swing_limit_cones.append(LimitCone.new(Vector3.MODEL_TOP, deg_to_rad(2.5)))
			swing_limit_cones.append(LimitCone.new(Vector3.MODEL_REAR, deg_to_rad(2.5)))
		elif bone_name in ["LeftShoulder", "RightShoulder"]:
			swing_limit_cones.append(LimitCone.new(Vector3.MODEL_FRONT, deg_to_rad(30.0)))
		elif bone_name in ["LeftUpperArm", "RightUpperArm"]:
			twist_from = deg_to_rad(80.0)
			twist_range = deg_to_rad(12.0)
			swing_limit_cones.append(LimitCone.new(Vector3.MODEL_FRONT, deg_to_rad(90.0)))
			resistance = 0.3
		elif bone_name == "LeftLowerArm":
			twist_from = deg_to_rad(-55.0)
			twist_range = deg_to_rad(50.0)
			swing_limit_cones.append(LimitCone.new(Vector3.MODEL_FRONT, deg_to_rad(2.5)))
			swing_limit_cones.append(LimitCone.new(Vector3.MODEL_RIGHT, deg_to_rad(2.5)))
			swing_limit_cones.append(LimitCone.new(Vector3.MODEL_REAR, deg_to_rad(2.5)))
			resistance = 0.4
		elif bone_name == "RightLowerArm":
			twist_from = deg_to_rad(-145.0)
			twist_range = deg_to_rad(50.0)
			swing_limit_cones.append(LimitCone.new(Vector3.MODEL_FRONT, deg_to_rad(2.5)))
			swing_limit_cones.append(LimitCone.new(Vector3.MODEL_FRONT, deg_to_rad(2.5)))
			swing_limit_cones.append(LimitCone.new(Vector3.MODEL_REAR, deg_to_rad(2.5)))
			resistance = 0.4
		elif bone_name in ["LeftHand", "RightHand"]:
			swing_limit_cones.append(LimitCone.new(((Vector3.MODEL_TOP + Vector3.MODEL_FRONT) / 2.0).normalized(), deg_to_rad(65.0)))
			swing_limit_cones.append(LimitCone.new(Vector3.MODEL_FRONT, deg_to_rad(0.0)))
			swing_limit_cones.append(LimitCone.new(((Vector3.MODEL_BOTTOM + Vector3.MODEL_FRONT) / 2.0).normalized(), deg_to_rad(70.0)))
			swing_limit_cones.append(LimitCone.new(Vector3.MODEL_FRONT, deg_to_rad(0.0)))
			swing_limit_cones.append(LimitCone.new(((Vector3.MODEL_LEFT + Vector3.MODEL_FRONT) / 2.0).normalized(), deg_to_rad(40.0)))
			swing_limit_cones.append(LimitCone.new(Vector3.MODEL_FRONT, deg_to_rad(0.0)))
			swing_limit_cones.append(LimitCone.new(((Vector3.MODEL_RIGHT + Vector3.MODEL_FRONT) / 2.0).normalized(), deg_to_rad(45.0)))
			swing_limit_cones.append(LimitCone.new(Vector3.MODEL_FRONT, deg_to_rad(0.0)))
		elif bone_name in ["LeftThumb", "RightThumb"]:
			swing_limit_cones.append(LimitCone.new(Vector3.MODEL_FRONT, deg_to_rad(90.0)))
		elif bone_name in ["LeftFoot", "RightFoot"]:
			swing_limit_cones.append(LimitCone.new(((Vector3.MODEL_BOTTOM + Vector3.MODEL_FRONT) / 2.0).normalized(), deg_to_rad(2.5)))
			swing_limit_cones.append(LimitCone.new(Vector3.MODEL_REAR, deg_to_rad(0)))
			swing_limit_cones.append(LimitCone.new(((Vector3.MODEL_TOP + Vector3.MODEL_REAR) / 2.0).normalized(), deg_to_rad(2.5)))
			swing_limit_cones.append(LimitCone.new(Vector3.MODEL_REAR, deg_to_rad(0)))
		else:
			continue
		set_bone_constraint(many_bone_ik, bone_name, twist_from, twist_range, swing_limit_cones, resistance)
	many_bone_ik.queue_print_skeleton()
	var bones: Array = [
		"Hips",
		"Chest",
		"LeftLowerArm",
		"LeftHand",
		#"LeftThumbProximal",
		#"LeftIndexProximal",
		#"LeftMiddleProximal",
		#"LeftRingProximal",
		#"LeftLittleProximal",
		#"LeftThumbDistal",
		#"LeftIndexDistal",
		#"LeftMiddleDistal",
		#"LeftRingDistal",
		#"LeftLittleDistal",
		"RightLowerArm",
		"RightHand",
		#"RightThumbProximal",
		#"RightIndexProximal",
		#"RightMiddleProximal",
		#"RightRingProximal",
		#"RightLittleProximal",
		#"RightThumbDistal",
		#"RightIndexDistal",
		#"RightMiddleDistal",
		#"RightRingDistal",
		#"RightLittleDistal",
		"LeftLowerLeg",
		"RightLowerLeg",
		"LeftFoot",
		"RightFoot",
		"Head",
	]
	
	many_bone_ik.set_pin_count(0)
	many_bone_ik.set_pin_count(bones.size())

	var children: Array[Node] = root.find_children("*", "BoneAttachment3D")
	for i in range(children.size()):
		var node: Node = children[i] as Node
		node.queue_free()
	
	for pin_i in range(bones.size()):
		var bone_name: String = bones[pin_i]
		var marker_3d: BoneAttachment3D = BoneAttachment3D.new()
		marker_3d.name = bone_name
		if bone_name == "Root":
			marker_3d.bone_name = "root"
		else:
			marker_3d.bone_name = bone_name
		marker_3d.set_external_skeleton("../..")
		many_bone_ik.add_child(marker_3d, true)
		marker_3d.owner = root
		var targets_3d: Marker3D = Marker3D.new()
		targets_3d.gizmo_extents =  .05
		marker_3d.add_child(targets_3d, true)
		targets_3d.owner = root
		var bone_i: int = skeleton.find_bone(bone_name)
		if bone_i == -1:
			continue
		var pose: Transform3D =  skeleton.get_bone_global_rest(bone_i)
		marker_3d.global_transform = pose
		many_bone_ik.set_pin_nodepath(pin_i, many_bone_ik.get_path_to(marker_3d))
		many_bone_ik.set_pin_bone_name(pin_i, bone_name)
		if bone_name in ["Root", "Hips", "LeftHand", "RightHand", "LeftFoot", "RightFoot", "Hips"]:
			many_bone_ik.set_pin_passthrough_factor(pin_i, 0)
		else:
			many_bone_ik.set_pin_passthrough_factor(pin_i, 1)

	skeleton.show_rest_only = false

	var set_a: Array[Vector3] = []
	var set_b: Array[Vector3] = []
	
	var reference_skeleton = many_bone_ik.owner.get_node("vrm_1_vsekai_godot_engine_humanoid_08/Root/Skeleton3D")
	for bone_name in bones:
		var bone_id = reference_skeleton.find_bone(bone_name)
		if bone_id != -1:
			var bone_position = reference_skeleton.get_bone_global_pose(bone_id).origin
			set_a.append(bone_position)
		else:
			print("Bone '%s' not found!" % bone_name)
	
	var target_skeleton = many_bone_ik.owner.get_node("VVVV_200502/Armature/GeneralSkeleton")
	for bone_name in bones:
		var bone_id = target_skeleton.find_bone(bone_name)
		if bone_id != -1:
			var bone_position = target_skeleton.get_bone_global_pose(bone_id).origin
			set_b.append(bone_position)
		else:
			print("Bone '%s' not found!" % bone_name)
	var distance = chamfer_distance(set_a, set_b)
	print(distance)

var bone_constraints: Dictionary

func get_bone_constraint(p_bone_name: String) -> BoneConstraint:
	if bone_constraints.has(p_bone_name):
		return bone_constraints[p_bone_name]
	else:
		return BoneConstraint.new()

func set_bone_constraint(many_bone_ik: ManyBoneIK3D, p_bone_name: String, p_twist_from: float, p_twist_range: float, p_swing_limit_cones: Array, p_resistance: float = 0.0):
	bone_constraints[p_bone_name] = BoneConstraint.new(p_twist_from, p_twist_range, p_swing_limit_cones, p_resistance)
	var constraint_count = many_bone_ik.get_constraint_count()
	many_bone_ik.set_constraint_count(constraint_count + 1)
	many_bone_ik.set_constraint_name(constraint_count, p_bone_name)
	many_bone_ik.set_kusudama_resistance(constraint_count, p_resistance)
	many_bone_ik.set_kusudama_twist(constraint_count, Vector2(p_twist_from, p_twist_range))
	many_bone_ik.set_kusudama_limit_cone_count(constraint_count, p_swing_limit_cones.size())
	for cone_constraint_i: int in range(p_swing_limit_cones.size()):
		var cone_constraint: LimitCone = p_swing_limit_cones[cone_constraint_i]
		many_bone_ik.set_kusudama_limit_cone_center(constraint_count, cone_constraint_i, cone_constraint.direction)
		many_bone_ik.set_kusudama_limit_cone_radius(constraint_count, cone_constraint_i, cone_constraint.angle)
