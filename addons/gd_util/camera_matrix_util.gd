# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# camera_matrix_util.gd
# SPDX-License-Identifier: MIT

@tool


static func xform_plane(p_transform: Transform3D, p_plane: Plane) -> Plane:
	var point: Vector3 = p_plane.normal * p_plane.d
	var point_dir: Vector3 = point + p_plane.normal
	point = p_transform * point
	point_dir = p_transform * point_dir

	var normal: Vector3 = (point_dir - point).normalized()
	var d: float = normal.dot(point)

	return Plane(normal, d)


var matrix: PackedFloat64Array = PackedFloat64Array([0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0])


func set_identity() -> void:
	matrix = PackedFloat64Array([0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0])


static func get_fovy(p_fovx: float, p_aspect: float) -> float:
	return rad_to_deg(atan(p_aspect * tan(deg_to_rad(p_fovx) * 0.5)) * 2.0)


func get_endpoints() -> PackedVector3Array:
	# Near Plane
	var near_plane: Plane = Plane(matrix[3] + matrix[2], matrix[7] + matrix[6], matrix[11] + matrix[10], -matrix[15] - matrix[14]).normalized()

	# Far Plane
	var far_plane: Plane = Plane(matrix[2] - matrix[3], matrix[6] - matrix[7], matrix[10] - matrix[11], matrix[15] - matrix[14]).normalized()

	# Right Plane
	var right_plane: Plane = Plane(matrix[0] - matrix[3], matrix[4] - matrix[7], matrix[8] - matrix[11], -matrix[15] + matrix[12]).normalized()

	# Top Plane
	var top_plane: Plane = Plane(matrix[1] - matrix[3], matrix[5] - matrix[7], matrix[9] - matrix[11], -matrix[15] + matrix[13]).normalized()

	var near_endpoint: Vector3 = near_plane.intersect_3(right_plane, top_plane)
	var far_endpoint: Vector3 = far_plane.intersect_3(right_plane, top_plane)

	var points_8: PackedVector3Array = PackedVector3Array()

	points_8.push_back(Vector3(near_endpoint.x, near_endpoint.y, near_endpoint.z))
	points_8.push_back(Vector3(near_endpoint.x, -near_endpoint.y, near_endpoint.z))
	points_8.push_back(Vector3(-near_endpoint.x, near_endpoint.y, near_endpoint.z))
	points_8.push_back(Vector3(-near_endpoint.x, -near_endpoint.y, near_endpoint.z))
	points_8.push_back(Vector3(far_endpoint.x, far_endpoint.y, far_endpoint.z))
	points_8.push_back(Vector3(far_endpoint.x, -far_endpoint.y, far_endpoint.z))
	points_8.push_back(Vector3(-far_endpoint.x, far_endpoint.y, far_endpoint.z))
	points_8.push_back(Vector3(-far_endpoint.x, -far_endpoint.y, far_endpoint.z))

	return points_8


func get_projection_planes(p_transform: Transform3D) -> Array:
	var planes: Array = []
	var new_plane: Plane

	# Near Plane
	new_plane = Plane(matrix[3] + matrix[2], matrix[7] + matrix[6], matrix[11] + matrix[10], matrix[15] + matrix[14])

	new_plane.normal = -new_plane.normal
	new_plane = new_plane.normalized()

	planes.push_back(xform_plane(p_transform, new_plane))

	# Far Plane
	new_plane = Plane(matrix[3] - matrix[2], matrix[7] - matrix[6], matrix[11] - matrix[10], matrix[15] - matrix[14])

	new_plane.normal = -new_plane.normal
	new_plane = new_plane.normalized()

	planes.push_back(xform_plane(p_transform, new_plane))

	# Left Plane
	new_plane = Plane(matrix[3] + matrix[0], matrix[7] + matrix[4], matrix[11] + matrix[8], matrix[15] + matrix[12])

	new_plane.normal = -new_plane.normal
	new_plane = new_plane.normalized()

	planes.push_back(xform_plane(p_transform, new_plane))

	# Top Plane
	new_plane = Plane(matrix[3] - matrix[1], matrix[7] - matrix[5], matrix[11] - matrix[9], matrix[15] - matrix[13])

	new_plane.normal = -new_plane.normal
	new_plane = new_plane.normalized()

	planes.push_back(xform_plane(p_transform, new_plane))

	# Right Plane
	new_plane = Plane(matrix[3] - matrix[0], matrix[7] - matrix[4], matrix[11] - matrix[8], matrix[15] - matrix[12])

	new_plane.normal = -new_plane.normal
	new_plane = new_plane.normalized()

	planes.push_back(xform_plane(p_transform, new_plane))

	# Bottom Plane
	new_plane = Plane(matrix[3] + matrix[1], matrix[7] + matrix[5], matrix[11] + matrix[9], matrix[15] + matrix[13])

	new_plane.normal = -new_plane.normal
	new_plane = new_plane.normalized()

	planes.push_back(xform_plane(p_transform, new_plane))

	return planes


func set_perspective(p_fovy_degrees: float, p_aspect: float, p_z_near: float, p_z_far: float, p_flip_fov: float) -> void:
	if p_flip_fov:
		p_fovy_degrees = get_fovy(p_fovy_degrees, 1.0 / p_aspect)

	var sine: float
	var cotangent: float
	var delta_z: float
	var radians: float = p_fovy_degrees / 2.0 * PI / 180.0

	delta_z = p_z_far - p_z_near
	sine = sin(radians)

	if (delta_z == 0) || (sine == 0) || (p_aspect == 0):
		return

	cotangent = cos(radians) / sine

	set_identity()

	matrix[0] = cotangent / p_aspect
	matrix[5] = cotangent
	matrix[10] = -(p_z_far + p_z_near) / delta_z
	matrix[11] = -1
	matrix[14] = -2 * p_z_near * p_z_far / delta_z
	matrix[15] = 0


func set_orthogonal(p_left: float, p_right: float, p_bottom: float, p_top: float, p_znear: float, p_zfar: float) -> void:
	set_identity()

	matrix[0] = 2.0 / (p_right - p_left)
	matrix[12] = -((p_right + p_left) / (p_right - p_left))
	matrix[5] = 2.0 / (p_top - p_bottom)
	matrix[13] = -((p_top + p_bottom) / (p_top - p_bottom))
	matrix[10] = -2.0 / (p_zfar - p_znear)
	matrix[14] = -((p_zfar + p_znear) / (p_zfar - p_znear))
	matrix[15] = 1.0
