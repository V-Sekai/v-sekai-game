# res://addons/actor/senses.gd
# This file is part of the V-Sekai Game.
# https://github.com/V-Sekai/actor
#
# Copyright (c) 2018-2022 SaracenOne
# Copyright (c) 2019-2022 K. S. Ernest (iFire) Lee (fire)
# Copyright (c) 2020-2022 Lyuma
# Copyright (c) 2020-2022 MMMaellon
# Copyright (c) 2022 V-Sekai Contributors
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

extends "res://addons/entity_manager/component_node.gd"

const immediate_shapes_const = preload("res://addons/gd_util/immediate_shape_util.gd")
const camera_matrix_const = preload("res://addons/gd_util/camera_matrix_util.gd")
const geometry_util_const = preload("res://addons/gd_util/geometry_util.gd")

# Virtual camera info
var camera_matrix: Object = null
var camera_planes: Array = []


func get_actor_eye_transform() -> Transform3D:
	return Transform3D()
	#if camera_controller != null:
	#	return camera_controller.global_transform
	#else:
	#	return get_global_origin() + Transform(Basis(), extended_kinematic_body.up * eye_height)


func can_see_collider_point(p_point: Vector3, p_exclusion_array: Array = [], p_collision_bits: int = 1) -> bool:
	var dss: PhysicsDirectSpaceState3D = entity_node.PhysicsServer3D.space_get_direct_state(
		entity_node.get_world_3d().get_space()
	)
	if dss:
		camera_planes = camera_matrix.get_projection_planes(get_actor_eye_transform())

		if geometry_util_const.test_point_with_planes(p_point, camera_planes):
			var ray_exclusion_array = p_exclusion_array
			ray_exclusion_array.push_front(self)
			var param: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.new()
			param.from = get_actor_eye_transform().origin
			param.to = p_point
			param.exclude = ray_exclusion_array
			param.collision_mask = p_collision_bits
			var result = dss.intersect_ray(param)
			if result.is_empty():
				return true

	return false


func can_see_collider_aabb(p_aabb: AABB, p_exclusion_array: Array = [], p_collision_bits: int = 1) -> bool:
	var dss = entity_node.PhysicsServer3D.space_get_direct_state(entity_node.get_world_3d().get_space())
	if dss:
		camera_planes = camera_matrix.get_projection_planes(get_actor_eye_transform())

		if geometry_util_const.test_aabb_with_planes(p_aabb, camera_planes):
			var ray_exclusion_array = p_exclusion_array
			ray_exclusion_array.push_front(self)

			var param: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.new()
			param.from = get_actor_eye_transform().origin
			param.to = p_aabb.position + (p_aabb.size * 0.5)
			param.exclude = ray_exclusion_array
			param.collision_mask = p_collision_bits
			param.collide_with_bodies = true
			var result = dss.intersect_ray(param)
			if result.is_empty():
				return true

	return false


func setup_camera_matrix(
	p_fovy_degrees: float, p_aspect: float, p_z_near: float, p_z_far: float, p_flip_fov: float
) -> void:
	camera_matrix = camera_matrix_const.new()
	camera_matrix.set_perspective(p_fovy_degrees, p_aspect, p_z_near, p_z_far, p_flip_fov)
