# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# split_splerger.gd
# SPDX-License-Identifier: MIT

extends RefCounted


class _SplitInfo:
	var grid_size: float = 0
	var grid_size_y: float = 0
	var aabb: AABB
	var x_splits: int = 0
	var y_splits: int = 1
	var z_splits: int = 0


static func _get_num_splits_x(si: _SplitInfo) -> int:
	var splits = int(floor(si.aabb.size.x / si.grid_size))
	if splits < 1:
		splits = 1
	return splits


static func _get_num_splits_y(si: _SplitInfo) -> int:
	if si.grid_size_y <= 0.00001:
		return 1

	var splits = int(floor(si.aabb.size.y / si.grid_size_y))
	if splits < 1:
		splits = 1
	return splits


static func _get_num_splits_z(si: _SplitInfo) -> int:
	var splits = int(floor(si.aabb.size.z / si.grid_size))
	if splits < 1:
		splits = 1
	return splits


# split a mesh according to the grid size
static func split(
	mesh_instance: MeshInstance3D,
	surface_id: int,
	attachment_node: Node,
	grid_size: float,
	grid_size_y: float,
):
	# save all the info we can into a class to avoid passing it around
	var si: _SplitInfo = _SplitInfo.new()
	si.grid_size = grid_size
	si.grid_size_y = grid_size_y

	# calculate the AABB
	si.aabb = _calc_aabb(mesh_instance)
	si.x_splits = _get_num_splits_x(si)
	si.y_splits = _get_num_splits_y(si)
	si.z_splits = _get_num_splits_z(si)

	print(mesh_instance.get_name() + " : x_splits " + str(si.x_splits) + " y_splits " + str(si.y_splits) + " z_splits " + str(si.z_splits))

	## no need to split .. should never happen
	if (si.x_splits + si.y_splits + si.z_splits) == 3:
		print("WARNING - not enough splits, moving without splitting")
		var x_offset = (si.x_splits - 1) * grid_size
		var y_offset = (si.y_splits - 1) * grid_size_y
		var z_offset = (si.z_splits - 1) * grid_size
		mesh_instance.transform.origin += Vector3(x_offset, y_offset, z_offset)
		return false

	var mesh = mesh_instance.mesh

	var mdt = MeshDataTool.new()

	var surface_tool: SurfaceTool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for surface_i in range(mesh.get_surface_count()):
		surface_tool.append_from(mesh, surface_i, Transform3D())
	surface_tool.generate_normals()
	if mdt.get_vertex_count() and mdt.get_vertex_uv(0) != Vector2():
		surface_tool.generate_tangents()
	mdt.create_from_surface(surface_tool.commit(), surface_id)

	var nVerts = mdt.get_vertex_count()
	if nVerts == 0:
		return true

	# new .. create pre transformed to world space verts, no need to transform for each split
	var world_verts = PackedVector3Array([Vector3(0, 0, 0)])
	world_verts.resize(nVerts)
	var xform = mesh_instance.global_transform
	for n in range(nVerts):
		world_verts.set(n, xform * mdt.get_vertex(n))

	print("\tnVerts " + str(nVerts))

	# only allow faces to be assigned to one of the splits
	# i.e. prevent duplicates in more than 1 split
	var nFaces = mdt.get_face_count()
	var faces_assigned = []
	faces_assigned.resize(nFaces)

	# each split
	for z in range(si.z_splits):
		for y in range(si.y_splits):
			for x in range(si.x_splits):
				_split_mesh(mdt, mesh_instance, surface_id, x, y, z, si, attachment_node, faces_assigned, world_verts)

	return true


