# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# head_controller.gd
# SPDX-License-Identifier: MIT

extends Node

var docstring = """
Based of Head.cpp from High Fidelity
Copyright 2013 High Fidelity, Inc.

Distributed under the Apache License, Version 2.0
See the accompanying file LICENSE or http://www.apache.org/licenses/LICENSE-2.0.html
"""

const EPSILON = 0.000001  # TODO: expose this as a built-in constant

const AUDIO_AVERAGING_SECS = 0.05
const AUDIO_LONG_TERM_AVERAGING_SECS = 15.0

# Saccades
const AVERAGE_MICROSACCADE_INTERVAL = 1.0
const AVERAGE_SACCADE_INTERVAL = 6.0
const MICROSACCADE_MAGNITUDE = 0.002
const SACCADE_MAGNITUDE = 0.04
const NOMINAL_FRAME_RATE = 60.0

# Blink
const BLINK_SPEED = 10.0
const BLINK_SPEED_VARIABILITY = 1.0
const BLINK_START_VARIABILITY = 0.25
const FULLY_OPEN = 0.0
const FULLY_CLOSED = 1.0
const TALKING_LOUDNESS = 150.0
const BLINK_AFTER_TALKING = 0.25
const BASE_BLINK_RATE = 15.0 / 60.0
const ROOT_LOUDNESS_TO_BLINK_INTERVAL = 0.25
const MIN_BLINK_ANGLE = 0.35  # 20 degrees

# Brow
const BROW_LIFT_THRESHOLD = 100.0

# Mouth
const SILENT_TRAILING_JAW_OPEN = 0.0002
const MAX_SILENT_MOUTH_TIME = 10.0

# Mouth shape consts
const JAW_OPEN_SCALE = 0.35
const JAW_OPEN_RATE = 0.9
const JAW_CLOSE_RATE = 0.90
const TIMESTEP_CONSTANT = 0.0032
const MMMM_POWER = 0.10
const SMILE_POWER = 0.10
const FUNNEL_POWER = 0.35
const MMMM_SPEED = 2.685
const SMILE_SPEED = 1.0
const FUNNEL_SPEED = 2.335
const STOP_GAIN = 5.0
const NORMAL_HZ = 60.0
const MAX_DELTA_LOUDNESS = 100.0

const EYE_PITCH_TO_COEFFICIENT = 3.5
const MAX_EYELID_OFFSET = 1.5
const BLINK_DOWN_MULTIPLIER = 0.25
const OPEN_DOWN_MULTIPLIER = 0.3
const BROW_UP_MULTIPLIER = 0.5

# Lean
const LEAN_RELAXATION_PERIOD = 0.25  #seconds

const LOOKING_AT_ME_GAP_ALLOWED = (5 * 1000 * 1000) / 60  # n frames, in microseconds

@export var avatar_display_path: NodePath = NodePath()
# var _avatar_display: Node3D = null

var left_eye_blink: float = 0.0
var right_eye_blink: float = 0.0
var average_loudness: float = 0.0
var brow_audio_lift: float = 0.0

var look_at_position: Vector3 = Vector3()

var position: Vector3 = Vector3()
var rotation: Vector3 = Vector3()
var left_eye_position: Vector3 = Vector3()
var right_eye_position: Vector3 = Vector3()
var eye_position: Vector3 = Vector3()

var last_loudness: float = 0.0
var long_term_average_loudness: float = -1.0
var audio_attack: float = 0.0
var audio_jaw_open: float = 0.0
var trailing_audio_jaw_open: float = 0.0
var mouth2: float = 0.0
var mouth3: float = 0.0
var mouth4: float = 0.0
var mouth_time: float = 0.0

var saccade: Vector3 = Vector3()
var saccade_target: Vector3 = Vector3()
var left_eye_blink_velocity: float = 0.0
var right_eye_blink_velocity: float = 0.0
var time_without_talking: float = 0.0

var request_look_at_position: Vector3 = Vector3()
var force_blink_to_retarget: bool = false
var is_eye_look_at_updated: bool = false

var disable_eyelid_adjustment: bool = false

