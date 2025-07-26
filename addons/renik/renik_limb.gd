# renik_limb.cpp
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
# EXPRESS OR IMPLIED, I`NCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

@tool
class_name RenIKLimbModifier3D
extends SkeletonModifier3D

const renik_helper = preload("./renik_helper.gd")

var upper: Transform3D
var lower: Transform3D
var leaf: Transform3D
var upper_extra_bones: Transform3D # Extra bones between upper and lower
var lower_extra_bones: Transform3D # Extra bones between lower and leaf
var upper_extra_bone_ids: PackedInt32Array
var lower_extra_bone_ids: PackedInt32Array

var leaf_id: int = -1
var lower_id: int = -1
var upper_id: int = -1
var dynamic_pole_root_id: int = -1
var dynamic_pole_head_id: int = -1

const LEFT_HAND = 0
const RIGHT_HAND = 1
const LEFT_FOOT = 2
const RIGHT_FOOT = 3
const CUSTOM = 4

@export_enum("LeftHand", "RightHand", "LeftFoot", "RightFoot", "Custom Limb") var preset: int = 4:
	set(x):
		preset = x
		leaf_id = -1
		lower_id = -1
		upper_id = -1
		dynamic_pole_root_id = -1
		mirror_factor = (-1 if mirror else 1)

@export_tool_button("Assign Arm Defaults") var assign_arm_defaults: Callable:
	get:
		return func():
			upper_twist_offset = -0.5*PI
			lower_twist_offset = -0.5*PI
			roll_offset = deg_to_rad(-120.0)
			upper_limb_twist = 0.5
			lower_limb_twist = 0.66666
			twist_inflection_point_offset = deg_to_rad(180.0)
			twist_overflow = deg_to_rad(45.0)
			target_rotation_influence = 0.33
			pole_offset = Quaternion.from_euler(Vector3(deg_to_rad(15.0), 0, deg_to_rad(60.0)))
			target_position_influence = Vector3(2.0, -1.5, -1.0)

@export_tool_button("Assign Leg Defaults") var assign_leg_defaults: Callable:
	get:
		return func():
			upper_twist_offset = 0
			lower_twist_offset = PI
			roll_offset = 0
			upper_limb_twist = 0.25
			lower_limb_twist = 0.25
			twist_inflection_point_offset = deg_to_rad(0.0)
			twist_overflow = deg_to_rad(45.0)
			target_rotation_influence = 0.5
			pole_offset = Quaternion.from_euler(Vector3(0, 0, PI))
			target_position_influence = Vector3()

@export var leaf_bone: StringName:
	set(x):
		leaf_bone = x
		leaf_id = -1
	get:
		match preset:
			0:
				return "LeftHand"
			1:
				return "RightHand"
			2:
				return "LeftFoot"
			3:
				return "RightFoot"
			_:
				return leaf_bone

@export var lower_bone: StringName:
	set(x):
		lower_bone = x
		lower_id = -1
	get:
		match preset:
			0:
				return "LeftLowerArm"
			1:
				return "RightLowerArm"
			2:
				return "LeftLowerLeg"
			3:
				return "RightLowerLeg"
			_:
				return lower_bone

@export var upper_bone: StringName:
	set(x):
		upper_bone = x
		upper_id = -1
	get:
		match preset:
			0:
				return "LeftUpperArm"
			1:
				return "RightUpperArm"
			2:
				return "LeftUpperLeg"
			3:
				return "RightUpperLeg"
			_:
				return upper_bone

@export var mirror: bool:
	set(x):
		mirror = x
		mirror_factor = (-1 if mirror else 1)
	get:
		match preset:
			0, 2:
				return false
			1, 3:
				return true
			_:
				return mirror

