# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# controller_helpers.gd
# SPDX-License-Identifier: MIT

static func get_direction_to(p_start: Vector3, p_end: Vector3) -> Vector3:
	var dir = p_end - p_start
	dir = dir.normalized()
	return dir


static func convert_euler_to_normal(p_euler: Vector3) -> Vector3:
	return Vector3(cos(p_euler.x) * sin(p_euler.y), -sin(p_euler.x), cos(p_euler.y) * cos(p_euler.x))


static func convert_normal_to_euler(p_normal: Vector3) -> Vector2:
	return Vector2(asin(p_normal.y), atan2(p_normal.x, p_normal.z))


static func get_absolute_basis(p_basis: Basis) -> Basis:
	var m: Basis = p_basis.orthonormalized()
	var det: float = m.determinant()
	if det < 0:
		m = m.scaled(Vector3(-1, -1, -1))

	return m


static func get_spatial_relative_movement_velocity(p_spatial: Node3D, p_input_direction: Vector2) -> Vector3:
	var new_direction: Vector3 = Vector3()

	if p_spatial:
		# Get the camera rotation
		var m: Basis = p_spatial.transform.basis

		var camera_yaw: float = m.get_euler().y  # Radians
		var spatial_normal: Vector3 = convert_euler_to_normal(Vector3(0.0, camera_yaw, 0.0))

		new_direction += Vector3(-spatial_normal.x, 0.0, -spatial_normal.z) * p_input_direction.x
		new_direction += Vector3(spatial_normal.z, 0.0, -spatial_normal.x) * p_input_direction.y

	return new_direction
