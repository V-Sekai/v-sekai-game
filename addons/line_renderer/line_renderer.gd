# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# line_renderer.gd
# SPDX-License-Identifier: MIT

@tool
extends Node3D


# Remove when Godot 4.x implements support for ImmediateGometry3D
class StubImmediateGeometry3D:
	extends MeshInstance3D

	var verts_array: PackedVector3Array = PackedVector3Array()
	var color_array: PackedColorArray = PackedColorArray()

	func clear():
		if not verts_array.is_empty():
			is_dirty = true
		verts_array = PackedVector3Array()
		color_array = PackedColorArray()

	var line_strip: int = 0
	var cur_color: Color = Color.WHITE
	var last_vert: Vector3 = Vector3.ZERO
	var is_dirty: bool = false

	func begin(mode):
		if mode == Mesh.PRIMITIVE_LINE_STRIP:
			line_strip = 1

	func end():
		is_dirty = true
		line_strip = 0

	func set_color(color: Color):
		cur_color = color

	func add_vertex(v: Vector3):
		if line_strip > 2:
			color_array.append(cur_color)
			verts_array.append(last_vert)
		color_array.append(cur_color)
		verts_array.append(v)
		last_vert = v
		if line_strip > 0:
			line_strip += 1

	func _commit_arraymesh():
		if is_dirty:
			if mesh == null:
				mesh = ArrayMesh.new()
			mesh.clear_surfaces()
			var arrays = []
			arrays.resize(Mesh.ARRAY_MAX)
			arrays[Mesh.ARRAY_COLOR] = color_array
			arrays[Mesh.ARRAY_VERTEX] = verts_array
			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays, [], {})
			is_dirty = false


var geometry: StubImmediateGeometry3D = null
@export var material: Material = null:
	set = set_material

@export var thickness: float = 0.01
@export var start: Vector3 = Vector3()
@export var end: Vector3 = Vector3()


#
func set_material(p_material: Material):
	material = p_material
	if geometry:
		var tmp: Variant = material
		geometry.material_override = tmp


func add_vertex(p_point: Vector3):
	if geometry:
		geometry.add_vertex(p_point)


func update(p_a: Vector3, p_b: Vector3):
	if geometry:
		geometry.clear()

		var camera = get_viewport().get_camera_3d()
		if camera:
			geometry.begin(Mesh.PRIMITIVE_TRIANGLES)

			var ab = p_b - p_a
			var transform_start: Vector3 = (camera.global_transform.origin - ((p_a + p_b) / 2)).cross(ab).normalized() * thickness
			var transform_end: Vector3 = (camera.global_transform.origin - ((p_a + p_b) / 2)).cross(ab).normalized() * thickness

			var a_upper: Vector3 = p_a + transform_start
			var b_upper: Vector3 = p_b + transform_end
			var a_lower: Vector3 = p_a - transform_start
			var b_lower: Vector3 = p_b - transform_end

			add_vertex(a_upper)
			add_vertex(b_upper)
			add_vertex(a_lower)
			add_vertex(b_upper)
			add_vertex(b_lower)
			add_vertex(a_lower)

			geometry.end()
		geometry._commit_arraymesh()


func _process(_delta: float) -> void:
	update(start, end)


func _ready() -> void:
	geometry = StubImmediateGeometry3D.new()
	geometry.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_DOUBLE_SIDED
	var tmp: Variant = material
	geometry.material_override = tmp
	geometry.set_as_top_level(true)

	add_child(geometry, true)
	geometry.global_transform = Transform3D()