enum Blendshapes { EyeBlink_L = 0, EyeBlink_R, EyeSquint_L, EyeSquint_R, EyeDown_L, EyeDown_R, EyeIn_L, EyeIn_R, EyeOpen_L, EyeOpen_R, EyeOut_L, EyeOut_R, EyeUp_L, EyeUp_R, BrowsD_L, BrowsD_R, BrowsU_C, BrowsU_L, BrowsU_R, JawFwd, JawLeft, JawOpen, JawRight, MouthLeft, MouthRight, MouthFrown_L, MouthFrown_R, MouthSmile_L, MouthSmile_R, MouthDimple_L, MouthDimple_R, LipsStretch_L, LipsStretch_R, LipsUpperClose, LipsLowerClose, LipsFunnel, LipsPucker, Puff, CheekSquint_L, CheekSquint_R, MouthClose, MouthUpperUp_L, MouthUpperUp_R, MouthLowerDown_L, MouthLowerDown_R, MouthPress_L, MouthPress_R, MouthShrugLower, MouthShrugUpper, NoseSneer_L, NoseSneer_R, TongueOut, UserBlendshape0, UserBlendshape1, UserBlendshape2, UserBlendshape3, UserBlendshape4, UserBlendshape5, UserBlendshape6, UserBlendshape7, UserBlendshape8, UserBlendshape9, BlendshapeCount }

var transient_blendshape_coefficents: PackedFloat32Array = PackedFloat32Array()


static func should_do(p_desired_interval: float, p_delta: float) -> bool:
	return randf() < p_delta / p_desired_interval


static func rand_vector3() -> Vector3:
	return Vector3(randf() - 0.5, randf() - 0.5, randf() - 0.5) * 2.0


static func update_fake_coefficients(p_left_blink, p_right_blink, p_brow_up, p_jaw_open, p_mouth2, p_mouth3, p_mouth4, p_coefficients) -> PackedFloat32Array:
	p_coefficients.resize(max(p_coefficients.size(), Blendshapes.BlendshapeCount))

	p_coefficients[Blendshapes.EyeBlink_L] = p_left_blink
	p_coefficients[Blendshapes.EyeBlink_R] = p_right_blink
	p_coefficients[Blendshapes.BrowsU_C] = p_brow_up
	p_coefficients[Blendshapes.BrowsU_L] = p_brow_up
	p_coefficients[Blendshapes.BrowsU_R] = p_brow_up
	p_coefficients[Blendshapes.JawOpen] = p_jaw_open
	p_coefficients[Blendshapes.MouthSmile_R] = p_mouth4
	p_coefficients[Blendshapes.MouthSmile_L] = p_coefficients[Blendshapes.MouthSmile_R]
	p_coefficients[Blendshapes.LipsUpperClose] = p_mouth2
	p_coefficients[Blendshapes.LipsFunnel] = p_mouth3

	return p_coefficients


func get_orientation() -> Quaternion:
	printerr("get_orientation not implemented!")
	return Quaternion()


func calculate_mouth_shapes(p_delta: float) -> void:
	var delta_time_ratio: float = p_delta / (1.0 / NORMAL_HZ)

	# From the change in loudness, decide how much to open or close the jaw
	var delta_loudness: float = max(min(average_loudness - long_term_average_loudness, MAX_DELTA_LOUDNESS), 0.0) / MAX_DELTA_LOUDNESS
	var audio_delta: float = pow(delta_loudness, 2.0) * JAW_OPEN_SCALE
	if audio_delta > audio_jaw_open:
		audio_jaw_open += (audio_delta - audio_jaw_open) * JAW_OPEN_RATE * delta_time_ratio
	else:
		audio_jaw_open *= pow(JAW_CLOSE_RATE, delta_time_ratio)

	audio_jaw_open = clamp(audio_jaw_open, 0.0, 1.0)
	var trailing_audio_jaw_open_ratio = (100.0 - p_delta * NORMAL_HZ) / 100.0  # --> 0.99 at 60 Hz
	trailing_audio_jaw_open = lerpf(trailing_audio_jaw_open, audio_jaw_open, trailing_audio_jaw_open_ratio)

	# truncate _mouthTime when mouth goes quiet to prevent floating point error on increment
	if trailing_audio_jaw_open < SILENT_TRAILING_JAW_OPEN && mouth_time > MAX_SILENT_MOUTH_TIME:
		mouth_time = 0.0

	# Advance time at a rate proportional to loudness, and move the mouth shapes through
	# a cycle at differing speeds to create a continuous random blend of shapes.
	mouth_time += sqrt(average_loudness) * TIMESTEP_CONSTANT * delta_time_ratio
	mouth2 = ((sin(mouth_time * MMMM_SPEED) + 1.0) * MMMM_POWER * min(1.0, trailing_audio_jaw_open * STOP_GAIN))
	mouth3 = ((sin(mouth_time * FUNNEL_SPEED) + 1.0) * FUNNEL_POWER * min(1.0, trailing_audio_jaw_open * STOP_GAIN))
	mouth4 = ((sin(mouth_time * SMILE_SPEED) + 1.0) * SMILE_POWER * min(1.0, trailing_audio_jaw_open * STOP_GAIN))


