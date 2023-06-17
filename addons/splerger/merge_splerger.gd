extends RefCounted


static func merge_suitable_meshes_across_branches(root: Node3D):
	var master_list: Array[MeshInstance3D] = []
	_list_mesh_instances(root, master_list)

	var mat_list = []
	var sub_list = []

	# identify materials
	for n in range(master_list.size()):
		var mat
		var mesh_instance: MeshInstance3D = master_list[n]
		if mesh_instance.mesh.get_surface_count() > 0:
			mat = mesh_instance.get_active_material(0)

		# is the material in the mat list already?
		var mat_id = -1

		for m in range(mat_list.size()):
			if mat_list[m] == mat:
				mat_id = m
				break

		# first instance of material
		if mat_id == -1:
			mat_id = mat_list.size()
			mat_list.push_back(mat)
			sub_list.push_back([])

		# mat id is the sub list to add to
		var sl = sub_list[mat_id]
		sl.push_back(master_list[n])
		print("adding " + master_list[n].get_name() + " to material sublist " + str(mat_id))

	# at this point the sub lists are complete, and we can start merging them
	for n in range(sub_list.size()):
		var sl: Array[MeshInstance3D] = sub_list[n]

		if sl.size() > 1:
			var new_mi: MeshInstance3D = merge_meshinstances(sl, root)

			# compensate for local transform on the parent node
			# (as the new verts will be in global space)
			var tr: Transform3D = root.global_transform
			tr = tr.inverse()
			new_mi.transform = tr


static func _list_mesh_instances(node: Node, list: Array[MeshInstance3D]):
	if node is MeshInstance3D:
		if node.get_child_count() == 0:
			var mi: MeshInstance3D = node
			if mi.mesh.get_surface_count() <= 1:
				list.push_back(node)

	for c in range(node.get_child_count()):
		_list_mesh_instances(node.get_child(c), list)


static func merge_meshinstances(
	mesh_array: Array[MeshInstance3D],
	attachment_node: Node,
	use_local_space: bool = false,
	delete_originals: bool = true
) -> MeshInstance3D:
	if mesh_array.size() < 2:
		printerr("merge_meshinstances array must contain at least 2 meshes")
		return

	var tmpMesh = ArrayMesh.new()

	var first_mi = mesh_array[0]

	var mat
	if first_mi is MeshInstance3D:
		mat = first_mi.mesh.surface_get_material(0)
	else:
		printerr("merge_meshinstances array must contain mesh instances")
		return

	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_material(mat)

	var vertex_count: int = 0

	for n in range(mesh_array.size()):
		vertex_count = _merge_meshinstance(st, mesh_array[n], use_local_space, vertex_count)

	st.commit(tmpMesh)

	var new_mi = MeshInstance3D.new()
	new_mi.mesh = tmpMesh

	if new_mi.mesh.get_surface_count():
		new_mi.set_surface_override_material(0, mat)

	if use_local_space:
		new_mi.transform = first_mi.transform

	var sz = first_mi.get_name() + "_merged"
	new_mi.set_name(sz)

	# add the new mesh as a child
	attachment_node.add_child(new_mi)
	new_mi.owner = attachment_node.owner

	if delete_originals:
		for n in range(mesh_array.size()):
			var mi = mesh_array[n]
			var node_3d_placeholder : Node3D = Node3D.new()
			mi.replace_by(node_3d_placeholder, true)
			node_3d_placeholder.transform = mi.transform
			node_3d_placeholder.name = mi.name
			mi.queue_free()

	# return the new mesh instance as it can be useful to change transform
	return new_mi


static func _merge_meshinstance(st: SurfaceTool, mi: MeshInstance3D, use_local_space: bool, vertex_count: int):
	if mi == null:
		printerr("_merge_meshinstance - not a mesh instance, ignoring")
		return vertex_count

	print("merging meshinstance : " + mi.get_name())
	var mesh: Mesh = mi.mesh
	
	var mdt = MeshDataTool.new()
	# only surface 0 for now
	mdt.create_from_surface(mesh, 0)

	var nVerts = mdt.get_vertex_count()
	var nFaces = mdt.get_face_count()

	var xform = mi.transform

	var is_normal: bool = false
	var is_tangent: bool = false
	var is_color: bool = false
	var is_uv: bool = false
	var is_bones: bool = false
	var is_bone_weights: bool = false

	is_normal = mdt.get_vertex_normal(0) != Vector3()
	is_tangent = mdt.get_vertex_tangent(0) != Plane()
	is_color = mdt.get_vertex_color(0) != Color()
	is_uv = mdt.get_vertex_uv(0) != Vector2()
	is_bones = mdt.get_vertex_bones(0).size()
	is_bone_weights = mdt.get_vertex_weights(0).size()

	for n in nVerts:
		var vert = mdt.get_vertex(n)
		
		if is_normal:
			var norm = mdt.get_vertex_normal(n)
			if use_local_space == false:
				norm = xform.basis * norm
				norm = norm.normalized()
			st.set_normal(norm)
		if is_tangent:
			var tangent = mdt.get_vertex_tangent(n)
			if use_local_space == false:
				tangent = Plane(xform * tangent.normal, tangent.d)
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
		if use_local_space == false:
			print(xform.origin)
			vert = xform * vert
		st.add_vertex(vert)

	# indices
	for f in nFaces:
		for i in range(3):
			var ind = mdt.get_face_vertex(f, i)

			# index must take into account the vertices of previously added meshes
			st.add_index(ind + vertex_count)
	# new running vertex count
	return vertex_count + nVerts


func _check_aabb(aabb: AABB):
	assert(aabb.size.x >= 0)
	assert(aabb.size.y >= 0)
	assert(aabb.size.z >= 0)


func _calc_aabb(mesh_instance: MeshInstance3D):
	var aabb: AABB = mesh_instance.get_transformed_aabb()
	# godot intersection doesn't work on borders ...
	aabb = aabb.grow(0.1)
	return aabb


static func traverse_root_and_merge(
	root: Node3D,
) -> void:
	var instances: Array[Node] = root.find_children("*", "MeshInstance3D")

	var mesh_instances: Array[MeshInstance3D]
	if instances.size() == 1:
		return
	for instance in instances:
		mesh_instances.push_back(instance as MeshInstance3D)
	merge_meshinstances(mesh_instances, mesh_instances[0].get_parent())
