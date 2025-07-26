# renik_cpp
# Copyright 2020 MMMaellon
# Copyright (c) 2014-present Godot Engine contributors (see AUTHORS.md).
# Copyright (c) 2007-2014 Juan Linietsky, Ariel Manzur.
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

@tool
class_name RenIKSpineModifier3D
extends SkeletonModifier3D

const renik_helper = preload("./renik_helper.gd")

class Joint:
	var rotation: Quaternion
	var id: int
	var relative_prev: Vector3
	var relative_next: Vector3
	var prev_distance: float = 0
	var next_distance: float = 0
	var root_influence: float = 0
	var leaf_influence: float = 0
	var twist_influence: float = 1
	var chest_twist_influence: float = 1
	var total_length: float = 0


const DEFAULT_THRESHOLD: float = 0.0005
const DEFAULT_LOOP_LIMIT: int = 16

var leaf_id: int = -1
var first_id: int = -1
var root_id: int = -1
var chest_id: int = -1

var chest_joint: Joint

@export var leaf_bone: StringName = &"Head":
	set(x):
		leaf_bone = x
		leaf_id = -1

@export var root_bone: StringName = &"Hips":
	set(x):
		root_bone = x
		root_id = -1

@export var chest_bone: StringName = &"":
	set(x):
		chest_bone = x
		chest_id = -1
		skel_dirty = true

var joints: Array[Joint]
var total_length: float = 0
var rest_leaf: Transform3D
var skel_dirty: bool = false

@export var chain_curve_direction: Vector3 = Vector3(0, 15, -15)
@export_range(0,1,0.001) var root_influence: float = 0.5: # how much the start bone is influenced by the root rotation
	set(value):
		root_influence = value
		skel_dirty = true
@export_range(0,1,0.001) var leaf_influence: float = 0.5: # how much the end bone is influenced by the goal rotation
	set(value):
		leaf_influence = value
		skel_dirty = true
@export_range(0,1,0.001) var twist_influence: float = 1: # How much the chain tries to twist to follow the end when the start is facing a different direction
	set(value):
		twist_influence = value
		skel_dirty = true
@export_range(0,1,0.001) var twist_start: float = 0: # Where along the chain the twisting starts
	set(value):
		twist_start = value
		skel_dirty = true
@export_range(0,1,0.001) var twist_stop: float = 1: # Where along the chain the twisting stops
	set(value):
		twist_stop = value
		skel_dirty = true
@export_range(0,1,0.001) var target_rotation_influence: float = 1.0:
	set(value):
		target_rotation_influence = value
		skel_dirty = true

@export var chest_target: Node3D

@export var head_target: Node3D

@export_tool_button("Create Head Target") var create_head_target: Callable:
	get:
		return func():
			var skel = get_skeleton()
			if skel != null:
				if skel.has_node(NodePath(leaf_bone + "Target")):
					head_target = get_parent().get_node(NodePath(leaf_bone + "Target"))
				else:
					var marker = Marker3D.new()
					marker.name = leaf_bone + "Target"
					skel.add_child(marker)
					marker.owner = owner
					marker.transform = skel.get_bone_global_pose(skel.find_bone(leaf_bone))
					head_target = marker

@export var hip_target: Node3D

@export_tool_button("Create Hip Target") var create_hip_target: Callable:
	get:
		return func():
			var skel = get_skeleton()
			if skel != null:
				if skel.has_node(NodePath(root_bone + "Target")):
					hip_target = get_parent().get_node(NodePath(root_bone + "Target"))
				else:
					var marker = Marker3D.new()
					marker.name = root_bone + "Target"
					skel.add_child(marker)
					marker.owner = owner
					marker.transform = skel.get_bone_global_pose(skel.find_bone(root_bone))
					hip_target = marker

@export_tool_button("Reset Targets to Rest") var reset_targets_to_rest: Callable:
	get:
		return func():
			var skel = get_skeleton()
			if skel != null:
				if hip_target != null:
					hip_target.global_transform = skel.global_transform * skel.get_bone_global_rest(skel.find_bone(root_bone))
				if head_target != null:
					head_target.global_transform = skel.global_transform * skel.get_bone_global_rest(skel.find_bone(leaf_bone))

