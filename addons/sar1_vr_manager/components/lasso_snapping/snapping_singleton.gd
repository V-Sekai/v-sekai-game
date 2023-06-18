# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# snapping_singleton.gd
# SPDX-License-Identifier: MIT

extends Node

var snapping_points: RefCounted = null


func _init():
	if type_exists("LassoDB"):
		snapping_points = ClassDB.instantiate("LassoDB")


static func calc_snapping_power_sphere(point: Vector3, size_radius: float, power: float, source: Transform3D) -> float:
	var point_local: Vector3 = point * source
	var rejection = Vector3(point_local.x, point_local.y, 0)  #assuming -z is forward
	var euclidian_dist: float = point_local.length()
	var angular_dist: float = point_local.angle_to(Vector3(0, 0, -1))
	# Pretend there's a spherical collider and check if the laser hits it. If it does then we ignore angular dist and pretend we hit our target dead on.
	if rejection.length() <= size_radius:
		return power / (1.0 + euclidian_dist) / (0.01 + angular_dist)
	return power / (1.0 + euclidian_dist) / (0.1 + angular_dist)


static func calc_redirection_basis(source: Vector3, center: Vector3):
	var center_vector = source - center
	var up: Vector3 = XRServer.get_hmd_transform().basis.y.normalized()
	var z_vector: Vector3 = center_vector.normalized()
	var x_vector: Vector3 = z_vector.cross(up).normalized()
	var y_vector: Vector3 = x_vector.cross(z_vector).normalized()
	var new_basis: Basis = Basis(x_vector, y_vector, z_vector).transposed()
	return new_basis


static func calc_redirection_dist(point: Vector3, source: Vector3, center: Vector3, redirect_basis: Basis, redirect_direction: Vector2) -> float:
	var point_vector = source - point
	var center_vector = source - center
	if point_vector.angle_to(center_vector) > PI / 4:  # Return if angle is more than 45 degrees away, we don't snap.
		return INF
	var point_xyz: Vector3 = redirect_basis * point_vector
	var point_2d: Vector2 = Vector2(point_xyz.x, -point_xyz.y)
	if abs(redirect_direction.angle_to(point_2d)) >= PI / 2:
		return INF
	elif redirect_direction.x == 0:
		return (-point_2d.x / point_2d.y + 1) * (point_2d.x / 2)
	elif point_2d.y == 0:
		return Vector2(point_2d.x / 2, point_2d.x / 2 * (redirect_direction.y / redirect_direction.x)).length_squared()
	var a1: float = -point_2d.x / point_2d.y
	var c1: float = (1 - a1) * point_2d.x / 2
	var a2: float = redirect_direction.y / redirect_direction.x
	var x_component: float = c1 / (a2 - a1)
	var y_component: float = (a2 * c1) / (a2 - a1)
	return Vector2(x_component, y_component).length_squared()  # This is length squared because it's slightly more performant and we don't care about the actual value


static func vector_projection(v: Vector3, normal: Vector3) -> Vector3:
	if v.length_squared() == 0 || normal.length_squared() == 0:
		return Vector3()
	var normal_length: float = normal.length()
	var proj: Vector3 = (normal.dot(v) / normal_length) * (normal / normal_length)
	return proj


static func vector_rejection(v: Vector3, normal: Vector3) -> Vector3:
	return v - vector_projection(v, normal)
