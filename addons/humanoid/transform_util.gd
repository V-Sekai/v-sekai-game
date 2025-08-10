# -!- coding: utf-8 -!-
#
# Copyright 2023-present Lyuma and contributors
# Copyright 2022-2023 lox9973
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#	 http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# SPDX-License-Identifier: Apache-2.0
@tool
extends RefCounted

const human_trait := preload("./human_trait.gd")

static func calculate_humanoid_rotation(bone_idx: int, muscle_triplet: Vector3, from_postq: bool = false) -> Quaternion:
	var muscle_from_bone: PackedInt32Array = human_trait.MuscleFromBone[bone_idx]
	for i in range(3):
		if muscle_from_bone[i] == -1:
			continue
		muscle_triplet[i] *= deg_to_rad(
			human_trait.MuscleDefaultMax[muscle_from_bone[i]] if muscle_triplet[i] >= 0
			else -human_trait.MuscleDefaultMin[muscle_from_bone[i]])
	muscle_triplet *= Vector3(1,-1,-1) * human_trait.Signs[bone_idx]
	var preQ : Quaternion = human_trait.preQ_exported[bone_idx]
	if from_postq:
		preQ = human_trait.postQ_inverse_exported[bone_idx].inverse().normalized()
	if not preQ.is_normalized():
		push_error("preQ is not normalized " + str(bone_idx))
	var invPostQ : Quaternion = human_trait.postQ_inverse_exported[bone_idx]
	if not invPostQ.is_normalized():
		push_error("invPostQ is not normalized " + str(bone_idx))
	var swing_res: Quaternion = swing_twist(muscle_triplet)
	if not swing_res.is_normalized():
		push_error("swing_res is not normalized " + str(bone_idx) + " " + str(muscle_triplet))
	var ret: Quaternion = preQ * swing_res * invPostQ
	if not ret.is_normalized():
		push_error("ret is not normalized " + str(bone_idx) + " " + str(muscle_triplet) + " " + str(preQ) + "," + str(swing_res) + "," + str(invPostQ))
	ret = ret.normalized()
	if not ret.is_normalized():
		push_error("ret is not normalized " + str(bone_idx) + " " + str(muscle_triplet) + " " + str(preQ) + "," + str(swing_res) + "," + str(invPostQ))
	return ret

'''
static func setBody(humanPositions: Array[Vector3], humanRotations: Array[Quaternion], rootT, rootQ):
	var hipsPosition := humanPositions[0]
	var hipsRotation := humanRotations[0]
	var sourceT := getMassT(humanPositions, humanRotations)
	var sourceQ := getMassQ(humanPositions)
	var targetT: Vector3 = Vector3(-1,1,1) * rootT
	var targetQ := Quaternion(rootQ.x, -rootQ.y, -rootQ.z, rootQ.w)
	var deltaQ: Quaternion = targetQ * sourceQ.inverse()
	sourceT = deltaQ * (sourceT - hipsPosition)
	hips.position = targetT - deltaQ * (sourceT - hipsPosition)
	hips.rotation = deltaQ
'''

# Based on uvw.js HumanPoseHandler.setBody
static func get_hips_rotation_delta(humanPositions: Array[Vector3], targetQ: Quaternion) -> Quaternion:
	var sourceQ := getMassQ(humanPositions)
	#return Quaternion(targetQ.x, -targetQ.y, -targetQ.z, targetQ.w) * sourceQ.inverse()
	return targetQ * sourceQ.inverse()
	# Quaternion(Vector3.UP, PI) * 

# Based on uvw.js HumanPoseHandler.setBody
# deltaQ is the result of get_hips_rotation_delta()
static func get_hips_position(humanPositions: Array[Vector3], humanRotations: Array[Quaternion], deltaQ: Quaternion, targetT: Vector3) -> Vector3:
	var hipsPosition := humanPositions[0]
	var hipsRotation := humanRotations[0]
	var sourceT := getMassT(humanPositions, humanRotations)
	sourceT = deltaQ * (sourceT - hipsPosition)
	return targetT - sourceT