func init_chain(skeleton: Skeleton3D):
	joints.clear()
	total_length = 0
	if (skeleton && root_id >= 0 && leaf_id >= 0 &&
			root_id < skeleton.get_bone_count() &&
			leaf_id < skeleton.get_bone_count()):
		var bone: int = skeleton.get_bone_parent(leaf_id)
		# generate the chain of bones
		var chain: PackedInt32Array
		var total_lengths: PackedFloat32Array
		var last_length: float = 0.0
		var chest_index_from_end: int = -1
		var chest_to_head_length: float = 0.0
		rest_leaf = skeleton.get_bone_rest(leaf_id)
		while bone != root_id:
			var rest_pose: Transform3D = skeleton.get_bone_rest(bone)
			rest_leaf = rest_pose * rest_leaf.orthonormalized()
			total_lengths.push_back(total_length)
			last_length = rest_pose.origin.length()
			total_length += last_length
			if chest_index_from_end < 0:
				chest_to_head_length += last_length
			if bone < 0: # invalid chain
				total_length = 0
				first_id = -1
				rest_leaf = Transform3D()
				return
			chain.push_back(bone)
			first_id = bone
			if bone == chest_id:
				chest_index_from_end = len(chain)
			bone = skeleton.get_bone_parent(bone)

		total_length -= last_length
		total_length += skeleton.get_bone_rest(leaf_id).origin.length()

		if total_length <= 0: # invalid chain
			total_length = 0
			first_id = -1
			rest_leaf = Transform3D()
			return

		var chest_twist_start: float = 1
		var chest_length: float = total_length - chest_to_head_length
		if chest_index_from_end != -1 and twist_start < chest_length / total_length:
			chest_twist_start = twist_start / (chest_length / total_length)
		if twist_start > chest_length / total_length:
			chest_index_from_end = -1
		var totalRotation: Basis
		var progress: float = 0
		# flip the order and figure out the relative distances of these joints
		for i in range(len(chain) - 1, -1, -1):
			var j: Joint = Joint.new()
			j.id = chain[i]
			if j.id == chest_id:
				chest_joint = j
			var boneTransform: Transform3D = skeleton.get_bone_rest(j.id)
			j.rotation = boneTransform.basis.get_rotation_quaternion()
			j.relative_prev = boneTransform.origin * totalRotation
			j.prev_distance = j.relative_prev.length()
			j.total_length = total_lengths[i]


			# calc influences
			progress += j.prev_distance
			var percentage: float = (progress / total_length)
			var chest_percentage: float
			if progress >= chest_length:
				chest_percentage = 1 + (progress - chest_length) / chest_to_head_length
			else:
				chest_percentage = progress / chest_length
			var effectiveRootInfluence: float = 0
			var effectiveLeafInfluence: float = 0
			var effectiveTwistInfluence: float = 0
			var effectiveChestTwistInfluence: float = 0
			if root_influence > 0 and percentage < root_influence:
				effectiveRootInfluence = (percentage - root_influence) / -root_influence
			if leaf_influence > 0 and percentage > 1 - leaf_influence:
				effectiveLeafInfluence = (percentage - (1 - leaf_influence)) / leaf_influence
			var twist_len := clampf(twist_stop - twist_start, 0.01, 1.0)
			if twist_start < 1 and twist_influence > 0 and percentage > twist_start:
				effectiveTwistInfluence = (percentage - twist_start) / twist_len * (twist_influence / (1 - twist_start))
			twist_len = clampf(twist_stop - chest_twist_start, 0.01, 1.0)
			if chest_twist_start < 1 and twist_influence > 0 and percentage > chest_twist_start:
				effectiveTwistInfluence = (percentage - chest_twist_start) / twist_len * (twist_influence / (1 - chest_twist_start))
			j.root_influence = minf(effectiveRootInfluence, 1)
			j.leaf_influence = minf(effectiveLeafInfluence, 1)
			j.twist_influence = minf(effectiveTwistInfluence, 1)
			j.chest_twist_influence = minf(effectiveTwistInfluence, 1)

			if not joints.is_empty():
				joints[len(joints) - 1].relative_next = -j.relative_prev
				joints[len(joints) - 1].next_distance = j.prev_distance

			joints.push_back(j)
			totalRotation = (totalRotation * boneTransform.basis).orthonormalized()

		if not joints.is_empty():
			joints[len(joints) - 1].relative_next = -skeleton.get_bone_rest(leaf_id).origin
			joints[len(joints) - 1].next_distance = joints[len(joints) - 1].relative_next.length()


func is_valid() -> bool:
	return not joints.is_empty()