var mirror_factor: float = 1
@export_range(-180.0, 180.0, 0.1, "radians") var upper_twist_offset: float = -0.5*PI
@export_range(-180.0, 180.0, 0.1, "radians") var lower_twist_offset: float = -0.5*PI
@export_range(-180.0, 180.0, 0.1, "radians") var roll_offset: float = deg_to_rad(-120.0) # Rolls the entire limb so the joint points in a different direction.
@export_range(0,1,0.001) var upper_limb_twist: float = 0.5 # How much the upper limb follows the lower limb.
@export_range(0,1,0.001) var lower_limb_twist: float = 0.66666 # How much the lower limb follows the leaf limb.
@export_range(-180.0, 180.0, 0.1, "radians") var twist_inflection_point_offset: float = deg_to_rad(180.0) # When the limb snaps from twisting in the positive direction to twisting in the negative direction.
@export_range(0.0, 180.0, 0.1, "radians") var twist_overflow: float = deg_to_rad(45.0) # How much past the inflection point we go before snapping.
# ADVANCED - How much the rotation the leaf points in affects the ik.
@export var target_rotation_influence: float = 0.33

# ADVANCED - Moving the limb 180 degrees from rest tends to
# be a bit unpredictable as there is a pole in the forward vector sphere at
# that spot. This offsets the rest position so that the pole is in a place
# where the limb is unlikely to go
@export var pole_offset: Quaternion = Quaternion.from_euler(Vector3(deg_to_rad(15.0), 0, deg_to_rad(60.0)))

# ADVANCED - How much each of the leaf's axis of translation from rest affects the ik.
@export var target_position_influence: Vector3 = Vector3(2.0, -1.5, -1.0)

@export_range(0.0,10.0,0.01) var stretchiness: float = 0.0

# STATE: We're keeping a little bit of state now... kinda goes against the design, but it makes life easier so fuck it.
var overflow_state: int = 0 # 0 means no twist overflow. -1 means underflow. 1 means overflow.

@export var has_shoulder: bool = true

@export_range(0,1,0.001) var arm_shoulder_influence: float = 0.25
#@export_range(-180,180,0.1,"radians")
@export var arm_shoulder_offset: Quaternion = Quaternion.IDENTITY

#@export_range(-180,180,0.1,"radians")
@export var arm_shoulder_pole_offset: Quaternion = Quaternion.from_euler(Vector3(0,0,deg_to_rad(-78.0)))


@export var dynamic_pole_root_bone: StringName:
	set(x):
		dynamic_pole_root_bone = x
		dynamic_pole_root_id = -1
	get:
		match preset:
			0, 1:
				return &"Hips"
			2, 3:
				return &""
			_:
				return dynamic_pole_root_bone

@export var dynamic_pole_head_bone: StringName:
	set(x):
		dynamic_pole_head_bone = x
		dynamic_pole_head_id = -1
	get:
		match preset:
			0, 1:
				return &"Head"
			2, 3:
				return &""
			_:
				return dynamic_pole_head_bone

@export var dynamic_pole_spine_length: float = 0.5
@export var dynamic_pole_min: float = 0.0
@export var dynamic_pole_max: float = 0.4
@export var dynamic_pole_power: float = 1.7

@export var pole_target: Node3D

@export var target: Node3D

@export_tool_button("Create Target") var create_target: Callable:
	get:
		return func():
			var skel = get_skeleton()
			if skel != null:
				if skel.has_node(NodePath(leaf_bone + "Target")):
					target = get_parent().get_node(NodePath(leaf_bone + "Target")) as Node3D
				else:
					var marker := Marker3D.new()
					marker.name = leaf_bone + "Target"
					skel.add_child(marker)
					marker.owner = owner
					marker.transform = skel.get_bone_global_pose(skel.find_bone(leaf_bone))
					target = marker

@export_tool_button("Reset Targets to Rest") var reset_targets_to_rest: Callable:
	get:
		return func():
			var skel := get_skeleton()
			if skel != null:
				var target_or_self: Node3D = target if target != null else self
				target_or_self.global_transform = skel.global_transform * skel.get_bone_global_rest(skel.find_bone(leaf_bone))


static func safe_acos(f: float) -> float:
	return acos(clampf(f, -1, 1))