static func getMassQ(humanPositions: Array[Vector3]) -> Quaternion:
	human_trait.boneIndexToMono.find(human_trait.HumanBodyBones.LeftUpperArm)
	var leftUpperArmT := humanPositions[14] # boneIndexToMono.find(LeftUpperArm)
	var rightUpperArmT := humanPositions[15] # boneIndexToMono.find(RightUpperArm)
	var leftUpperLegT := humanPositions[1] # boneIndexToMono.find(LeftUpperLeg)
	var rightUpperLegT := humanPositions[2] # boneIndexToMono.find(RightUpperLeg)
	# this interpretation of "average left/right hips/shoulders vectors" seems most accurate
	var x: Vector3 = (leftUpperArmT + leftUpperLegT) - (rightUpperArmT + rightUpperLegT)
	var y: Vector3 = (leftUpperArmT + rightUpperArmT) - (leftUpperLegT + rightUpperLegT)
	x = x.normalized()
	y = y.normalized()
	var z: Vector3 = x.cross(y).normalized()
	x = y.cross(z)
	return Basis(x, y, z).get_rotation_quaternion()

static func getMassT(humanPositions: Array[Vector3], humanRotations: Array[Quaternion]) -> Vector3:
	var sum: float = 1.0e-6
	var out := Vector3.ZERO
	for i in range(len(humanPositions)):
		# var postQ_inverse := human_trait.postQ_inverse_exported[i]
		var m_HumanBoneMass := human_trait.human_bone_mass[i] # m_HumanBoneMass
		var axisLength := human_trait.bone_lengths[i] # m_AxesArray.m_Length
		if m_HumanBoneMass:
			#var centerT := Vector3(axisLength/2, 0, 0) # GUESS: mass-center at half bone length
			#centerT = postQ_inverse.inverse() * centerT # Bring centerT from source coords to Godot coords
			var centerT := Vector3(0, axisLength/2, 0)
			centerT = humanPositions[i] + humanRotations[i] * centerT
			out += centerT * m_HumanBoneMass
			sum += m_HumanBoneMass
	return out / sum

static func swing_twist(vec: Vector3) -> Quaternion:
	var x: float = vec.x
	var y: float = vec.y
	var z: float = vec.z
	var yz = sqrt(y*y + z*z)
	var sinc = 0.5 if abs(yz) < 1e-8 else sin(yz/2)/yz
	var swingW = cos(yz/2)
	var twistW = cos(x/2)
	var twistX = sin(x/2)
	return Quaternion(
		swingW * twistX,
		(z * twistX + y * twistW) * sinc,
		(z * twistW - y * twistX) * sinc,
		swingW * twistW)

static func swing_twist_inv(q: Quaternion) -> Vector3:
	var a: float = q.x
	var b: float = q.y
	var c: float = q.z
	var d: float = q.w

	# ------
	# Original swing_twist function, using same notation:
	# var yz = sqrt(y*y + z*z)
	# var sinc = 0.5 if abs(yz) < 1e-8 else sin(yz/2)/yz
	# var swingW = cos(yz/2)
	# var twistW = cos(x/2)
	# var twistX = sin(x/2)
	# a = swingW * twistX,
	# b = (z * twistX + y * twistW) * sinc,
	# c = (z * twistW - y * twistX) * sinc,
	# d = swingW * twistW)
	# ------
	# Therefore, we can conclude the following:
	# a = cos(yz/2) * sin(x/2)
	# d = cos(yz/2) * cos(x/2)
	# d = cos(yz/2) * sqrt(1 - sin(x/2) * sin(x/2))
	# swingW = a / twistX = swingW
	# swingW = d / sqrt(1 - twistX*twistX)
	# This allows us to solve for twistX and swingW given and b:
	var twistX: float = 0
	if not is_zero_approx(a * a + d * d):
		twistX = sqrt(a * a / (a * a + d * d))
	if twistX >= 1.0:
		twistX = 1.0
	if a < 0:
		twistX *= -1
	if d < 0:
		twistX *= -1

	var twistW: float = sqrt(1 - twistX * twistX)
	var swingW: float
	if is_zero_approx(twistX):
		swingW = d / twistW
	else:
		swingW = a / twistX
	# Given these variables, we now know the values of x and yz:
	var x: float = asin(twistX) * 2 # * axis_constraints.x
	var yz: float = acos(swingW) * 2
	var sinc: float = 0.5 if abs(yz) < 1e-8 else sin(yz/2)/yz
	twistX = 1e-8 if is_zero_approx(twistX) else twistX
	twistW = 1e-8 if is_zero_approx(twistW) else twistW

	# Finally, we solve for y and z given b and c:
	# b = (z * twistX + y * twistW) * sinc
	# c = (z * twistW - y * twistX) * sinc

	# b / twistX = (z + y * twistW / twistX) * sinc
	# c / twistW = (z - y * twistX / twistW) * sinc
	# b / twistX - c / twistW = y * (twistW / twistX + twistX / twistW) * sinc
	var y: float = (b / twistX - c / twistW) / (twistW / twistX + twistX / twistW) / sinc

	# b / twistW = (z * twistX / twistW + y) * sinc
	# c / twistX = (z * twistW / twistX - y) * sinc
	# b / twistW + c / twistX = z * (twistX / twistW + twistW / twistX) * sinc
	var z: float = (b / twistW + c / twistX) / (twistX / twistW + twistW / twistX) / sinc

	return Vector3(x, y, z)