func get_look_at_position() -> Vector3:
	return look_at_position


func apply_eyelid_offset(p_head_orientation: Quaternion) -> void:
	# Adjusts the eyelid blendshape coefficients so that the eyelid follows the iris as the head pitches.
	var is_blinking: bool = right_eye_blink_velocity != 0.0 and left_eye_blink_velocity != 0.0
	if disable_eyelid_adjustment or is_blinking:
		return

	var look_at_vector: Vector3 = get_look_at_position() - eye_position
	#if (glm::length2(lookAtVector) == 0.0):
	#   return

	var look_at: Vector3 = look_at_vector.normalized()
	var head_up: Vector3 = p_head_orientation * Vector3.UP
	var eye_pitch: float = (PI / 2.0) - acos(look_at.dot(head_up))
	var eyelid_offset: float = clamp(abs(eye_pitch * EYE_PITCH_TO_COEFFICIENT), 0.0, MAX_EYELID_OFFSET)

	var blink_up_coefficient: float = -eyelid_offset
	var blink_down_coefficient: float = BLINK_DOWN_MULTIPLIER * eyelid_offset

	var open_up_coefficient: float = eyelid_offset
	var open_down_coefficient: float = OPEN_DOWN_MULTIPLIER * eyelid_offset

	var brows_up_coefficient: float = BROW_UP_MULTIPLIER * eyelid_offset
	var brows_down_coefficient: float = 0.0

	var is_looking_up: bool = eye_pitch > 0

	if is_looking_up:
		for i in range(0, 2):
			transient_blendshape_coefficents[int(Blendshapes.EyeBlink_L) + i] = blink_up_coefficient
			transient_blendshape_coefficents[int(Blendshapes.EyeOpen_L) + i] = open_up_coefficient
			transient_blendshape_coefficents[int(Blendshapes.BrowsU_L) + i] = brows_up_coefficient
	else:
		for i in range(0, 2):
			transient_blendshape_coefficents[int(Blendshapes.EyeBlink_L) + i] = blink_down_coefficient
			transient_blendshape_coefficents[int(Blendshapes.EyeOpen_L) + i] = open_down_coefficient
			transient_blendshape_coefficents[int(Blendshapes.BrowsU_L) + i] = brows_down_coefficient