func update_bones(skeleton: Skeleton3D) -> void:
	if skeleton != null and (skel_dirty or chest_id == -1) and not chest_bone.is_empty():
		chest_id = skeleton.find_bone(chest_bone)
	if skeleton != null and (skel_dirty or root_id == -1 or leaf_id == -1 or first_id == -1):
		skel_dirty = false
		if root_id == -1 and not root_bone.is_empty():
			root_id = skeleton.find_bone(root_bone)
		if leaf_id == -1 and not leaf_bone.is_empty():
			leaf_id = skeleton.find_bone(leaf_bone)
		init_chain(skeleton)


func is_valid_in_skeleton(skeleton: Skeleton3D) -> bool:
	update_bones(skeleton)
	if (skeleton == null || root_id < 0 || leaf_id < 0 || first_id < 0 ||
			root_id >= skeleton.get_bone_count() ||
			leaf_id >= skeleton.get_bone_count() ||
			first_id >= skeleton.get_bone_count()):
		return false
	return true


func contains_bone(skeleton: Skeleton3D, bone: int) -> bool:
	if skeleton:
		var spineBone: int = leaf_id
		while spineBone >= 0:
			if spineBone == bone:
				return true

			spineBone = skeleton.get_bone_parent(spineBone)

	return false



func apply_ik_map_quat(ik_map: Dictionary, global_parent: Transform3D, apply_order: PackedInt32Array):
	var skeleton := get_skeleton()
	if skeleton:
		for apply_i in apply_order:
			var local_quat: Quaternion = ik_map[apply_i]
			skeleton.set_bone_pose_rotation(apply_i, local_quat)


func _process_modification() -> void:
	if not is_valid_in_skeleton(get_skeleton()):
		return
	perform_torso_ik()


func perform_torso_ik ():
	var skeleton := get_skeleton()
	var head_xform: Transform3D
	if skeleton && is_valid():
		var hip: int = root_id
		var head: int = leaf_id
		var skel_inverse: Transform3D = skeleton.global_transform.affine_inverse()

		var parent_id := skeleton.get_bone_parent(hip)
		var parent_xform: Transform3D = skeleton.get_bone_global_pose(parent_id)

		if head_target && head_target.visible:
			head_xform = skel_inverse * head_target.global_transform
		else:
			head_xform = skeleton.get_bone_global_pose(head)
		var headGlobalTransform: Transform3D = head_xform.orthonormalized()

		var chestGlobalTransform: Transform3D = headGlobalTransform
		var use_chest_twist = false
		if chest_id != -1:
			var chest_xform: Transform3D
			if chest_target && chest_target.visible:
				chest_xform = skel_inverse * chest_target.global_transform
				use_chest_twist = true
			else:
				chest_xform = skeleton.get_bone_global_pose(chest_id)
			chestGlobalTransform = chest_xform.orthonormalized()

		var has_hip_tracker := false
		var hipTransform: Transform3D
		if hip_target and hip_target.visible:
			hipTransform = skel_inverse * hip_target.global_transform.orthonormalized()
			has_hip_tracker = true
		else:
			hipTransform = skeleton.get_bone_global_pose(hip)
		var hipGlobalTransform: Transform3D = hipTransform.orthonormalized()

		if root_bone != &"Hips":
			headGlobalTransform.origin += hipGlobalTransform.origin - parent_xform.origin


		var delta: Vector3 = hipGlobalTransform.origin + hipGlobalTransform.basis * (joints[0].relative_prev) - headGlobalTransform.origin
		var fullLength: float = total_length
		if delta.length() > fullLength:
			var head_delta: Vector3 = (delta.normalized() * fullLength) - hipGlobalTransform.basis * (joints[0].relative_prev)
			var hip_delta: Vector3 = (headGlobalTransform.origin + head_delta) - hipGlobalTransform.origin
			hipGlobalTransform.origin += hip_delta
			if chest_id != -1 and chest_joint != null and use_chest_twist:
				chestGlobalTransform.origin += hip_delta

		if chest_id != -1 and use_chest_twist:
			var chest_delta: Vector3 = (chestGlobalTransform.origin - skeleton.get_bone_global_pose(chest_id).origin)
			var chest_delta_clamped: Vector3 = chest_delta.clamp(Vector3.ONE * -0.3, Vector3.ONE * 0.3)
			headGlobalTransform.origin += chest_delta_clamped
			pass

		var ik_map: Dictionary = solve_ifabrik(
				hipGlobalTransform, headGlobalTransform, chestGlobalTransform,
				use_chest_twist, DEFAULT_THRESHOLD, DEFAULT_LOOP_LIMIT)
		if has_hip_tracker:
			skeleton.set_bone_pose_rotation(hip, (parent_xform.basis.inverse() * hipGlobalTransform.basis).get_rotation_quaternion())
			if root_bone == &"Hips" and has_hip_tracker:
				skeleton.set_bone_pose_position(hip, hipGlobalTransform.origin)

		apply_ik_map_quat(ik_map, hipGlobalTransform, bone_id_order_spine())

		# Keep Hip and Head as global poses tand then apply them as global pose
		# override
		var neckQuaternion: Quaternion = Quaternion.IDENTITY
		var parent_bone: int = skeleton.get_bone_parent(head)
		while parent_bone != -1:
			neckQuaternion = skeleton.get_bone_pose_rotation(parent_bone) * neckQuaternion
			parent_bone = skeleton.get_bone_parent(parent_bone)

		var cur_head_rotation: Quaternion = skeleton.get_bone_pose_rotation(head)
		skeleton.set_bone_pose_rotation(head, cur_head_rotation.slerp(
			neckQuaternion.inverse() * headGlobalTransform.basis.get_rotation_quaternion(),
			target_rotation_influence))

		return true

	return false