static func safe_asin(f: float) -> float:
	return asin(clampf(f, -1, 1))


func bone_id_order_limb () -> PackedInt32Array:
	var ret: PackedInt32Array
	ret.push_back(upper_id)
	ret.append_array(upper_extra_bone_ids)
	ret.push_back(lower_id)
	ret.append_array(lower_extra_bone_ids)
	ret.push_back(leaf_id)
	return ret

func trig_angles(side1: Vector3, side2: Vector3, side3: Vector3) -> Vector2:
	# Law of Cosines
	var length1Squared: float = side1.length_squared()
	var length2Squared: float = side2.length_squared()
	var length3Squared: float = side3.length_squared()
	var length1: float = sqrt(length1Squared) * 2
	var length2: float = sqrt(length2Squared)
	var length3: float = sqrt(length3Squared) # multiply by 2 here to save on having to multiply by 2 twice later
	var angle1: float = renik_helper.safe_acos(
			(length1Squared + length3Squared - length2Squared) / (length1 * length3))
	var angle2: float = PI - renik_helper.safe_acos((length1Squared + length2Squared - length3Squared) / (length1 * length2))
	return Vector2(angle1, angle2)


func get_joint_axis(root: Transform3D, target: Transform3D, has_pole: bool, target_pole: Vector3) -> Vector3:
	var map: Dictionary[int, Basis]
	# The true root of the limb is the point where the upper bone starts
	var trueRoot: Transform3D = root.translated_local(self.upper.origin)
	var localTarget: Transform3D = trueRoot.affine_inverse() * target

	var full_upper: Transform3D = self.upper
	#.translated_local(Vector3(0, limb.upper_extra_bones.origin.length(), 0))
	var full_lower: Transform3D = self.lower
	#.translated_local(Vector3(0, limb.lower_extra_bones.origin.length(), 0))

	# The Triangle
	var upperVector: Vector3 = (self.upper_extra_bones * self.lower).origin
	var lowerVector: Vector3 = (self.lower_extra_bones * self.leaf).origin
	var targetVector: Vector3 = localTarget.origin
	var normalizedTargetVector: Vector3 = targetVector.normalized()
	var limbLength: float = upperVector.length() + lowerVector.length()
	if targetVector.length() > upperVector.length() + lowerVector.length():
		targetVector = normalizedTargetVector * limbLength

	var angles: Vector2 = trig_angles(upperVector, lowerVector, targetVector)

	var pole_offset_mirrored := Quaternion(
		pole_offset.x, mirror_factor * pole_offset.y,
		mirror_factor * pole_offset.z, pole_offset.w)
	# The local x-axis of the upper limb is axis along which the limb will bend
	# We take into account how the pole offset and alignment with the target
	# vector will affect this axis
	var startingPole: Vector3 = pole_offset_mirrored * (
			Vector3(0, 1, 0)) # the opposite of this vector is where the pole is
	var jointAxis: Vector3
	if has_pole:
		startingPole = trueRoot.affine_inverse() * target_pole
		jointAxis = targetVector.cross(startingPole);
		var angleDiff: float = 0 # targetVector.angle_to(startingPole) * influence
		if jointAxis.length_squared() == 0:
			jointAxis = renik_helper.get_perpendicular_vector(startingPole)
		# FIXME: double normalization
		jointAxis = jointAxis.normalized().normalized()
	else:
		jointAxis = renik_helper.align_vectors(startingPole, targetVector) * (pole_offset_mirrored * (Vector3(1, 0, 0)))

	# #We then find how far away from the rest position the leaf is and use
	# that to change the rotational axis more.
	var leafRestVector: Vector3 = full_upper.basis * (full_lower * (self.leaf.origin))
	var positionalOffset: float = (self.target_position_influence * Vector3(1, mirror_factor, mirror_factor)).dot(targetVector - leafRestVector)
	if not has_pole:
		jointAxis = jointAxis.rotated(normalizedTargetVector, positionalOffset + mirror_factor * self.roll_offset)

	# Leaf Rotations... here we go...
	# Let's always try to avoid having the leaf intersect the lowerlimb
	# First we find the a vector that corresponds with the direction the leaf
	# and lower limbs are pointing local to the true root
	var localLeafVector: Vector3 = localTarget.basis * (Vector3(0, 1, 0)) # y axis of the target
	var localLowerVector: Vector3 = normalizedTargetVector.rotated(jointAxis, angles.x - angles.y).normalized()
	# We then take the vector rejections of the leaf and lower limb against the
	# target vector A rejection is the opposite of a projection. We use the
	# target vector because that's our axis of rotation for the whole limb. We
	# then turn the whole arm along the target vector based on how close the
	# rejections are We scale the amount we rotate with the rotation influence
	# setting and the angle between the leaf and lower vector so if the arm is
	# mostly straight, we rotate less
	var leafRejection: Vector3 = renik_helper.vector_rejection(localLeafVector, normalizedTargetVector)
	var lowerRejection: Vector3 = renik_helper.vector_rejection(localLowerVector, normalizedTargetVector)
	var jointRollAmount: float = (leafRejection.angle_to(lowerRejection)) * self.target_rotation_influence
	jointRollAmount *= absf(localLeafVector.cross(localLowerVector).dot(normalizedTargetVector))
	if mirror_factor < 0: # if leafRejection.cross(lowerRejection).dot(normalizedTargetVector) > 0:
		jointRollAmount *= -1

	jointAxis = jointAxis.rotated(normalizedTargetVector, jointRollAmount)
	var totalRoll: float = jointRollAmount + positionalOffset + mirror_factor * self.roll_offset

	# Add a little twist
	# We align the leaf's y axis with the lower limb's y-axis and see how far
	# off the x-axis is from the joint axis to calculate the twist.
	var leafX: Vector3 = renik_helper.align_vectors(
					localLeafVector.rotated(normalizedTargetVector, jointRollAmount),
					localLowerVector.rotated(normalizedTargetVector, jointRollAmount)
					) * (localTarget.basis * (Vector3(1, 0, 0)))
	var rolledJointAxis: Vector3 = jointAxis.rotated(localLowerVector, -totalRoll)
	var lowerZ: Vector3 = rolledJointAxis.cross(localLowerVector)
	var twistAngle: float = leafX.angle_to(rolledJointAxis)
	if mirror_factor > 0: # leafX.dot(lowerZ) > 0:
		twistAngle *= -1


	var inflectionPoint: float = (PI if twistAngle > 0 else -PI) - mirror_factor * self.twist_inflection_point_offset
	var overflowArea: float = self.overflow_state * self.twist_overflow
	var inflectionDistance: float = twistAngle - inflectionPoint

	if absf(inflectionDistance) < self.twist_overflow:
		if self.overflow_state == 0:
			self.overflow_state = 1 if inflectionDistance < 0 else -1

	else:
		self.overflow_state = 0


	if not has_pole:
		inflectionPoint += overflowArea
		if twistAngle > 0 && twistAngle > inflectionPoint:
			twistAngle -= TAU # Change to complement angle
		elif twistAngle < 0 && twistAngle < inflectionPoint:
			twistAngle += TAU # Change to complement angle

	if not has_pole:
		jointAxis = jointAxis.rotated(normalizedTargetVector, twistAngle * self.target_rotation_influence)

	return jointAxis


