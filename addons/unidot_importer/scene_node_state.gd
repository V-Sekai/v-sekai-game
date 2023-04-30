@tool
extends RefCounted

const object_adapter_class: GDScript = preload("./unity_object_adapter.gd")
var object_adapter_class_inst = object_adapter_class.new()

var owner: Node = null
var body: CollisionObject3D = null
var database: Resource = null  # asset_database instance
var meta: Resource = null  # asset_database.AssetMeta instance
var env: Environment = null

# Dictionary from parent_transform uniq_key -> array of convert_scene.Skelley
var skelley_parents: Dictionary = {}.duplicate()
# Dictionary from any transform uniq_key -> convert_scene.Skelley
var uniq_key_to_skelley: Dictionary = {}.duplicate()


# State shared across recursive instances of scene_node_state.
class PrefabState:
	extends RefCounted
	# Prefab_instance_id -> array[UnityTransform objects]
	var child_transforms_by_stripped_id: Dictionary = {}.duplicate()
	var transforms_by_parented_prefab: Dictionary = {}.duplicate()
	#var transforms_by_parented_prefab_source_obj: Dictionary = {}.duplicate()
	var components_by_stripped_id: Dictionary = {}.duplicate()
	var gameobjects_by_parented_prefab: Dictionary = {}.duplicate()
	#var gameobjects_by_parented_prefab_source_obj: Dictionary = {}.duplicate()
	var skelleys_by_parented_prefab: Dictionary = {}.duplicate()

	var non_stripped_prefab_references: Dictionary = {}.duplicate()  # some legacy 5.6 thing I think
	var gameobject_name_map: Dictionary = {}.duplicate()
	var prefab_gameobject_name_map: Dictionary = {}.duplicate()

	# Dictionary from parent_transform uniq_key -> array of UnityPrefabInstance
	var prefab_parents: Dictionary = {}.duplicate()
	var prefab_instance_paths: Array = [].duplicate()

	var main_cameras: Array = [].duplicate()
	var animator_node_to_object: Dictionary = {}.duplicate()


var prefab_state: PrefabState = null
#var root_nodepath: Nodepath = Nodepath("/")


func set_main_name_map(name_map: Dictionary, prefab_name_map: Dictionary = {}):
	meta.gameobject_name_to_fileid_and_children = name_map
	meta.prefab_gameobject_name_to_fileid_and_children = prefab_name_map


func add_prefab_to_parent_transform(gameobject_fileid: int, prefab_id):
	if not meta.transform_fileid_to_prefab_ids.has(gameobject_fileid):
		meta.transform_fileid_to_prefab_ids[gameobject_fileid] = PackedInt64Array().duplicate()
	meta.transform_fileid_to_prefab_ids[gameobject_fileid].append(prefab_id)


func add_name_map_to_prefabbed_transform(gameobject_fileid: int, name_map: Dictionary):
	assert(not meta.transform_fileid_to_children.has(gameobject_fileid))
	meta.transform_fileid_to_children[gameobject_fileid] = name_map


func add_component_map_to_prefabbed_gameobject(gameobject_fileid: int, component_map: Dictionary):
	assert(not meta.gameobject_fileid_to_components.has(gameobject_fileid))
	meta.gameobject_fileid_to_components[gameobject_fileid] = component_map


func add_prefab_rename(gameobject_fileid: int, new_name: String):
	if meta.gameobject_fileid_to_rename.has(gameobject_fileid):
		meta.log_debug(gameobject_fileid,
			(
				"Duplicate rename for fileid "
				+ str(gameobject_fileid)
				+ " : was "
				+ str(meta.gameobject_fileid_to_rename[gameobject_fileid])
				+ " is now "
				+ new_name
			)
		)
	meta.gameobject_fileid_to_rename[gameobject_fileid] = new_name


func get_godot_node(uo: RefCounted) -> Node:
	var np = meta.fileid_to_nodepath.get(uo.fileID, NodePath())
	if np == NodePath():
		np = meta.prefab_fileid_to_nodepath.get(uo.fileID, NodePath())
		if np == NodePath():
			return null
	return owner.get_node(np)


