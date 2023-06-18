# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# viewmodel_generator.gd
# SPDX-License-Identifier: MIT

extends Node

const bone_lib_const = preload("bone_lib.gd")


static func add_vertex(p_surface_tool: SurfaceTool, p_mesh_data_tool: MeshDataTool, p_vertex_id: int) -> SurfaceTool:
	p_surface_tool.add_vertex(p_mesh_data_tool.get_vertex(p_vertex_id))
	p_surface_tool.add_normal(p_mesh_data_tool.get_vertex_normal(p_vertex_id))
	p_surface_tool.add_tangent(p_mesh_data_tool.get_vertex_tangent(p_vertex_id))
	p_surface_tool.add_color(p_mesh_data_tool.get_vertex_color(p_vertex_id))
	p_surface_tool.add_uv(p_mesh_data_tool.get_vertex_uv(p_vertex_id))
	p_surface_tool.add_uv2(p_mesh_data_tool.get_vertex_uv2(p_vertex_id))
	p_surface_tool.add_bones(p_mesh_data_tool.get_vertex_bones(p_vertex_id))
	p_surface_tool.add_weights(p_mesh_data_tool.get_vertex_weights(p_vertex_id))

	return p_surface_tool


static func get_recursive_children_for_bone_id(p_skeleton: Skeleton3D, p_bone_id: int) -> PackedInt32Array:
	var valid_ids: Array = []

	return PackedInt32Array(valid_ids)


static func generate_mesh_for_bone_ids(p_mesh: Mesh, p_valid_bone_ids: PackedInt32Array) -> Mesh:
	var new_mesh: Mesh = Mesh.new()

	var mesh_surface_count: int = p_mesh.get_surface_count()
	var last_index: int = 0
	var vertex_table: Dictionary = {}
	for mesh_surface_idx in range(0, mesh_surface_count):
		var mesh_data_tool: MeshDataTool = MeshDataTool.new()
		mesh_data_tool.create_from_surface(p_mesh, mesh_surface_idx)

		var surface_tool: SurfaceTool = SurfaceTool.new()
		surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

		for face_idx in range(0, mesh_data_tool.get_face_count()):
			var vertex_ids: PackedInt32Array = [-1, -1, -1]
			var face_valid: bool = true
			for face_vertex_idx in range(0, 3):
				vertex_ids[face_vertex_idx] = (mesh_data_tool.get_face_vertex(face_idx, face_vertex_idx))

				if vertex_table.has(vertex_ids[face_vertex_idx]):
					continue
				else:
					var bone_ids: PackedInt32Array = mesh_data_tool.get_vertex_bones(vertex_ids[face_vertex_idx])
					var bone_weights: PackedFloat32Array = mesh_data_tool.get_vertex_weights(vertex_ids[face_vertex_idx])

					var vertex_valid: bool = false

					if bone_ids.size() != bone_weights.size():
						print("Bone IDs size does not match Bone Weights size")
						return new_mesh

					var found: bool = false
					for bone_idx in range(0, bone_ids.size()):
						for valid_bone_idx in range(0, p_valid_bone_ids.size()):
							if bone_ids[bone_idx] == p_valid_bone_ids[valid_bone_idx]:
								if bone_weights[bone_idx] > 0.0:
									vertex_valid = true
									break
						if found:
							break

					if !vertex_valid:
						face_valid = false

			if face_valid:
				for face_vertex_idx in range(0, 3):
					var index: int = -1
					var vertex_id: int = vertex_ids[face_vertex_idx]
					if vertex_table.has(vertex_id):
						index = vertex_table[vertex_id]
					else:
						surface_tool = add_vertex(surface_tool, mesh_data_tool, vertex_id)

						index = last_index
						vertex_table[vertex_id] = index
						last_index += 1

					surface_tool.add_index(index)
		surface_tool.commit(new_mesh)
	return new_mesh