# IK SOLVING

func bone_id_order_spine () -> PackedInt32Array:
	var ret: PackedInt32Array
	for joint in joints:
		# the last one's rotation is defined by the leaf position not a
		# joint so we skip it
		# FIXME: It's not actually skipping the last.
		ret.push_back(joint.id)

	return ret


func solve_ifabrik(root: Transform3D, target: Transform3D, twistTarget: Transform3D, use_chest_twist: bool, threshold: float, loopLimit: int) -> Dictionary:
	var map: Dictionary
	if is_valid(): # if the chain is valid there's at least one joint in the chain and there's one bone between it and the root
		var joints: Array[Joint] = joints # just so I don't have to call it all the time
		var trueRoot: Transform3D = root.translated_local(joints[0].relative_prev)
		# how the change in the target would affect the chain if the chain was parented to the target instead of the root
		var targetDelta: Transform3D = target * rest_leaf.affine_inverse()
		var trueRelativeTarget: Transform3D = trueRoot.affine_inverse() * target
		var trueRelativeTwistTarget: Transform3D = trueRoot.affine_inverse() * twistTarget
		var alignToTarget: Quaternion = renik_helper.align_vectors(
				rest_leaf.origin - joints[0].relative_prev,
				trueRelativeTarget.origin)

		var heightDiff: float = (rest_leaf.origin - joints[0].relative_prev).length() - trueRelativeTarget.origin.length()
		heightDiff = maxf(0, heightDiff)
		# The angle root is rotated  to point at the target
		var prebentRoot: Transform3D = Transform3D(trueRoot.basis * Basis(alignToTarget), trueRoot.origin).translated_local(
				(chain_curve_direction * total_length * heightDiff) - joints[0].relative_prev)

		var globalJointPoints: PackedVector3Array

		# We generate the starting points
		# Here is where we take into account root and target influences and the
		# prebend vector
		var relativeJoint: Vector3 = joints[0].relative_prev
		for joint_i in range(1, len(joints)):
			relativeJoint = relativeJoint + joints[joint_i].relative_prev
			var prebentJoint: Vector3 = prebentRoot * (
					relativeJoint) # if you rotated the root around the true root so
									# that the whole chain was pointing to the leaf and
									# then you moved everything along the prebend vector
			var rootJoint: Vector3 = root * relativeJoint # if you moved the joint with the root
			var leafJoint: Vector3 = targetDelta * relativeJoint # if you moved the joint with the leaf
			prebentJoint = prebentJoint.lerp(rootJoint, joints[joint_i].root_influence)
			prebentJoint = prebentJoint.lerp(
					leafJoint, joints[joint_i].leaf_influence) # leaf influence dominates
			globalJointPoints.push_back(prebentJoint)


		# We then do regular FABRIK
		for i in range(loopLimit):
			var lastJoint: Vector3 = target.origin
			# Backward
			for j in range(len(joints) - 1, 0, -1):
				# we skip the first joint because we're not allowed to move that joint
				var delta: Vector3 = globalJointPoints[j - 1] - lastJoint
				delta = delta.normalized() * joints[j].next_distance
				globalJointPoints.set(j - 1, lastJoint + delta)
				lastJoint = globalJointPoints[j - 1]
			lastJoint = trueRoot.origin # the root joint

			# Forwards
			for j in range(1, len(joints)):
				# we skip the first joint because we're not allowed to move that joint
				var delta: Vector3 = globalJointPoints[j - 1] - lastJoint
				delta = delta.normalized() * joints[j].prev_distance
				globalJointPoints.set(j - 1, lastJoint + delta)
				lastJoint = globalJointPoints[j - 1]

			var error: float = (lastJoint - trueRoot.origin).length()
			if error < threshold:
				break

		# Add a little twist
		# We align the leaf's y axis with the rest_leaf's y-axis and see how far
		# off the x-axes are to calculate the twist.
		trueRelativeTarget = trueRelativeTarget.orthonormalized()
		var relativeTargetQuat := trueRelativeTwistTarget.basis.get_rotation_quaternion()
		var leafX: Vector3 = renik_helper.align_vectors(
						trueRelativeTarget.basis * (Vector3(0, 1, 0)),
						rest_leaf.basis * (Vector3(0, 1, 0))
						).normalized() * (trueRelativeTarget.basis * (Vector3(1, 0, 0)))
		var restX: Vector3 = rest_leaf.basis * (Vector3(1, 0, 0))
		var maxTwist: float = leafX.angle_to(restX)
		if leafX.cross(restX).dot(Vector3(0, 1, 0)) > 0:
			maxTwist *= -1

		# Convert everything to quaternions and store it in the map
		var rootRot: Quaternion = root.basis.get_rotation_quaternion()
		var parentRot: Quaternion = root.basis.get_rotation_quaternion()
		var parentRot2: Quaternion = Quaternion.IDENTITY
		var parentPos: Vector3 = trueRoot.origin
		var prevTwist: Quaternion
		globalJointPoints.push_back(target.origin)
		for joint_i in range(len(joints)):
			# the last one's rotation is defined by the leaf position not a
			# joint so we skip it
			# FIXME: Not actually skipping the last.
			var pose: Quaternion = renik_helper.align_vectors(
					Vector3(0, 1, 0),
					Transform3D(parentRot * joints[joint_i].rotation, parentPos)
							.affine_inverse()
							 * (globalJointPoints[joint_i])) # offset by one because joints has one extra element

			pose = Quaternion(Vector3(0, 1, 0), Transform3D(parentRot * joints[joint_i].rotation, parentPos)
							.affine_inverse()
							 * (globalJointPoints[joint_i]))

			var new_rotation: Quaternion = pose
			
			# renik_spine.gd:497 @ solve_ifabrik(): The quaternion (-0.0, 0.021804, 0.0, 1.000638) must be normalized.
			var old_rotation: Quaternion = (prevTwist.normalized().inverse() * new_rotation).normalized() # skeleton.get_bone_pose_rotation(joint.x)
			var lerp_fraction: float = joints[joint_i].chest_twist_influence if use_chest_twist else joints[joint_i].twist_influence # float(joint_i + 1) / len(joints)
			var child_target_quat := parentRot2.inverse() * relativeTargetQuat
			var child_twist_quat := renik_helper.get_twist(child_target_quat.normalized(), Vector3(0,1,0)) # Quaternion(child_target_quat * Vector3(0,1,0), 0).inverse() * child_target_quat
			var swing_quat := renik_helper.get_swing(old_rotation.normalized(), Vector3(0,1,0))
			var twist_quat := swing_quat * child_twist_quat.normalized()
			var interpolated: Quaternion = pose.normalized().slerp(twist_quat.normalized(), lerp_fraction)
			pose = interpolated # twist_quat # interpolated
			prevTwist = interpolated.inverse() * old_rotation

			map[joints[joint_i].id] = pose
			parentRot = parentRot * pose
			parentRot2 = parentRot2 * pose
			parentPos = globalJointPoints[joint_i]

	return map


func calculate_bone_chain (root: int, leaf: int) -> PackedInt32Array:
	var chain: PackedInt32Array
	var b: int = leaf
	var skeleton := get_skeleton()
	chain.push_back(b)
	if skeleton:
		while b >= 0 && b != root:
			b = skeleton.get_bone_parent(b)
			chain.push_back(b)
		if b < 0:
			chain.clear()
			chain.push_back(leaf)
		else:
			chain.reverse()
	return chain