func solve_trig_ik_redux(root: Transform3D, target: Transform3D, jointAxis: Vector3) -> Dictionary[int, Basis]:
	var map: Dictionary[int, Basis]
	# The true root of the limb is the point where the upper bone starts
	var trueRoot: Transform3D = root.translated_local(self.upper.origin)
	var localTarget: Transform3D = trueRoot.affine_inverse() * target

	var full_upper: Transform3D = self.upper
	#.translated_local(Vector3(0, limb.upper_extra_bones.origin.length(), 0))
	var full_lower: Transform3D = self.lower
	#.translated_local(Vector3(0, limb.lower_extra_bones.origin.length(), 0))

	# The Triangle
	var upperVector: Vector3 = (self.upper_extra_bones * self.lower).origin
	var lowerVector: Vector3 = (self.lower_extra_bones * self.leaf).origin
	var targetVector: Vector3 = localTarget.origin
	var normalizedTargetVector: Vector3 = targetVector.normalized()
	var limbLength: float = upperVector.length() + lowerVector.length()
	if targetVector.length() > upperVector.length() + lowerVector.length():
		targetVector = normalizedTargetVector * limbLength

	var angles: Vector2 = trig_angles(upperVector, lowerVector, targetVector)

	# #We then find how far away from the rest position the leaf is and use
	# that to change the rotational axis more.
	var leafRestVector: Vector3 = full_upper.basis * (full_lower * (self.leaf.origin))
	var positionalOffset: float = (self.target_position_influence * Vector3(1, mirror_factor, mirror_factor)).dot(targetVector - leafRestVector)

	# Duplicate code from get_joint_axis()
	var localLeafVector: Vector3 = localTarget.basis * (Vector3(0, 1, 0)) # y axis of the target
	var localLowerVector: Vector3 = normalizedTargetVector.rotated(jointAxis, angles.x - angles.y).normalized()
	var leafRejection: Vector3 = renik_helper.vector_rejection(localLeafVector, normalizedTargetVector)
	var lowerRejection: Vector3 = renik_helper.vector_rejection(localLowerVector, normalizedTargetVector)
	var jointRollAmount: float = (leafRejection.angle_to(lowerRejection)) * self.target_rotation_influence
	jointRollAmount *= absf(localLeafVector.cross(localLowerVector).dot(normalizedTargetVector))
	if leafRejection.cross(lowerRejection).dot(normalizedTargetVector) > 0:
		jointRollAmount *= -1

	jointAxis = jointAxis.rotated(normalizedTargetVector, jointRollAmount)
	var totalRoll: float = jointRollAmount + positionalOffset + mirror_factor * self.roll_offset

	# Add a little twist
	# We align the leaf's y axis with the lower limb's y-axis and see how far
	# off the x-axis is from the joint axis to calculate the twist.
	var leafX: Vector3 = renik_helper.align_vectors(
					localLeafVector.rotated(normalizedTargetVector, jointRollAmount),
					localLowerVector.rotated(normalizedTargetVector, jointRollAmount)
					) * (localTarget.basis * (Vector3(1, 0, 0)))
	var rolledJointAxis: Vector3 = jointAxis.rotated(localLowerVector, -totalRoll)
	var lowerZ: Vector3 = rolledJointAxis.cross(localLowerVector)
	var twistAngle: float = leafX.angle_to(rolledJointAxis)
	if leafX.dot(lowerZ) > 0:
		twistAngle *= -1


	var inflectionPoint: float = (PI if twistAngle > 0 else -PI) - mirror_factor * self.twist_inflection_point_offset
	var overflowArea: float = self.overflow_state * self.twist_overflow
	var inflectionDistance: float = twistAngle - inflectionPoint

	if absf(inflectionDistance) < self.twist_overflow:
		if self.overflow_state == 0:
			self.overflow_state = 1 if inflectionDistance < 0 else -1

	else:
		self.overflow_state = 0


	inflectionPoint += overflowArea
	if twistAngle > 0 && twistAngle > inflectionPoint:
		twistAngle -= TAU # Change to complement angle
	elif twistAngle < 0 && twistAngle < inflectionPoint:
		twistAngle += TAU # Change to complement angle

	var pole_offset_mirrored = Quaternion(
		pole_offset.x, mirror_factor * pole_offset.y,
		mirror_factor * pole_offset.z, pole_offset.w)
	# The local x-axis of the upper limb is axis along which the limb will bend
	# We take into account how the pole offset and alignment with the target
	# vector will affect this axis

	var lowerTwist: float = twistAngle * self.lower_limb_twist
	var upperTwist: float = lowerTwist * self.upper_limb_twist + mirror_factor * self.upper_twist_offset - totalRoll
	lowerTwist += mirror_factor * self.lower_twist_offset - 2 * mirror_factor * self.roll_offset - positionalOffset - jointRollAmount

	# Rebuild the rotations
	var upperJointVector: Vector3 = normalizedTargetVector.rotated(jointAxis, angles.x)
	var rolledLowerJointAxis: Vector3 = Vector3(1, 0, 0).rotated(Vector3(0, 1, 0), -mirror_factor * self.roll_offset)
	var lowerJointVector: Vector3 = Vector3(0, 1, 0).rotated(rolledLowerJointAxis, angles.y)
	var twistedJointAxis: Vector3 = jointAxis.rotated(upperJointVector, upperTwist)
	var upperBasis: Basis = Basis(twistedJointAxis, upperJointVector, twistedJointAxis.cross(upperJointVector))
	var lowerBasis: Basis = Basis(rolledLowerJointAxis, lowerJointVector, rolledLowerJointAxis.cross(lowerJointVector))
	lowerBasis = lowerBasis.transposed()
	lowerBasis = lowerBasis * Basis(Vector3(0, 1, 0), lowerTwist)
	lowerBasis = lowerBasis.rotated(Vector3(0, 1, 0), -upperTwist)

	var upperTransform: Basis = ((full_upper.basis.inverse() * upperBasis).orthonormalized())
	var lowerTransform: Basis = ((full_lower.basis.inverse() * lowerBasis).orthonormalized())
	var leafTransform: Basis = (self.leaf.basis.inverse() * (upperBasis * lowerBasis).inverse() * localTarget.basis * self.leaf.basis)
	map[self.upper_id] = upperTransform
	for bone_id in self.upper_extra_bone_ids:
		map[bone_id] = Basis()

	map[self.lower_id] = lowerTransform # limb.upper_extra_bones.affine_inverse() * (full_lower.basis.inverse() * lowerBasis)
	for bone_id in self.lower_extra_bone_ids:
		map[bone_id] = Basis()

	map[self.leaf_id] = leafTransform

	return map