func update(p_delta: float) -> void:
	var audio_loudness: float = 0.0

	average_loudness = lerpf(average_loudness, audio_loudness, min(p_delta / AUDIO_AVERAGING_SECS, 1.0))
	if long_term_average_loudness == -1.0:
		long_term_average_loudness = average_loudness
	else:
		long_term_average_loudness = lerpf(long_term_average_loudness, average_loudness, min(p_delta / AUDIO_LONG_TERM_AVERAGING_SECS, 1.0))

	# Procedural Eye Joint Animation
	if 1:
		if randf() < p_delta / AVERAGE_MICROSACCADE_INTERVAL:
			saccade_target = MICROSACCADE_MAGNITUDE * rand_vector3()
		elif randf() < p_delta / AVERAGE_SACCADE_INTERVAL:
			saccade_target = SACCADE_MAGNITUDE * rand_vector3()

		saccade += (saccade_target - saccade) * pow(0.5, NOMINAL_FRAME_RATE * p_delta)

	time_without_talking += p_delta
	if (average_loudness - long_term_average_loudness) > TALKING_LOUDNESS:
		time_without_talking = 0.0

	# Procedural Blink Animation
	if 1:
		var force_blink: bool = false
		if time_without_talking - p_delta < BLINK_AFTER_TALKING and time_without_talking >= BLINK_AFTER_TALKING:
			force_blink = true

		if left_eye_blink_velocity == 0.0 and right_eye_blink_velocity == 0.0:
			if force_blink_to_retarget or force_blink or (brow_audio_lift < EPSILON and should_do(max(1.0, sqrt(abs(average_loudness - long_term_average_loudness)) * ROOT_LOUDNESS_TO_BLINK_INTERVAL) / BASE_BLINK_RATE, p_delta)):
				var rand_speed_variability: float = randf()
				var eye_blink_velocity: float = BLINK_SPEED + rand_speed_variability * BLINK_SPEED_VARIABILITY
				if force_blink_to_retarget:
					eye_blink_velocity = 0.5 * eye_blink_velocity
					force_blink_to_retarget = false
				left_eye_blink_velocity = eye_blink_velocity
				right_eye_blink_velocity = eye_blink_velocity
				if randf() < 0.5:
					left_eye_blink = BLINK_START_VARIABILITY
					right_eye_blink = BLINK_START_VARIABILITY
		else:
			left_eye_blink = clamp(left_eye_blink + left_eye_blink_velocity * p_delta, FULLY_OPEN, FULLY_CLOSED)
			right_eye_blink = clamp(right_eye_blink + right_eye_blink_velocity * p_delta, FULLY_OPEN, FULLY_CLOSED)

			if left_eye_blink == FULLY_CLOSED:
				left_eye_blink_velocity = -BLINK_SPEED
				update_eye_look_at()  # ???
			elif left_eye_blink == FULLY_OPEN:
				left_eye_blink_velocity = 0.0

			if right_eye_blink == FULLY_CLOSED:
				right_eye_blink_velocity = -BLINK_SPEED
			elif right_eye_blink == FULLY_OPEN:
				right_eye_blink_velocity = 0.0
	else:
		right_eye_blink = FULLY_OPEN
		left_eye_blink = FULLY_OPEN
		update_eye_look_at()

	# Audio Procedural Blendshape Animation
	if 1:
		# Update audio attack data for facial animation (eyebrows and mouth)
		var audio_attack_averaging_rate: float = (10.0 - p_delta * NORMAL_HZ) / 10.0  # --> 0.9 at 60 Hz
		audio_attack = (audio_attack_averaging_rate * audio_attack + ((1.0 - audio_attack_averaging_rate) * abs((audio_loudness - long_term_average_loudness) - last_loudness)))
		last_loudness = (audio_loudness - long_term_average_loudness)
		if audio_attack > BROW_LIFT_THRESHOLD:
			brow_audio_lift += sqrt(audio_attack) * 0.01

		brow_audio_lift *= 0.7  # Should we do this? (line 173)
		brow_audio_lift = clamp(brow_audio_lift, 0.0, 1.0)
		calculate_mouth_shapes(p_delta)
	else:
		audio_jaw_open = 0.0
		brow_audio_lift = 0.0
		mouth2 = 0.0
		mouth3 = 0.0
		mouth4 = 0.0
		mouth_time = 0.0

	transient_blendshape_coefficents = update_fake_coefficients(left_eye_blink, right_eye_blink, brow_audio_lift, audio_jaw_open, mouth2, mouth3, mouth4, transient_blendshape_coefficents)

	# Lid adjustment procedural
	if 1:
		# This controls two things, the eye brow and the upper eye lid, it is driven by the vertical up/down angle of the
		# eyes relative to the head.  This is to try to help prevent sleepy eyes/crazy eyes.
		apply_eyelid_offset(get_orientation())


func update_eye_look_at() -> void:
	look_at_position = request_look_at_position
	is_eye_look_at_updated = true


func cache_nodes() -> void:
	# Node caching
#	_avatar_display = get_node_or_null(avatar_display_path)
	pass