func get_object(fileid: int) -> RefCounted:
	var parsed_asset: RefCounted = meta.parsed.assets.get(fileid)
	if parsed_asset != null and not parsed_asset.is_stripped:
		return parsed_asset
	var utype = meta.fileid_to_utype.get(fileid, -1)
	if utype == -1:
		utype = meta.prefab_fileid_to_utype.get(fileid, -1)
		if utype == -1:
			return null  # Not anywhere in the meta.
	var ret: RefCounted = object_adapter_class_inst.instantiate_unity_object_from_utype(meta, fileid, utype)
	var np = meta.fileid_to_nodepath.get(fileid, NodePath())
	if np == NodePath():
		np = meta.prefab_fileid_to_nodepath.get(fileid, NodePath())
		if np == NodePath():
			return ret
	var node: Node = owner.get_node(np)
	if node == null:
		return ret
	var keys: Variant = node.get_meta("unidot_keys")
	if typeof(keys) == TYPE_DICTIONARY:
		ret.keys = keys
	return ret


func get_gameobject(uo: RefCounted) -> RefCounted:
	var gofd: int = meta.get_gameobject_fileid(uo.fileID)
	if gofd == 0:
		return null
	return get_object(gofd)


func get_component(uo: RefCounted, type: String) -> RefCounted:
	var compid: int = meta.get_component_fileid(uo.fileID, type)
	if compid == 0:
		return null
	return get_object(compid)


func get_components(uo: RefCounted, type: String = "") -> Array:
	var fileids: PackedInt64Array = meta.get_components_fileids(uo.fileID, type)
	var ret: Array = [].duplicate()
	for f in fileids:
		ret.push_back(get_object(f))
	return ret


func find_objects_of_type(type: String) -> Array:
	var fileids: PackedInt64Array = meta.find_fileids_of_type(type)
	var ret: Array = [].duplicate()
	for f in fileids:
		ret.push_back(get_object(f))
	return ret