func apply_ik_map_basis(ik_map: Dictionary[int, Basis], global_parent: Transform3D, apply_order: PackedInt32Array):
	var skeleton := get_skeleton()
	if skeleton:
		for apply_i in apply_order:
			var local_basis: Basis = ik_map[apply_i]
			skeleton.set_bone_pose_rotation(apply_i, local_basis.get_rotation_quaternion())


func get_extra_bones(skeleton: Skeleton3D, p_root_bone_id: int, p_tip_bone_id: int) -> Transform3D:
	var cumulative_rest: Transform3D
	var current_bone_id: int = p_tip_bone_id
	while current_bone_id != -1 && current_bone_id != p_root_bone_id:
		current_bone_id = skeleton.get_bone_parent(current_bone_id)
		if current_bone_id == -1 || current_bone_id == p_root_bone_id:
			break
		cumulative_rest = skeleton.get_bone_rest(current_bone_id) * cumulative_rest

	return cumulative_rest

func get_extra_bone_ids(skeleton: Skeleton3D, p_root_bone_id: int, p_tip_bone_id: int) -> PackedInt32Array:
	var output: PackedInt32Array
	var current_bone_id: int = p_tip_bone_id
	while current_bone_id != -1:
		current_bone_id = skeleton.get_bone_parent(current_bone_id)
		if current_bone_id == -1 || current_bone_id == p_root_bone_id:
			break
		output.push_back(current_bone_id)

	return output


