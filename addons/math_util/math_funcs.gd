# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# math_funcs.gd
# SPDX-License-Identifier: MIT

@tool
extends Node


static func smooth_damp_scaler(current : float, target : float, current_velocity : float, smooth_time : float, max_speed : float, delta : float) -> Dictionary:
	smooth_time = max(0.0001, smooth_time)
	var value_a : float = 2.0 / smooth_time
	var value_b : float = value_a * delta
	var value_c : float = 1.0 / (1.0 + value_b + 0.48 * value_b * value_b + 0.235 * value_b * value_b * value_b)
	
	var scaler_a : float = current - target;
	var scaler_b : float = target;
	var max_length : float = max_speed * smooth_time
	
	scaler_a = clamp(scaler_a, -max_length, max_length);
	
	target = current - scaler_a;
	var scaler_c : float = (current_velocity + value_a * scaler_a) * delta;
	current_velocity = (current_velocity - value_a * scaler_c) * value_c;
	var scaler_d : float = target + (scaler_a + scaler_c) * value_c;
	if ((scaler_b - current) > 0.0 == (scaler_d > scaler_b)):
		scaler_d = scaler_b
		current_velocity = (scaler_d - scaler_b) / delta;
	
	return {"interpolation":scaler_d, "velocity":current_velocity}


static func rotate_around(p_transform : Transform3D, p_point : Vector3, p_axis : Vector3, p_angle : float) -> Transform3D:
	var vector : Vector3 = p_point + (Quaternion(p_axis, p_angle) * (p_transform.origin - p_point))
	p_transform.origin = vector
	
	return p_transform.rotated(p_axis, p_angle * 0.0174532924)


static func base_log(a : float, new_base : float) -> float:
	return log(a) / log(new_base)


static func transform_directon_vector(p_direction : Vector3, p_basis : Basis) -> Vector3:
	return Vector3(((p_basis.x.x * p_direction.x) + (p_basis.y.x * p_direction.y) + (p_basis.z.x * p_direction.z)), ((p_basis.x.y * p_direction.x) + (p_basis.y.y * p_direction.y) + (p_basis.z.y * p_direction.z)),((p_basis.x.z * p_direction.x) + (p_basis.y.z * p_direction.y) + (p_basis.z.z * p_direction.z)))


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


static func vec2rad_to_deg(p_vector2 : Vector2) -> Vector2:
	return Vector2(rad_to_deg(p_vector2.x), rad_to_deg(p_vector2.y))


static func vec2deg2rad(p_vector2 : Vector2) -> Vector2:
	return Vector2(deg_to_rad(p_vector2.x), deg_to_rad(p_vector2.y))


static func vec3rad_to_deg(p_vector3 : Vector3) -> Vector3:
	return Vector3(rad_to_deg(p_vector3.x), rad_to_deg(p_vector3.y), rad_to_deg(p_vector3.z))


static func vec3deg2rad(p_vector3 : Vector3) -> Vector3:
	return Vector3(deg_to_rad(p_vector3.x), deg_to_rad(p_vector3.y), deg_to_rad(p_vector3.z))


static func sanitise_float(p_float : float) -> float:
	var return_float : float = p_float
	if is_nan(return_float) or is_inf(return_float):
		return_float = 0.0
		
	return return_float


static func sanitise_vec2(p_vec2 : Vector2) -> Vector2:
	var return_vec2 : Vector2 = p_vec2
	if is_nan(return_vec2.x) or is_inf(return_vec2.x):
		return_vec2.x = 0.0
	if is_nan(return_vec2.y) or is_inf(return_vec2.y):
		return_vec2.y = 0.0
		
	return return_vec2

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


static func shortest_angle_distance(p_from: float, p_to: float) -> float:
	var difference: float = fmod(p_to - p_from, PI * 2.0)
	return fmod(2.0 * difference, PI * 2.0) - difference