class Skelley:
	extends RefCounted
	var id: int = 0
	var bones: Array = [].duplicate()

	var root_bones: Array = [].duplicate()

	var bones_set: Dictionary = {}.duplicate()
	var uniq_key_to_bone: Dictionary = {}.duplicate()
	var godot_skeleton: Skeleton3D = Skeleton3D.new()

	# Temporary private storage:
	var intermediate_bones: Array = [].duplicate()
	var intermediates: Dictionary = {}.duplicate()
	var bone0_parent_list: Array = [].duplicate()
	var bone0_parents: Dictionary = {}.duplicate()
	var found_prefab_instance: RefCounted = null  # UnityPrefabInstance

	func initialize(bone0: RefCounted):  # UnityTransform
		var current_parent: RefCounted = bone0  # UnityTransform or UnityPrefabInstance
		var tmp: Array = [].duplicate()
		intermediates[current_parent.uniq_key] = current_parent
		intermediate_bones.push_back(current_parent)
		while current_parent != null:
			tmp.push_back(current_parent)
			bone0_parents[current_parent.uniq_key] = current_parent
			current_parent = current_parent.parent_no_stripped
		# reverse list
		for i in range(len(tmp)):
			bone0_parent_list.push_back(tmp[-1 - i])
		# bone0.log_debug("Initialized " + str(self)+ " ints " + str(intermediates) + " intbones " + str(intermediate_bones) + " b0ps " + str(bone0_parents) + " b0pl " + str(bone0_parent_list))

	func add_bone(bone: RefCounted) -> Array:  # UnityTransform
		if bone == null:
			push_warning("Got null bone in add_bone")
			return []
		if bones_set.has(bone.uniq_key):
			bone.log_warn("Already added bone " + str(bone.uniq_key))
			return []
		bones.push_back(bone)
		bones_set[bone.uniq_key] = true
		# bone.log_debug("Adding a bone: " + str(bones))
		var added_bones: Array = [].duplicate()
		var current_parent: RefCounted = bone  #### UnityTransform or UnityPrefabInstance
		intermediates[current_parent.uniq_key] = current_parent
		intermediate_bones.push_back(current_parent)
		added_bones.push_back(current_parent)
		current_parent = current_parent.parent_no_stripped
		while current_parent != null and not bone0_parents.has(current_parent.uniq_key):
			if intermediates.has(current_parent.uniq_key):
				# bone.log_debug("Already intermediate to add " + str(bone) + "/" + str(current_parent) + " " + str(self)+ " ints " + str(intermediates) + " intbones " + str(intermediate_bones) + " b0ps " + str(bone0_parents) + " b0pl " + str(bone0_parent_list))
				return added_bones
			intermediates[current_parent.uniq_key] = current_parent
			intermediate_bones.push_back(current_parent)
			added_bones.push_back(current_parent)
			current_parent = current_parent.parent_no_stripped
		if current_parent == null:
			bone.log_warn("Warning: No common ancestor for skeleton " + bone.uniq_key + ": assume parented at root")
			bone0_parents.clear()
			bone0_parent_list.clear()
			return added_bones
		#if current_parent.parent_no_stripped == null:
		#	bone0_parents.clear()
		#	bone0_parent_list.clear()
		#	bone.log_warn("Warning: Skeleton parented at root " + bone.uniq_key + " at " + current_parent.uniq_key)
		#	return added_bones
		if bone0_parent_list.is_empty():
			# bone.log_debug("b0pl is empty to add " + str(bone) + "/" + str(current_parent) + " " + str(self)+ " ints " + str(intermediates) + " intbones " + str(intermediate_bones) + " b0ps " + str(bone0_parents) + " b0pl " + str(bone0_parent_list) +": " + str(added_bones))
			return added_bones
		while bone0_parent_list[-1] != current_parent:
			bone0_parents.erase(bone0_parent_list[-1].uniq_key)
			bone0_parent_list.pop_back()
			if bone0_parent_list.is_empty():
				bone.log_fail("Assertion failure " + bones[0].uniq_key + "/" + current_parent.uniq_key, "parent", current_parent)
				return []
			if not intermediates.has(bone0_parent_list[-1].uniq_key):
				intermediates[bone0_parent_list[-1].uniq_key] = bone0_parent_list[-1]
				intermediate_bones.push_back(bone0_parent_list[-1])
				added_bones.push_back(bone0_parent_list[-1])
		#if current_parent.is_stripped and found_prefab_instance == null:
		# If this is child a prefab instance, we want to make sure the prefab instance itself
		# is used for skeleton merging, so that we avoid having duplicate skeletons.
		# WRONG!!! They might be different skelleys in the source prefab.
		#	found_prefab_instance = current_parent.parent_no_stripped
		#	if found_prefab_instance != null:
		#		added_bones.push_back(found_prefab_instance)
		# bone.log_debug("success added " + str(bone) + "/" + str(current_parent) + " " + str(self)+ " ints " + str(intermediates) + " intbones " + str(intermediate_bones) + " b0ps " + str(bone0_parents) + " b0pl " + str(bone0_parent_list) +": " + str(added_bones))
		return added_bones

	# if null, this is not mixed with a prefab's nodes
	var parent_prefab: RefCounted:  # UnityPrefabInstance
		get:
			if bone0_parent_list.is_empty():
				return null
			var arrlen: int = len(bone0_parent_list) - 1
			var pref: RefCounted = bone0_parent_list[arrlen]  # UnityTransform or UnityPrefabInstance
			if pref.type == "PrefabInstance":
				return pref
			return null

	# if null, this is a root node.
	var parent_transform: RefCounted:  # UnityTransform
		get:
			if bone0_parent_list.is_empty():
				return null
			var arrlen: int = len(bone0_parent_list) - 1
			var pref: RefCounted = bone0_parent_list[arrlen]  # UnityTransform or UnityPrefabInstance
			if pref.type == "Transform":
				return pref
			return null

	func add_nodes_recursively(
		skel_parents: Dictionary, child_transforms_by_stripped_id: Dictionary, bone_transform: RefCounted
	):
		if bone_transform.is_stripped:
			#bone_transform.log_warn("Not able to add skeleton nodes from a stripped transform!")
			for child in child_transforms_by_stripped_id.get(bone_transform.fileID, []):
				if not intermediates.has(child.uniq_key):
					child.log_debug(
						(
							"Adding child bone "
							+ str(child)
							+ " into intermediates during recursive search from "
							+ str(bone_transform)
						)
					)
					intermediates[child.uniq_key] = child
					intermediate_bones.push_back(child)
					# TODO: We might also want to exclude prefab instances here.
					# If something is a prefab, we should not include it in the skeleton!
					if not skel_parents.has(child.uniq_key):
						# We will not recurse: everything underneath this is part of a separate skeleton.
						add_nodes_recursively(skel_parents, child_transforms_by_stripped_id, child)
			return
		for child_ref in bone_transform.children_refs:
			var child: RefCounted = bone_transform.meta.lookup(child_ref)  # UnityTransform
			# child.log_debug("Try child " + str(child_ref))
			# not skel_parents.has(child.uniq_key):
			if not intermediates.has(child.uniq_key):
				child.log_debug(
					(
						"Adding child bone "
						+ str(child)
						+ " into intermediates during recursive search from "
						+ str(bone_transform)
					)
				)
				intermediates[child.uniq_key] = child
				intermediate_bones.push_back(child)
				# TODO: We might also want to exclude prefab instances here.
				# If something is a prefab, we should not include it in the skeleton!
				if not skel_parents.has(child.uniq_key):
					# We will not recurse: everything underneath this is part of a separate skeleton.
					add_nodes_recursively(skel_parents, child_transforms_by_stripped_id, child)

	func construct_final_bone_list(skel_parents: Dictionary, child_transforms_by_stripped_id: Dictionary):
		var par_transform: RefCounted = bone0_parent_list[-1]  # UnityTransform or UnityPrefabInstance
		if par_transform == null:
			push_error("Final bone list transform is null!")
			return
		var par_key: String = par_transform.uniq_key
		var contains_stripped_bones: bool = false
		for bone in intermediate_bones:
			if bone.is_stripped_or_prefab_instance():
				root_bones.push_back(bone)
				continue
			if bone.parent_no_stripped == null or bone.parent_no_stripped.uniq_key == par_key:
				root_bones.push_back(bone)
		# par_transform.log_debug("Construct final bone list bones: " + str(bones))
		for bone in bones.duplicate():
			bone.log_debug("Skelley " + str(par_transform.uniq_key) + " has root bone " + str(bone.uniq_key))
			self.add_nodes_recursively(skel_parents, child_transforms_by_stripped_id, bone)
		# Keep original bone list in order; migrate intermediates in.
		for bone in bones:
			intermediates.erase(bone.uniq_key)
		for bone in intermediate_bones:
			if bone.is_stripped_or_prefab_instance:
				# We do not explicitly add stripped bones if they are not already present.
				# FIXME: Do cases exist in which we are required to add intermediate stripped bones?
				continue
			if intermediates.has(bone.uniq_key):
				if bones_set.has(bone.uniq_key):
					bone.log_warn("Already added intermediate bone " + str(bone.uniq_key))
				else:
					bones_set[bone.uniq_key] = true
					bones.push_back(bone)
		var idx: int = 0
		for bone in bones:
			if bone.is_stripped_or_prefab_instance():
				# We do not know yet the full extent of the skeleton
				uniq_key_to_bone[bone.uniq_key] = -1
				bone.log_debug(
					(
						"bone "
						+ bone.uniq_key
						+ " is stripped "
						+ str(bone.is_stripped)
						+ " or prefab instance. CLEARING SKELETON"
					)
				)
				contains_stripped_bones = true
				godot_skeleton = null
				continue
			uniq_key_to_bone[bone.uniq_key] = idx
			bone.skeleton_bone_index = idx
			idx += 1
		if not contains_stripped_bones:
			var dedupe_dict = {}.duplicate()
			for bone_i in range(godot_skeleton.get_bone_count()):
				dedupe_dict[godot_skeleton.get_bone_name(bone_i)] = null
			for bone in bones:
				if not dedupe_dict.has(bone.name):
					dedupe_dict[bone.name] = bone
			idx = 0
			for bone in bones:
				var ctr: int = 0
				var orig_bone_name: String = bone.name
				var bone_name: String = orig_bone_name
				while dedupe_dict.get(bone_name) != bone:
					ctr += 1
					bone_name = orig_bone_name + " " + str(ctr)
					if not dedupe_dict.has(bone_name):
						dedupe_dict[bone_name] = bone
				godot_skeleton.add_bone(bone_name)
				bone.log_debug(
					(
						"Adding bone "
						+ bone_name
						+ " idx "
						+ str(idx)
						+ " new size "
						+ str(godot_skeleton.get_bone_count())
					)
				)
				idx += 1
			idx = 0
			for bone in bones:
				if bone.parent_no_stripped == null:
					godot_skeleton.set_bone_parent(idx, -1)
				else:
					godot_skeleton.set_bone_parent(idx, uniq_key_to_bone.get(bone.parent_no_stripped.uniq_key, -1))
				# godot_skeleton.set_bone_rest(idx, bone.godot_transform)
				idx += 1
	# Skelley rules:
	# Root bone will be added as parent to common ancestor of all bones
	# Found parent transforms of each skeleton.
	# Found a list of bones in each skeleton.