func update_bones() -> void:
	var skeleton: Skeleton3D = get_skeleton()
	if skeleton != null and (leaf_id == -1 or lower_id == -1 or upper_id == -1):

		match preset:
			0:
				has_shoulder = true
			1:
				has_shoulder = true
			2:
				has_shoulder = false
			3:
				has_shoulder = false
		if leaf_id == -1 and not leaf_bone.is_empty():
			leaf_id = skeleton.find_bone(leaf_bone)
		if lower_id == -1 and not lower_bone.is_empty():
			lower_id = skeleton.find_bone(lower_bone)
		if upper_id == -1 and not upper_bone.is_empty():
			upper_id = skeleton.find_bone(upper_bone)
		
		if leaf_id >= 0:
			lower_id = lower_id if lower_id >= 0 else skeleton.get_bone_parent(leaf_id)
		if leaf_id >= 0 and lower_id >= 0:
			upper_id = upper_id if upper_id >= 0 else skeleton.get_bone_parent(lower_id)
		if leaf_id >= 0 and lower_id >= 0 and upper_id >= 0:
			# leaf = get_full_rest(skeleton, leaf_id, lower_id)
			# lower = get_full_rest(skeleton, lower_id, upper_id)
			# upper = skeleton.get_bone_rest(upper_id)

			lower_extra_bones = get_extra_bones(
					skeleton, lower_id,
					leaf_id) # lower bone + all bones after that except the leaf
			upper_extra_bones = get_extra_bones(
					skeleton, upper_id,
					lower_id) # upper bone + all bones between upper and lower
			lower_extra_bone_ids = get_extra_bone_ids(skeleton, lower_id, leaf_id)
			upper_extra_bone_ids = get_extra_bone_ids(skeleton, upper_id, lower_id)

			leaf = Transform3D(Basis(), skeleton.get_bone_rest(leaf_id).origin)
			lower = Transform3D(Basis(), skeleton.get_bone_rest(lower_id).origin)
			upper = Transform3D(Basis(), skeleton.get_bone_rest(upper_id).origin)
	if skeleton != null and dynamic_pole_root_id == -1 and not dynamic_pole_root_bone.is_empty():
		dynamic_pole_root_id = skeleton.find_bone(dynamic_pole_root_bone)
	if skeleton != null and dynamic_pole_head_id == -1 and not dynamic_pole_head_bone.is_empty():
		dynamic_pole_head_id = skeleton.find_bone(dynamic_pole_head_bone)


