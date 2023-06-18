# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# camera_gizmo.gd
# SPDX-License-Identifier: MIT

extends EditorNode3DGizmo

const immediate_shape_util_const = preload("immediate_shape_util.gd")

var plugin: EditorNode3DGizmoPlugin = null
var camera: Node = null
var material: StandardMaterial3D = null


static func _find_closest_angle_to_half_pi_arc(p_from: Vector3, p_to: Vector3, p_arc_radius: float, p_arc_xform: Transform3D) -> float:
	var arc_test_points: int = 64
	var min_d: int = 1e20
	var min_p: Vector3

	for i in range(0, arc_test_points):
		var a: float = i * PI * 0.5 / arc_test_points
		var an: float = (i + 1) * PI * 0.5 / arc_test_points
		var p: Vector3 = Vector3(cos(a), 0, -sin(a)) * p_arc_radius
		var n: Vector3 = Vector3(cos(an), 0, -sin(an)) * p_arc_radius

		var r: PackedVector3Array = Geometry3D.get_closest_points_between_segments(p, n, p_from, p_to)
		var ra: Vector3 = r[0]
		var rb: Vector3 = r[1]

		var d: float = ra.distance_to(rb)
		if d < min_d:
			min_d = d
			min_p = ra

	var a: float = Vector2(min_p.x, -min_p.z).angle()
	return a * 180.0 / PI


func get_handle_name(p_idx: int) -> String:
	return "FOV"


func get_handle_value(p_idx: int) -> int:
	return camera.get_fov()


func set_handle(p_idx: int, p_camera: Camera3D, p_point: Vector2) -> void:
	var gt: Transform3D = camera.get_global_transform()
	gt = gt.orthonormalized()
	var gi: Transform3D = gt.affine_inverse()

	var ray_from: Vector3 = p_camera.project_ray_origin(p_point)
	var ray_dir: Vector3 = p_camera.project_ray_normal(p_point)

	var s: Array = [gi * ray_from, gi * (ray_from + ray_dir * 4096)]

	gt = camera.get_global_transform()
	var a: float = _find_closest_angle_to_half_pi_arc(s[0], s[1], 1.0, gt)
	camera.set("fov", a)
	camera.property_list_changed_notify()


func commit_handle(p_idx: int, p_restore: bool, p_cancel: bool = false) -> void:
	if p_cancel:
		camera.set("fov", p_restore)
	else:
		var ur = plugin.get_undo_redo()
		ur.create_action("Change Camera3D FOV")
		ur.add_do_property(camera, "fov", camera.get_fov())
		ur.add_undo_property(camera, "fov", p_restore)
		ur.commit_action()
	camera.property_list_changed_notify()


func add_triangle(p_lines: PackedVector3Array, m_a: Vector3, m_b: Vector3, m_c: Vector3) -> PackedVector3Array:
	p_lines.push_back(m_a)
	p_lines.push_back(m_b)
	p_lines.push_back(m_b)
	p_lines.push_back(m_c)
	p_lines.push_back(m_c)
	p_lines.push_back(m_a)

	return p_lines


func redraw() -> void:
	clear()
	var lines: Array = []
	var handles: Array = []

	var fov: float = camera.get_fov()

	var side: Vector3 = Vector3(sin(deg_to_rad(fov)), 0, -cos(deg_to_rad(fov)))
	var nside: Vector3 = side
	nside.x = -nside.x
	var up: Vector3 = Vector3(0, side.x, 0)

	lines = add_triangle(lines, Vector3(), side + up, side - up)
	lines = add_triangle(lines, Vector3(), nside + up, nside - up)
	lines = add_triangle(lines, Vector3(), side + up, nside + up)
	lines = add_triangle(lines, Vector3(), side - up, nside - up)

	handles.push_back(side)
	side.x *= 0.25
	nside.x *= 0.25
	var tup: Vector3 = Vector3(0, up.y * 3 / 2, side.z)
	lines = add_triangle(lines, tup, side + up, nside + up)

	add_lines(lines, material)
	add_collision_segments(lines)
	add_handles(handles, material, PackedInt32Array())  # empty array = auto-assign ids


func _init(p_camera: Node, p_plugin: EditorNode3DGizmoPlugin, p_color: Color):
	camera = p_camera
	plugin = p_plugin
	set_node_3d(camera)
	material = immediate_shape_util_const.create_debug_material(p_color)
