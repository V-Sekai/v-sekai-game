# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# math_funcs.gd
# SPDX-License-Identifier: MIT

@tool
extends Node

static func get_interpolated_transform(p_current_transform : Transform3D, p_target_transform : Transform3D, p_origin_interpolation_factor : float, p_rotation_interpolation_factor : float, p_delta : float):
	var current_origin : Vector3 = p_current_transform.origin
	var current_rotation : Basis = p_current_transform.basis
	
	var target_origin : Vector3 = p_target_transform.origin
	var target_rotation : Basis = p_target_transform.basis
	
	if p_origin_interpolation_factor > 0.0:
		current_origin = current_origin.cubic_interpolate_in_time(target_origin, current_origin, target_origin, p_origin_interpolation_factor * p_delta,
			p_delta, 0.0, p_delta)
	else:
		current_origin = target_origin
		
	if p_rotation_interpolation_factor > 0.0:
		current_rotation = current_rotation.get_rotation_quaternion().spherical_cubic_interpolate_in_time(
			target_rotation.get_rotation_quaternion(), current_rotation.get_rotation_quaternion(), target_rotation.get_rotation_quaternion(),
			p_rotation_interpolation_factor * p_delta, p_delta, 0, p_delta)
	else:
		current_rotation = target_rotation
	
	return Transform3D(current_rotation, current_origin)


static func sanitise_float(p_float : float) -> float:
	var return_float : float = p_float
	if is_nan(return_float) or is_inf(return_float):
		return_float = 0.0
		
	return return_float


static func sanitise_vec3(p_vec3 : Vector3) -> Vector3:
	var return_vec3 : Vector3 = p_vec3
	if is_nan(return_vec3.x) or is_inf(return_vec3.x):
		return_vec3.x = 0.0
	if is_nan(return_vec3.y) or is_inf(return_vec3.y):
		return_vec3.y = 0.0
	if is_nan(return_vec3.z) or is_inf(return_vec3.z):
		return_vec3.z = 0.0
		
	return return_vec3


static func sanitise_quat(p_quat : Quaternion) -> Quaternion:
	var return_quat : Quaternion = p_quat.normalized()
	if is_nan(return_quat.x) or is_inf(return_quat.x):
		return_quat.x = 0.0
	if is_nan(return_quat.y) or is_inf(return_quat.y):
		return_quat.y = 0.0
	if is_nan(return_quat.z) or is_inf(return_quat.z):
		return_quat.z = 0.0
	if is_nan(return_quat.w) or is_inf(return_quat.w):
		return_quat.w = 1.0
		
	return return_quat