func is_valid() -> bool:
	update_bones()
	return upper_id >= 0 && lower_id >= 0 && leaf_id >= 0


func is_valid_in_skeleton(skeleton: Skeleton3D) -> bool:
	update_bones()
	if (skeleton == null || upper_id < 0 || lower_id < 0 || leaf_id < 0 ||
			upper_id >= skeleton.get_bone_count() ||
			lower_id >= skeleton.get_bone_count() ||
			leaf_id >= skeleton.get_bone_count()):
		return false

	var curr: int = skeleton.get_bone_parent(leaf_id)
	while curr != -1 && curr != lower_id:
		curr = skeleton.get_bone_parent(curr)

	while curr != -1 && curr != upper_id:
		#print(skeleton.get_bone_name(curr))
		curr = skeleton.get_bone_parent(curr)

	return curr != -1


func _process_modification() -> void:
	if not is_valid_in_skeleton(get_skeleton()):
		return
	if not target:
		return

	var skeleton := get_skeleton()
	var global_parent: Transform3D = skeleton.get_bone_global_pose(skeleton.get_bone_parent(upper_id))
	var skel_inverse: Transform3D = skeleton.global_transform.affine_inverse()
	var target_transform: Transform3D = (skel_inverse * target.global_transform).orthonormalized()
	var target_pole_transform: Transform3D
	var target_pole: Vector3
	var has_pole: bool = false
	if pole_target != null and pole_target.visible:
		target_pole_transform = (skel_inverse * pole_target.global_transform).orthonormalized()
		target_pole = target_pole_transform * (
			Quaternion(Vector3.UP, -mirror_factor * self.lower_twist_offset) * Vector3(0,0,1000))
		has_pole = true

	if (target && target.visible && skeleton && is_valid_in_skeleton(skeleton)):
		if not has_pole and dynamic_pole_root_id != -1 and dynamic_pole_head_id != -1:
			var global_pole_root: Transform3D = skeleton.get_bone_global_pose(dynamic_pole_root_id)
			var global_pole_head: Transform3D = skeleton.get_bone_global_pose(dynamic_pole_head_id)
			has_pole = true
			var arm_pole_length := (leaf.origin.length() + lower.origin.length()) * 2
			var up_direction: Vector3 = (global_pole_head.origin - global_pole_root.origin).normalized()
			var forward_direction: Vector3 = (global_pole_root.basis * Vector3.FORWARD).slerp(global_pole_head.basis * Vector3.FORWARD, 0.3).normalized()
			var right_direction: Vector3 = (up_direction.cross(forward_direction) + forward_direction * 0.001).normalized()
			var spine_basis := Basis(right_direction, up_direction, forward_direction).orthonormalized()
			var arm_midpoint: Vector3 = target_transform.origin.lerp(global_parent.origin, 0.5)
			var vec_factor: float = (target_transform.origin - global_parent.origin).normalized().dot(target_transform.basis * Vector3(0,0,1))
			vec_factor = dynamic_pole_spine_length * smoothstep(dynamic_pole_min, dynamic_pole_max, sign(vec_factor) * pow(abs(vec_factor), dynamic_pole_power))
			var vec1: Vector3 = 0.5 * arm_pole_length * (spine_basis * Vector3(mirror_factor * -2.0,0.0,2)).normalized() # Vector3(0,1,0)
			var vec2: Vector3 = arm_pole_length * (spine_basis * Vector3(mirror_factor * -2.0,1.0,-2)).normalized() #target_pole.normalized()
			target_pole = (global_pole_root.origin * 2 - global_pole_head.origin + vec1).lerp(global_pole_head.origin + vec2, vec_factor)

		var joint_axis: Vector3 = get_joint_axis(global_parent, target_transform, has_pole, target_pole)
		var root: Transform3D = global_parent
		if has_shoulder:
			var rootBone: int = skeleton.get_bone_parent(upper_id)
			if rootBone >= 0:
				var shoulderParent: int = skeleton.get_bone_parent(rootBone)
				var targetVector: Vector3 = root.affine_inverse() * (target_pole_transform.origin if has_pole else target_transform.origin)
				var offsetQuat: Quaternion = Quaternion(Vector3(0,1,0), arm_shoulder_influence * Quaternion(arm_shoulder_offset * Vector3(-1,0,0), joint_axis).get_euler().y)
				var poleOffset: float = atan(4 * (1 - targetVector.length() / lower.origin.length()))
				poleOffset = maxf(poleOffset, 2.0 * (root.affine_inverse() * target_transform).origin.normalized().z)
				var poleOffsetScaled: float = poleOffset * (arm_shoulder_influence / 2 if poleOffset < 0.0 else arm_shoulder_influence)
				var quatAlignToTarget: Quaternion = Quaternion(arm_shoulder_pole_offset * Vector3(0,1,0), poleOffsetScaled * PI / 2).normalized()
				var customPose: Transform3D = Transform3D(offsetQuat * quatAlignToTarget, Vector3())
				skeleton.set_bone_pose_rotation(rootBone, skeleton.get_bone_pose_rotation(rootBone) * offsetQuat * quatAlignToTarget)
				root = root * customPose
				joint_axis = joint_axis * customPose

		apply_ik_map_basis(solve_trig_ik_redux(root, target_transform, joint_axis), root, bone_id_order_limb())
		var scl: float = clampf(
			skeleton.get_bone_global_pose(upper_id).origin.distance_to(target_transform.origin) /
			skeleton.get_bone_global_pose(upper_id).origin.distance_to(skeleton.get_bone_global_pose(leaf_id).origin),
			1.0, 1.0 + stretchiness)
		skeleton.set_bone_pose_scale(upper_id, Vector3(1, scl, 1))
		skeleton.set_bone_pose_scale(leaf_id, Vector3(1, 1 /scl, 1))