func _init(database: Resource, meta: Resource, root_node: Node3D):
	init_node_state(database, meta, root_node)


func duplicate() -> RefCounted:
	var state = get_script().new(database, meta, owner)
	state.env = env
	state.body = body
	state.skelley_parents = skelley_parents
	state.uniq_key_to_skelley = uniq_key_to_skelley
	state.prefab_state = prefab_state
	return state


func add_child(child: Node, new_parent: Node3D, unityobj: RefCounted):
	# meta. # FIXME???
	if owner != null:
		if new_parent == null:
			meta.log_warn(0, "Trying to add child " + str(child) + " named " + str(child.name) + " to null parent", "parent", unityobj)
		assert(new_parent != null)
		new_parent.add_child(child, true)
		child.owner = owner
	if new_parent == null:
		assert(owner == null)
		# We are the root (of a Prefab). Become the owner.
		self.owner = child
	else:
		assert(owner != null)
	if unityobj.fileID != 0:
		add_fileID(child, unityobj)


func add_fileID_to_skeleton_bone(bone_name: String, fileID: int):
	meta.fileid_to_skeleton_bone[fileID] = bone_name


func remove_fileID_to_skeleton_bone(fileID: int):
	meta.fileid_to_skeleton_bone[fileID] = ""


func add_fileID(child: Node, unityobj: RefCounted):
	if owner != null:
		unityobj.log_debug(
			(
				"Add fileID "
				+ str(unityobj.fileID)
				+ " type "
				+ str(unityobj.utype)
				+ " "
				+ str(owner.name)
				+ " to "
				+ str(child.name)
			)
		)
		meta.fileid_to_nodepath[unityobj.fileID] = owner.get_path_to(child)
	# FIXME??
	#else:
	#	meta.fileid_to_nodepath[fileID] = root_nodepath


