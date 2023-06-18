# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# bounds_gizmo.gd
# SPDX-License-Identifier: MIT

extends EditorNode3DGizmo

const immediate_shape_util_const = preload("immediate_shape_util.gd")

var plugin: EditorNode3DGizmoPlugin = null
var spatial: Node = null
var color: Color = Color()


func get_handle_name(p_idx: int) -> String:
	if p_idx == 0:
		return "X"
	elif p_idx == 1:
		return "Y"
	elif p_idx == 2:
		return "Z"

	return ""


func get_handle_value(p_idx: int) -> Vector3:
	return spatial.get_bounds().size * 2


func set_handle(p_idx: int, p_camera: Camera3D, p_point: Vector2) -> void:
	var gt: Transform3D = spatial.get_global_transform()
	gt = gt.orthonormalized()
	var gi: Transform3D = gt.affine_inverse()

	var aabb: AABB = spatial.get_bounds()
	var ray_from: Vector3 = p_camera.project_ray_origin(p_point)
	var ray_dir: Vector3 = p_camera.project_ray_normal(p_point)

	var sg = [gi * ray_from, gi * (ray_from + ray_dir * 4096)]
	var ofs = aabb.position + aabb.size * 0.5

	var axis: Vector3 = Vector3()
	axis[p_idx] = 1.0

	var result: PackedVector3Array = Geometry3D.get_closest_points_between_segments(ofs, ofs + axis * 4096, sg[0], sg[1])
	var ra: Vector3 = result[0]
	var rb: Vector3 = result[1]

	var d: float = ra[p_idx]
	if d < 0.001:
		d = 0.001

	aabb.position[p_idx] = (aabb.position[p_idx] + aabb.size[p_idx] * 0.5) - d
	aabb.size[p_idx] = d * 2
	spatial.set_bounds(aabb)


func commit_handle(p_idx: int, p_restore: bool, p_cancel: bool = false) -> void:
	if p_cancel:
		spatial.set_bounds(p_restore)  # !
		return

	var ur: EditorUndoRedoManager = plugin.get_undo_redo()
	ur.create_action(tr("Change Box Shape3D Bounds"))
	ur.add_do_method(spatial, "set_bounds", spatial.get_bounds())
	ur.add_undo_method(spatial, "set_bounds", p_restore)  # !
	ur.commit_action()


static func get_lines(p_bounds: AABB) -> PackedVector3Array:
	var lines = PackedVector3Array()

	var aabb_min: Vector3 = p_bounds.position
	var aabb_max: Vector3 = p_bounds.end

	lines.append(Vector3(aabb_min.x, aabb_min.y, aabb_min.z))
	lines.append(Vector3(aabb_min.x, aabb_max.y, aabb_min.z))

	lines.append(Vector3(aabb_min.x, aabb_min.y, aabb_min.z))
	lines.append(Vector3(aabb_max.x, aabb_min.y, aabb_min.z))

	lines.append(Vector3(aabb_min.x, aabb_max.y, aabb_min.z))
	lines.append(Vector3(aabb_max.x, aabb_max.y, aabb_min.z))

	lines.append(Vector3(aabb_max.x, aabb_min.y, aabb_min.z))
	lines.append(Vector3(aabb_max.x, aabb_max.y, aabb_min.z))

	lines.append(Vector3(aabb_max.x, aabb_min.y, aabb_min.z))
	lines.append(Vector3(aabb_max.x, aabb_min.y, aabb_max.z))

	lines.append(Vector3(aabb_max.x, aabb_max.y, aabb_min.z))
	lines.append(Vector3(aabb_max.x, aabb_max.y, aabb_max.z))

	lines.append(Vector3(aabb_max.x, aabb_min.y, aabb_max.z))
	lines.append(Vector3(aabb_max.x, aabb_max.y, aabb_max.z))

	lines.append(Vector3(aabb_max.x, aabb_min.y, aabb_max.z))
	lines.append(Vector3(aabb_min.x, aabb_min.y, aabb_max.z))

	lines.append(Vector3(aabb_max.x, aabb_max.y, aabb_max.z))
	lines.append(Vector3(aabb_min.x, aabb_max.y, aabb_max.z))

	lines.append(Vector3(aabb_min.x, aabb_min.y, aabb_max.z))
	lines.append(Vector3(aabb_min.x, aabb_max.y, aabb_max.z))

	lines.append(Vector3(aabb_min.x, aabb_min.y, aabb_max.z))
	lines.append(Vector3(aabb_min.x, aabb_min.y, aabb_min.z))

	lines.append(Vector3(aabb_min.x, aabb_max.y, aabb_max.z))
	lines.append(Vector3(aabb_min.x, aabb_max.y, aabb_min.z))

	return lines


func redraw() -> void:
	clear()

	var material: StandardMaterial3D = immediate_shape_util_const.create_debug_material(color)

	var bounds: AABB = spatial.get_bounds()
	var lines = get_lines(bounds)

	var handles: PackedVector3Array = PackedVector3Array()

	for i in range(0, 3):
		var ax: Vector3 = Vector3()
		ax[i] = bounds.position[i] + bounds.size[i]
		handles.push_back(ax)

	add_lines(lines, material)
	add_collision_segments(lines)
	add_handles(handles, material, PackedInt32Array())  # empty array = auto-assign ids


func _init(p_spatial: Node, p_plugin: EditorNode3DGizmoPlugin, p_color: Color):
	spatial = p_spatial
	plugin = p_plugin
	color = p_color

	set_node_3d(spatial)