static func _split_mesh(mdt: MeshDataTool, orig_mi: MeshInstance3D, surface_id: int, grid_x: int, grid_y: int, grid_z: int, si: _SplitInfo, attachment_node: Node, faces_assigned, world_verts: PackedVector3Array):
	print("\tsplit " + str(grid_x) + ", " + str(grid_y) + ", " + str(grid_z))

	# find the subregion of the aabb
	var xgap = si.aabb.size.x / si.x_splits
	var ygap = si.aabb.size.y / si.y_splits
	var zgap = si.aabb.size.z / si.z_splits
	var pos = si.aabb.position
	pos.x += grid_x * xgap
	pos.y += grid_y * ygap
	pos.z += grid_z * zgap
	var aabb = AABB(pos, Vector3(xgap, ygap, zgap))

	# godot intersection doesn't work on borders ...
	aabb = aabb.grow(0.1)

	print("\tAABB : " + str(aabb))

	var nVerts = mdt.get_vertex_count()
	var nFaces = mdt.get_face_count()

	# find all faces that overlap the new aabb and add them to a new mesh
	var faces = []

	var face_aabb: AABB

	for f in range(nFaces):
		for i in range(3):
			var ind = mdt.get_face_vertex(f, i)
			var vert = world_verts[ind]

			if i == 0:
				face_aabb = AABB(vert, Vector3(0, 0, 0))
			else:
				face_aabb = face_aabb.expand(vert)

		# does this face overlap the aabb?
		if aabb.intersects(face_aabb):
			# only allow one split to contain a face
			if faces_assigned[f] != true:
				faces.push_back(f)
				faces_assigned[f] = true

	if faces.size() == 0:
		return

	var new_inds = []
	var unique_verts = []

	var ind_mapping = []
	ind_mapping.resize(mdt.get_vertex_count())
	for i in range(mdt.get_vertex_count()):
		ind_mapping[i] = -1

	var xform = orig_mi.global_transform

	for n in range(faces.size()):
		var f = faces[n]
		for i in range(3):
			var ind = mdt.get_face_vertex(f, i)

			var new_ind = _find_or_add_unique_vert(ind, unique_verts, ind_mapping)
			new_inds.push_back(new_ind)

	var tmpMesh = ArrayMesh.new()

	var mat = orig_mi.mesh.surface_get_material(surface_id)

	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_material(mat)

	var is_normal: bool = false
	var is_tangent: bool = false
	var is_color: bool = false
	var is_uv: bool = false
	var is_bones: bool = false
	var is_bone_weights: bool = false

	if unique_verts.size():
		var n = unique_verts[0]
		is_normal = mdt.get_vertex_normal(n) != Vector3()
		is_tangent = mdt.get_vertex_tangent(n) != Plane()
		is_color = mdt.get_vertex_color(n) != Color()
		is_uv = mdt.get_vertex_uv(n) != Vector2()
		is_bones = mdt.get_vertex_bones(n).size()
		is_bone_weights = mdt.get_vertex_weights(n).size()

	for u in unique_verts.size():
		var n = unique_verts[u]
		var vert = mdt.get_vertex(n)
		if is_normal:
			var norm = mdt.get_vertex_normal(n)
			st.set_normal(norm)
		if is_tangent:
			var tangent = mdt.get_vertex_tangent(n)
			st.set_tangent(tangent)
		if is_color:
			var col = mdt.get_vertex_color(n)
			st.set_color(col)
		if is_uv:
			var uv = mdt.get_vertex_uv(n)
			st.set_uv(uv)
		if is_bones:
			var bones = mdt.get_vertex_bones(n)
			st.set_bones(bones)
			var bone_weights = mdt.get_vertex_weights(n)
			st.set_weights(bone_weights)
		st.add_vertex(vert - Vector3(grid_x * xgap, grid_y * ygap, grid_z * zgap))

	for i in new_inds.size():
		st.add_index(new_inds[i])

	st.commit(tmpMesh)

	var new_mi: MeshInstance3D = MeshInstance3D.new()
	new_mi.mesh = tmpMesh

	if new_mi.mesh.get_surface_count():
		new_mi.set_surface_override_material(0, mat)

	new_mi.set_name(orig_mi.get_name() + "_" + str(grid_x) + str(grid_z))

	new_mi.skeleton = orig_mi.skeleton
	new_mi.skin = orig_mi.skin

	new_mi.transform = orig_mi.transform.translated(Vector3(grid_x * xgap, grid_y * ygap, grid_z * zgap))

	# add the new mesh as a child
	attachment_node.add_child(new_mi, true)
	new_mi.owner = attachment_node.owner

	if orig_mi.mesh and orig_mi.mesh.get_surface_count() - 1 == surface_id:
		orig_mi.queue_free()


static func _find_or_add_unique_vert(orig_index: int, unique_verts, ind_mapping):
	# already exists in unique verts
	if ind_mapping[orig_index] != -1:
		return ind_mapping[orig_index]

	# else add to list of unique verts
	var new_index = unique_verts.size()
	unique_verts.push_back(orig_index)

	# record this for next time
	ind_mapping[orig_index] = new_index

	return new_index


static func _check_aabb(aabb: AABB):
	assert(aabb.size.x >= 0)
	assert(aabb.size.y >= 0)
	assert(aabb.size.z >= 0)


static func _calc_aabb(mesh_instance: MeshInstance3D):
	if not mesh_instance.mesh:
		return AABB()
	var aabb: AABB = mesh_instance.global_transform * mesh_instance.mesh.get_aabb()
	# godot intersection doesn't work on borders ...
	aabb = aabb.grow(0.1)
	_check_aabb(aabb)
	return aabb


static func _set_owner_recursive(node, owner):
	if node != owner:
		node.set_owner(owner)

	for i in range(node.get_child_count()):
		_set_owner_recursive(node.get_child(i), owner)


static func save_scene(node, filename):
	var owner = node.get_owner()
	_set_owner_recursive(node, node)

	var packed_scene = PackedScene.new()
	packed_scene.pack(node)
	ResourceSaver.save(packed_scene, filename)


static func traverse_root_and_split(root: Node3D, grid_size: float = 0.9, grid_size_y: float = 0.9) -> void:
	var instances: Array[Node] = root.find_children("*", "MeshInstance3D")
	for node in instances:
		var mesh_instance: MeshInstance3D = node
		for surface_i in mesh_instance.mesh.get_surface_count():
			split(mesh_instance, surface_i, mesh_instance.get_parent(), grid_size, grid_size_y)