func init_node_state(database: Resource, meta: Resource, root_node: Node3D) -> RefCounted:
	self.database = database
	self.meta = meta
	self.owner = root_node
	self.prefab_state = PrefabState.new()
	return self


func state_with_body(new_body: CollisionObject3D) -> RefCounted:
	var state = duplicate()
	state.body = new_body
	return state


func state_with_meta(new_meta: Resource) -> RefCounted:
	var state = duplicate()
	state.meta = new_meta
	return state


func state_with_owner(new_owner: Node3D) -> RefCounted:
	var state = duplicate()
	state.owner = new_owner
	return state


#func state_with_nodepath(additional_nodepath) -> RefCounted:
#	var state = duplicate()
#	state.root_nodepath = NodePath(str(root_nodepath) + str(asdditional_nodepath) + "/")
#	return state


func initialize_skelleys(assets: Array) -> Array:
	var skelleys: Dictionary = {}.duplicate()
	var skel_ids: Dictionary = {}.duplicate()
	var num_skels = 0

	var child_transforms_by_stripped_id: Dictionary = prefab_state.child_transforms_by_stripped_id

	# Start out with one Skeleton per SkinnedMeshRenderer, but merge overlapping skeletons.
	# This includes skeletons where the members are interleaved (S1 -> S2 -> S1 -> S2)
	# which can actually happen in practice, for example clothing with its own bones.
	for asset in assets:
		if asset.type == "SkinnedMeshRenderer":
			if asset.is_stripped:
				# FIXME: We may need to later pull out the "m_Bones" from the modified components??
				continue
			var orig_bones: Array = asset.bones
			var bones: Array = []
			asset.log_debug("Importing model " + asset.meta.guid + " at " + asset.meta.path + ": " + str(orig_bones))
			for b in orig_bones:
				if asset.meta.lookup(b) == null:
					continue
				bones.append(b)
			if bones.is_empty():
				# Common if MeshRenderer is upgraded to SkinnedMeshRenderer, e.g. by the user.
				# For example, this happens when adding a Cloth component.
				# Also common for meshes which have blend shapes but no skeleton.
				# Skinned mesh renderers without bones act as normal meshes.
				continue
			var bone0_obj: RefCounted = asset.meta.lookup(bones[0])  # UnityTransform
			# TODO: what about meshes with bones but without skin? Can this even happen?
			if bone0_obj == null:
				asset.log_warn(
					(
						"ERROR: Importing model "
						+ asset.meta.guid
						+ " at "
						+ asset.meta.path
						+ ": "
						+ str(bones[0])
						+ " is null"
					)
				)
			var this_id: int = num_skels
			var this_skelley: Skelley = null
			if skel_ids.has(bone0_obj.uniq_key):
				this_id = skel_ids[bone0_obj.uniq_key]
				this_skelley = skelleys[this_id]
			else:
				this_skelley = Skelley.new()
				this_skelley.initialize(bone0_obj)
				this_skelley.id = this_id
				skelleys[this_id] = this_skelley
				num_skels += 1

			for bone in bones:
				var bone_obj: RefCounted = asset.meta.lookup(bone)  # UnityTransform
				var added_bones = this_skelley.add_bone(bone_obj)
				# asset.log_debug("Told skelley " + str(this_id) + " to add bone " + bone_obj.uniq_key + ": " + str(added_bones))
				for added_bone in added_bones:
					var uniq_key: String = added_bone.uniq_key
					if skel_ids.get(uniq_key, this_id) != this_id:
						# We found a match! Let's merge the Skelley objects.
						var new_id: int = skel_ids[uniq_key]
						# asset.log_debug("migrating from " + str(skelleys[this_id].bones))
						for inst in skelleys[this_id].bones:
							# asset.log_debug("Loop " + str(inst.uniq_key) + " skelley " + str(this_id) + " -> " + str(skel_ids.get(inst.uniq_key, -1)))
							if skel_ids.get(inst.uniq_key, -1) == this_id:  # FIXME: This seems to be missing??
								# asset.log_debug("Telling skelley " + str(new_id) + " to merge bone " + inst.uniq_key)
								skelleys[new_id].add_bone(inst)
						for i in skel_ids:
							if skel_ids.get(str(i)) == this_id:
								skel_ids[str(i)] = new_id
						skelleys.erase(this_id)  # We merged two skeletons.
						this_id = new_id
						this_skelley = skelleys[this_id]
					skel_ids[uniq_key] = this_id
					# asset.log_debug("Skel ids now " + str(skel_ids))

	var skelleys_with_no_parent = [].duplicate()

	# If skelley_parents contains your node, add Skelley.skeleton as a child to it for each item in the list.
	for skel_id in skelleys:
		var skelley: Skelley = skelleys[skel_id]
		var par_transform: RefCounted = skelley.parent_transform  # UnityTransform or UnityPrefabInstance
		var i = 0
		for bone in skelley.bones:
			i = i + 1
			if bone == par_transform:
				par_transform = par_transform.parent_no_stripped
				skelley.bone0_parent_list.pop_back()
		if skelley.parent_transform == null:
			if skelley.parent_prefab == null:
				skelleys_with_no_parent.push_back(skelley)
			else:
				var uk: String = skelley.parent_prefab.uniq_key
				if not prefab_state.skelleys_by_parented_prefab.has(uk):
					prefab_state.skelleys_by_parented_prefab[uk] = [].duplicate()
				prefab_state.skelleys_by_parented_prefab[uk].push_back(skelley)
		else:
			var uniq_key = skelley.parent_transform.uniq_key
			if not skelley_parents.has(uniq_key):
				skelley_parents[uniq_key] = [].duplicate()
			skelley_parents[uniq_key].push_back(skelley)

	for skel_id in skelleys:
		var skelley: Skelley = skelleys[skel_id]
		skelley.construct_final_bone_list(skelley_parents, child_transforms_by_stripped_id)
		for uniq_key in skelley.uniq_key_to_bone:
			uniq_key_to_skelley[uniq_key] = skelley
			meta.log_debug(0, "ADDING uniq key " + str(uniq_key) + " skelley " + str(skelley))

	return skelleys_with_no_parent