static func inverse_calculate_humanoid_rotation(leftovers: Array[Quaternion], bone_idx: int, rotation: Quaternion, from_postq: bool = false) -> Vector3:
	var muscle_from_bone: PackedInt32Array = human_trait.MuscleFromBone[bone_idx]
	var mono_bone_idx: int = bone_idx
	if bone_idx == human_trait.HumanBodyBones.UpperChest:
		mono_bone_idx = 9
	elif bone_idx > human_trait.HumanBodyBones.Chest:
		mono_bone_idx += 1
	var parent_bone_idx: int = human_trait.boneIndexToMono[human_trait.boneIndexToParent[mono_bone_idx]]
		
	var leftover_rotation = Quaternion()
	if parent_bone_idx >= 0 and parent_bone_idx < leftovers.size():
		leftover_rotation = leftovers[parent_bone_idx]

	rotation = leftover_rotation * rotation

	var preQ : Quaternion = human_trait.preQ_exported[bone_idx]
	if from_postq:
		preQ = human_trait.postQ_inverse_exported[bone_idx].inverse().normalized()
	var invPostQ : Quaternion = human_trait.postQ_inverse_exported[bone_idx]

	var swing_res: Quaternion = (preQ.inverse() * rotation * invPostQ.inverse()).normalized()
	if not swing_res.is_normalized():
		push_error("swing_res is not normalized " + str(bone_idx))
		swing_res = swing_res.normalized()

	var allowed_axes := Vector3(
		0 if muscle_from_bone[0] == -1 else 1,
		0 if muscle_from_bone[1] == -1 else 1,
		0 if muscle_from_bone[2] == -1 else 1)
	if allowed_axes != Vector3.ONE:
		swing_res = Quaternion(Basis.from_euler(swing_res.get_euler(EULER_ORDER_ZYX) * allowed_axes, EULER_ORDER_ZYX))
		if not swing_res.is_normalized():
			push_error("swing_res is not normalized after euler " + str(bone_idx))
			swing_res = swing_res.normalized()

	var muscle_triplet: Vector3 = swing_twist_inv(swing_res)
	muscle_triplet *= Vector3(1,-1,-1) * human_trait.Signs[bone_idx]

	for i in range(3):
		if muscle_from_bone[i] == -1:
			# TODO: What should we do if attempting to encode rotation on a missing axis?
			muscle_triplet[i] = 0.0
			continue
		muscle_triplet[i] /= deg_to_rad(
			human_trait.MuscleDefaultMax[muscle_from_bone[i]] if muscle_triplet[i] >= 0
			else -human_trait.MuscleDefaultMin[muscle_from_bone[i]])

	var invx: Quaternion = calculate_humanoid_rotation(bone_idx, muscle_triplet, from_postq)
	leftovers[bone_idx] = invx.inverse() * rotation

	return muscle_triplet
