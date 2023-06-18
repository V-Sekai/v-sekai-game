# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# geometry_util.gd
# SPDX-License-Identifier: MIT

@tool


static func test_point_with_planes(p_point: Vector3, p_planes: Array) -> bool:
	for plane in p_planes:
		if plane.is_point_over(p_point):
			return false
	return true


static func test_aabb_with_planes(p_aabb: AABB, p_planes: Array) -> bool:
	for plane in p_planes:
		if plane.is_point_over(p_aabb.position) and plane.is_point_over(p_aabb.end):
			return false
	return true


static func get_cylinder_boundings_box(p_pos: Vector3, p_cylinder: CylinderShape3D) -> AABB:
	return AABB(p_pos, Vector3(p_cylinder.get_radius(), p_cylinder.get_height() * 0.5, p_cylinder.get_radius()))


static func get_sphere_boundings_box(p_pos: Vector3, p_sphere: SphereShape3D) -> AABB:
	return AABB(p_pos, Vector3(p_sphere.get_radius(), p_sphere.get_radius(), p_sphere.get_radius()))