func add_bones_to_prefabbed_skeletons(uniq_key: String, target_prefab_meta: Resource, instanced_scene: Node3D):
	var fileid_to_added_bone: Dictionary = {}.duplicate()
	var fileid_to_skeleton_nodepath: Dictionary = {}.duplicate()
	var fileid_to_bone_name: Dictionary = {}.duplicate()

	for skelley in prefab_state.skelleys_by_parented_prefab.get(uniq_key, []):
		var godot_skeleton_nodepath = NodePath()
		for bone in skelley.bones:  # skelley.root_bones:
			if not bone.is_prefab_reference:
				# We are iterating through bones array because root_bones was not reliable.
				# So we will hit both types of bones. Let's just ignore non-prefab bones for now.
				# FIXME: Should we try to fix the root_bone logic so we can detect bad Skeletons?
				# bone.log_warn("Skeleton parented to prefab contains root bone not rooted within prefab.")
				continue
			var source_obj_ref = bone.prefab_source_object
			var target_skelley: NodePath = target_prefab_meta.fileid_to_nodepath.get(
				source_obj_ref[1], target_prefab_meta.prefab_fileid_to_nodepath.get(source_obj_ref[1], NodePath())
			)
			var target_skel_bone: String = target_prefab_meta.fileid_to_skeleton_bone.get(
				source_obj_ref[1], target_prefab_meta.prefab_fileid_to_skeleton_bone.get(source_obj_ref[1], "")
			)
			# bone.log_debug("Parented prefab root bone : " + str(bone.uniq_key) + " for " + str(target_skelley) + ":" + str(target_skel_bone))
			if godot_skeleton_nodepath == NodePath() and target_skelley != NodePath():
				godot_skeleton_nodepath = target_skelley
				skelley.godot_skeleton = instanced_scene.get_node(godot_skeleton_nodepath)
			if target_skelley != godot_skeleton_nodepath:
				bone.log_fail("Skeleton child of prefab spans multiple Skeleton objects in source prefab.", "bones", source_obj_ref)
			fileid_to_skeleton_nodepath[bone.fileID] = target_skelley
			fileid_to_bone_name[bone.fileID] = target_skel_bone
			if skelley.godot_skeleton != null:
				bone.skeleton_bone_index = skelley.godot_skeleton.find_bone(target_skel_bone)
			# if fileid_to_skeleton_nodepath.has(source_obj_ref[1]):
			# 	if fileid_to_skeleton_nodepath.get(source_obj_ref[1]) != target_skelley:
			# 		bone.log_warn("Skeleton spans multiple ")
			# WE ARE NOT REQUIRED TO create a new skelley object for each Skeleton3D instance in the inflated scene.
			# NO! THIS IS STUPID Then, the skelley objects with parent=scene should be dissolved and replaced with extended versions of the prefab's skelley
			# For every skelley in this prefab, go find the corresponding Skeleton3D object and add the missing nodes. that's it.
			# Then, we should make sure we create the bone attachments for all grand/great children too.
			# FINALLY! We did all this. now let's add the skins and proper bone index arrays into the skins!
		# Add all the bones
		if skelley.godot_skeleton == null:
			meta.log_fail(0, "Skelley " + str(skelley) + " in prefab " + uniq_key + " could not find source godot skeleton!", "prefab", [null,-1,target_prefab_meta.guid,-1])
			continue
		var dedupe_dict = {}.duplicate()
		for idx in range(skelley.godot_skeleton.get_bone_count()):
			dedupe_dict[skelley.godot_skeleton.get_bone_name(idx)] = null
		for bone in skelley.bones:
			if bone.is_prefab_reference:
				continue
			if fileid_to_bone_name.has(bone.fileID):
				continue
			if not dedupe_dict.has(bone.name):
				dedupe_dict[bone.name] = bone
		for bone in skelley.bones:
			if bone.is_prefab_reference:
				continue
			if fileid_to_bone_name.has(bone.fileID):
				continue
			var new_idx: int = skelley.godot_skeleton.get_bone_count()
			var ctr: int = 0
			var orig_bone_name: String = bone.name
			var bone_name: String = orig_bone_name
			while dedupe_dict.get(bone_name) != bone:
				ctr += 1
				bone_name = orig_bone_name + " " + str(ctr)
				if not dedupe_dict.has(bone_name):
					dedupe_dict[bone_name] = bone
			skelley.godot_skeleton.add_bone(bone_name)
			bone.log_debug(
				(
					"Prefab adding bone "
					+ bone.name
					+ " idx "
					+ str(new_idx)
					+ " new size "
					+ str(skelley.godot_skeleton.get_bone_count())
				)
			)
			fileid_to_bone_name[bone.fileID] = skelley.godot_skeleton.get_bone_name(new_idx)
			bone.skeleton_bone_index = new_idx
		# Now set up the indices and parents.
		for bone in skelley.bones:
			if bone.is_prefab_reference:
				continue
			if fileid_to_skeleton_nodepath.has(bone.fileID):
				continue
			var idx: int = skelley.godot_skeleton.find_bone(fileid_to_bone_name.get(bone.fileID, ""))
			var parent_bone_index: int = -1
			if bone.parent.is_prefab_reference:
				var source_obj_ref = bone.parent.prefab_source_object
				var target_skel_bone: String = target_prefab_meta.fileid_to_skeleton_bone.get(
					source_obj_ref[1], target_prefab_meta.prefab_fileid_to_skeleton_bone.get(source_obj_ref[1], "")
				)
				parent_bone_index = skelley.godot_skeleton.find_bone(target_skel_bone)
			else:
				parent_bone_index = skelley.godot_skeleton.find_bone(fileid_to_bone_name.get(bone.parent.fileID, ""))
			bone.log_debug("Parent bone index: " + str(bone.name) + " / " + str(bone.uniq_key) + " / " + str(parent_bone_index))
			skelley.godot_skeleton.set_bone_parent(idx, parent_bone_index)
			# skelley.godot_skeleton.set_bone_rest(idx, bone.godot_transform) # Set later on.
			fileid_to_skeleton_nodepath[bone.fileID] = godot_skeleton_nodepath
