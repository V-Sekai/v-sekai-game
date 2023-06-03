# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_importer.gd
# SPDX-License-Identifier: MIT

@tool
extends Node

const validator_const = preload("res://addons/vsk_importer_exporter/vsk_validator.gd")
const validator_avatar_const = preload("res://addons/vsk_importer_exporter/vsk_avatar_validator.gd")
const validator_map_const = preload("res://addons/vsk_importer_exporter/vsk_map_validator.gd")
const importer_const = preload("res://addons/vsk_importer_exporter/vsk_importer.gd")

const NO_PARENT_SAVED = 0x7FFFFFFF
const NAME_INDEX_BITS = 18

const FLAG_ID_IS_PATH = (1 << 30)
const TYPE_INSTANCE = 0x7fffffff
const FLAG_INSTANCE_IS_PLACEHOLDER = (1 << 30)
const FLAG_MASK = (1 << 24) - 1

enum ImporterResult {
	OK,
	FAILED,
	NULL_PACKED_SCENE,
	READ_FAIL,
	HAS_NODE_GROUPS,
	FAILED_TO_CREATE_TREE,
	INVALID_ENTITY_PATH,
	UNSAFE_NODEPATH,
	SCRIPT_ON_INSTANCE_NODE,
	INVALID_ROOT_SCRIPT,
	INVALID_CHILD_SCRIPT,
	RECURSIVE_CANVAS,
	INVALID_NODE_CLASS,
	INVALID_ANIMATION_PLAYER_ROOT,
	INVALID_METHOD_TRACK,
	INVALID_VALUE_TRACK,
	INVALID_TRACK_PATH,
}

class RefNode:
	extends RefCounted
	var id: int = -1
	var name: String = ""
	var properties: Array = []
	var class_str: String = ""
	var instance_path: String = ""
	var parent: RefNode = null
	var children: Array = []


class NodeData:
	extends RefCounted
	var parent_id: int = -1
	var owner_id: int = -1
	var type_id: int = -1
	var name_id: int = -1
	var index_id: int = -1
	var instance_id: int = -1
	var properties: Array = []
	var groups: Array = []
	
static func get_string_for_importer_result(p_importer_result: ImporterResult) -> String:
	match p_importer_result:
		ImporterResult.OK:
			return "OK"
		ImporterResult.FAILED:
			return "FAILED"
		ImporterResult.NULL_PACKED_SCENE:
			return "NULL_PACKED_SCENE"
		ImporterResult.READ_FAIL:
			return "READ_FAIL"
		ImporterResult.HAS_NODE_GROUPS:
			return "HAS_NODE_GROUPS"
		ImporterResult.FAILED_TO_CREATE_TREE:
			return "FAILED_TO_CREATE_TREE"
		ImporterResult.INVALID_ENTITY_PATH:
			return "INVALID_ENTITY_PATH"
		ImporterResult.UNSAFE_NODEPATH:
			return "UNSAFE_NODEPATH"
		ImporterResult.SCRIPT_ON_INSTANCE_NODE:
			return "SCRIPT_ON_INSTANCE_NODE"
		ImporterResult.INVALID_ROOT_SCRIPT:
			return "INVALID_ROOT_SCRIPT"
		ImporterResult.INVALID_CHILD_SCRIPT:
			return "INVALID_CHILD_SCRIPT"
		ImporterResult.RECURSIVE_CANVAS:
			return "RECURSIVE_CANVAS"
		ImporterResult.INVALID_NODE_CLASS:
			return "INVALID_NODE_CLASS"
		ImporterResult.INVALID_ANIMATION_PLAYER_ROOT:
			return "INVALID_ANIMATION_PLAYER_ROOT"
		ImporterResult.INVALID_METHOD_TRACK:
			return "INVALID_METHOD_TRACK"
		ImporterResult.INVALID_VALUE_TRACK:
			return "INVALID_VALUE_TRACK"
		ImporterResult.INVALID_TRACK_PATH:
			return "INVALID_TRACK_PATH"
		_:
			return "UNKNOWN_ERROR"
	
static func create_path_from_root_to_node(p_node: RefNode) -> String:
	var current_node: RefNode = p_node
	var path_string = ""
	while(current_node):
		if path_string.is_empty():
			path_string = current_node.name
		else:
			path_string = current_node.name + "/" + path_string
		
		current_node = current_node.parent
		
	return path_string

# This function attempts to walk the RefTree to make sure a nodepath is not
# breaking out of the sandbox
static func get_ref_node_from_relative_path(p_node: RefNode, p_path: NodePath) -> RefNode:
	var nodepath: NodePath = p_path
	
	var root: RefNode = null
	if nodepath.is_empty() or nodepath.is_absolute():
		return root
		
	var current: RefNode = p_node
	
	for i in range(0, nodepath.get_name_count()):
		var nodepath_name: String = nodepath.get_name(i)
		var next: RefNode = null
		
		if nodepath_name == ".":
			next = current
		elif nodepath_name == "..":
			if current == null or !current.parent:
				return null
				
			next = current.parent
		elif (current == null):
			
			if (nodepath_name == root.get_name()):
				next = root
		else:
			next = null
			
			for child in current.children:
				if child.name == nodepath_name:
					next = child
					break
			if next == null:
				return null
		current = next

	return current

enum RefNodeType {
	OTHER = 0,
	ANIMATION_PLAYER = 1,
	MESH_INSTANCE = 2
}

static func scan_ref_node_tree(p_ref_branch: RefNode, p_canvas: bool, p_validator: RefCounted) -> Dictionary: # validator_const
	# Special-case handling code for animation players
	var ref_node_type: int = RefNodeType.OTHER
	var skip_type_check: bool = false
	var is_instance: bool = false
	var children_belong_to_canvas: bool = p_canvas
	
	var animations: Array = []
	var animation_player_ref_node: RefNode = null
	
	if p_ref_branch.class_str == "Instanced":
		if p_validator.is_path_an_entity(p_ref_branch.instance_path):
			skip_type_check = true
			is_instance = true
		else:
			return {
				"code":ImporterResult.INVALID_ENTITY_PATH,
				"info":"Attempted to instance a none entity on node '{node_path}'".format(
					{"node_path":create_path_from_root_to_node(p_ref_branch)}
				)
			}
	
	match p_ref_branch.class_str:
		"AnimationPlayer":
			ref_node_type = RefNodeType.ANIMATION_PLAYER
			animation_player_ref_node = p_ref_branch.parent
	
	var animation_node_root_path: NodePath = NodePath()
	
	for property in p_ref_branch.properties:
		var property_name = property["name"]
		var property_value = property["value"]
			
		# We must make sure that any node path variants in this node only
		# reference nodes within this scene
		if property_value is NodePath:
			var ref_node_path_target: RefNode = get_ref_node_from_relative_path(p_ref_branch, property_value)
			if ref_node_path_target == null and property_name != "vskeditor_preview_camera_path" and property_name != "skeleton":
				return {
					"code":ImporterResult.UNSAFE_NODEPATH,
					"info":"Unsafe node path on node: '{node_path}', property:'{property}', path:'{value}'".format(
						{
							"node_path":create_path_from_root_to_node(p_ref_branch),
							"property":property_name,
							"value":str(property_value)
						}
					)
				}		
				
			if ref_node_type == RefNodeType.ANIMATION_PLAYER:
				if property_name == "root_node":
					animation_player_ref_node = ref_node_path_target
					animation_node_root_path = property_value
					
		elif property_value is Script:
			if property_name == "script":
				if is_instance:
					return {
						"code":ImporterResult.SCRIPT_ON_INSTANCE_NODE,
						"info":"Script assigned to instance node
							node: '{node_path}',
							script_path: '{script_path}'"
							.format(
							{
								"node_path":create_path_from_root_to_node(p_ref_branch),
								"script_path":property_value.resource_path
							}
						)
					}	
				
				if p_ref_branch.parent == null:
					# Check if the script is valid for the root node
					if !p_validator.is_script_valid_for_root(property_value, p_ref_branch.class_str):
						return {
							"code":ImporterResult.INVALID_ROOT_SCRIPT,
							"info":"Invalid script for root node: '{node_path}', script_path: '{script_path}'".format(
								{
									"node_path":create_path_from_root_to_node(p_ref_branch),
									"script_path":property_value.resource_path
								}
							)
						}
					else:
						skip_type_check = true
				else:
					# Check if this object is a canvas anchor
					if p_validator.is_valid_canvas_3d_anchor(property_value, p_ref_branch.class_str):
						children_belong_to_canvas = false
						skip_type_check = true
					# Check if this object is a canvas
					elif p_validator.is_valid_canvas_3d(property_value, p_ref_branch.class_str):
						if p_canvas:
							return {
								"code":ImporterResult.RECURSIVE_CANVAS,
								"info":"Recursive canvas detected in '{node_path}'".format(
									{
										"node_path":create_path_from_root_to_node(p_ref_branch),
									}
								)
							}
						else:
							children_belong_to_canvas = true
							skip_type_check = true
					else:
						# Check if it's another valid script for a child node
						if !p_validator.is_script_valid_for_children(property_value, p_ref_branch.class_str):
							return {
								"code":ImporterResult.INVALID_CHILD_SCRIPT,
								"info":"Invalid script for for child node: '{node_path}', script_path: '{script_path}'".format(
									{
										"node_path":create_path_from_root_to_node(p_ref_branch),
										"script_path":property_value.resource_path
									}
								)
							}
						else:
							skip_type_check = true
						
		elif property_value is Animation:
			# Save all animation for later validation
			animations.push_back(property_value)
			
	# Okay, with that information, make sure the node type itself is valid
	if !skip_type_check:
		if !p_validator.is_node_type_string_valid(p_ref_branch.class_str, p_canvas):
				return {
					"code":ImporterResult.INVALID_NODE_CLASS,
					"info":"Invalid node class '{class_name}' in node '{node_path}'".format(
						{
							"node_path":create_path_from_root_to_node(p_ref_branch),
							"class_name":p_ref_branch.class_str
						}
					)
				}

	for animation in animations:
		# If the animation player root node is null, it is not a secure path
		if !animation_player_ref_node:
			return {
				"code":ImporterResult.INVALID_ANIMATION_PLAYER_ROOT,
				"info":"Invalid root node for animation player '{node_path}', with path {root_path}".format(
					{
						"node_path":create_path_from_root_to_node(p_ref_branch),
						"root_path":str(animation_node_root_path)
					}
				)
			}
			
		# Now, loop through all the tracks
		var track_count: int = animation.get_track_count()
		for i in range(0, track_count):
			# Make sure all track paths reference the nodes in this scene
			var track_path: NodePath = animation.track_get_path(i)
			
			var track_ref_node: RefNode = get_ref_node_from_relative_path(animation_player_ref_node, track_path)
			if !track_ref_node:
				return {
					"code":ImporterResult.INVALID_TRACK_PATH,
					"info":"Invalid track_path for animation player '{node_path}', with path {track_path}".format(
						{
							"node_path":create_path_from_root_to_node(p_ref_branch),
							"track_path":str(track_path)
						}
					)
				}
			
			var track_type_int: int = animation.track_get_type(i)
			
			# Method and value tracks are currently banned until they can
			# be properly validated for safety
			if track_type_int == Animation.TYPE_METHOD:
				return {
					"code":ImporterResult.INVALID_METHOD_TRACK,
					"info":
						"Attempted to implement method track on '{node_path}', with path {track_path}.\nNot method tracks are current allowed until they can be implemented safely".format(
						{
							"node_path":create_path_from_root_to_node(p_ref_branch),
							"track_path":str(track_path)
						}
					)
				}
			elif track_type_int == Animation.TYPE_VALUE:
				if !p_validator.validate_value_track(
					track_path.get_concatenated_subnames(),
					track_ref_node.class_str):
					return {
						"code":ImporterResult.INVALID_VALUE_TRACK,
						"info":"Attempted to implement value track on '{node_path}', with path {track_path}".format(
							{
								"node_path":create_path_from_root_to_node(p_ref_branch),
								"track_path":str(track_path)
							}
						)
					}
			
	for child_ref_node in p_ref_branch.children:
		var result: Dictionary = scan_ref_node_tree(
			child_ref_node,
			children_belong_to_canvas,
			p_validator)
			
		if result["code"] != ImporterResult.OK:
			return result
		
	return {"code":ImporterResult.OK, "info":""}

# Build a node tree of RefNodes and return the root
static func build_ref_node_tree(
	p_node_data_array: Array,
	p_names: PackedStringArray,
	p_variants: Array,
	p_node_paths: PackedStringArray,
	_p_editable_instances: Array
):
	var root_ref_node: RefNode = null
	var ref_nodes: Array = []
	
	#var has_root: bool = false
	
	for snode in p_node_data_array:
		var ref_node = RefNode.new()
		if p_names.size() > snode.name_id - 1:
			ref_node.name = p_names[snode.name_id]
			for property in snode.properties:
				var property_name: String = p_names[property["name"]]
				var property_value = p_variants[property["value"]]
				
				ref_node.properties.push_back(
					{"name":property_name, "value":property_value}
				)
				
		else:
			return null
			
		var type: int = snode.type_id
		var parent_id: int = snode.parent_id
		
		if parent_id < 0 or parent_id == NO_PARENT_SAVED:
			if root_ref_node == null:
				root_ref_node = ref_node
			else:
				return null
		else:
			if root_ref_node == null:
				return null
				
			if parent_id & FLAG_ID_IS_PATH:
				var idx: int = parent_id & FLAG_MASK
				if p_node_paths.size() > idx - 1:
					var node_path: String = p_node_paths[idx]
					var parent_node: RefNode = get_ref_node_from_relative_path(root_ref_node, node_path)
					if parent_node:
						ref_node.parent = parent_node
						parent_node.children.push_back(ref_node)
						# TODO: check circular dependency
					else:
						return null
			else:
				var idx: int = parent_id & FLAG_MASK
				if ref_nodes.size() > idx - 1:
					ref_node.parent = ref_nodes[parent_id & FLAG_MASK]
					ref_nodes[parent_id & FLAG_MASK].children.push_back(ref_node)
					# TODO: check circular dependency
					
		if type == TYPE_INSTANCE:
			ref_node.class_str = "Instanced"
			var instance_id: int = snode.instance_id
			#var editable_instance = p_editable_instances[instance_id]
			ref_node.instance_path = p_variants[instance_id].resource_path
		else:
			if p_names.size() > snode.type_id - 1:
				ref_node.class_str = p_names[snode.type_id]
		
		ref_node.id = ref_nodes.size()
		ref_nodes.push_back(ref_node)
		
	return root_ref_node

# Read the next integer in the array and increment the internal IDX
static func reader_snode(p_snodes: PackedInt32Array, p_reader: Dictionary) -> Dictionary:
	if p_reader.idx < p_snodes.size() and p_reader.idx >= 0:
		p_reader.result = p_snodes[p_reader.idx]
		p_reader.idx += 1
	else:
		p_reader.result = null
		p_reader.idx = -1

	return p_reader
	

static func sanitise_packed_scene(
	p_packed_scene: PackedScene,
	p_validator: RefCounted
	) -> Dictionary: # validator_const

	if p_packed_scene == null:
		return {"packed_scene":null, "result":{"code":ImporterResult.NULL_PACKED_SCENE, "info":""}}

	var result: Dictionary = {"code":ImporterResult.OK, "info":""}

	var packed_scene_bundle: Dictionary = p_packed_scene._get_bundled_scene()
	var node_data_array: Array = []
	var node_count: int = packed_scene_bundle["node_count"]

	if node_count > 0:
		var snodes: PackedInt32Array = packed_scene_bundle["nodes"]
		var snode_reader = {"idx": 0, "result": -1}
		for _i in range(0, node_count):
			var nd = NodeData.new()

			snode_reader = reader_snode(snodes, snode_reader)
			if snode_reader.idx != -1:
				nd.parent_id = snode_reader.result
			else:
				result = {"code":ImporterResult.READ_FAIL, "info":"Failed to read parent_id"}
				break

			snode_reader = reader_snode(snodes, snode_reader)
			if snode_reader.idx != -1:
				nd.owner_id = snode_reader.result
			else:
				result = {"code":ImporterResult.READ_FAIL, "info":"Failed to read owner_id"}
				break

			snode_reader = reader_snode(snodes, snode_reader)
			if snode_reader.idx != -1:
				nd.type_id = snode_reader.result
			else:
				result = {"code":ImporterResult.READ_FAIL, "info":"Failed to read type_id"}
				break

			var name_index: int = -1
			snode_reader = reader_snode(snodes, snode_reader)
			if snode_reader.idx != -1:
				name_index = snode_reader.result
				nd.name_id = name_index & ((1 << NAME_INDEX_BITS) - 1)
				nd.index_id = (name_index >> NAME_INDEX_BITS) - 1
			else:
				result = {"code":ImporterResult.READ_FAIL, "info":"Failed to read name_id/index_id"}
				break

			snode_reader = reader_snode(snodes, snode_reader)
			if snode_reader.idx != -1:
				nd.instance_id = snode_reader.result
			else:
				result = {"code":ImporterResult.READ_FAIL, "info":"Faild to read instance_id"}
				break


			var property_count = 0
			snode_reader = reader_snode(snodes, snode_reader)
			if snode_reader.idx != -1:
				property_count = snode_reader.result
			else:
				result = {"code":ImporterResult.READ_FAIL, "info":"Failed to read property_count"}
				break


			for _j in range(0, property_count):
				var name_id: int = -1
				snode_reader = reader_snode(snodes, snode_reader)
				if snode_reader.idx != -1:
					name_id = snode_reader.result
				else:
					result = {"code":ImporterResult.READ_FAIL, "info":"Failed to read name_id"}
					break
					
				var value_id: int = -1
				snode_reader = reader_snode(snodes, snode_reader)
				if snode_reader.idx != -1:
					value_id = snode_reader.result
				else:
					result = {"code":ImporterResult.READ_FAIL, "info":"Failed to read name_id"}
					break
					
				nd.properties.append({"name": name_id, "value": value_id})
				
			if result["code"] != ImporterResult.OK:
				break
			
			var group_count = 0
			snode_reader = reader_snode(snodes, snode_reader)
			if snode_reader.idx != -1:
				group_count = snode_reader.result
				if group_count > 0:
					result = {"code":ImporterResult.HAS_NODE_GROUPS, "info":"Packed scene contains node groups"}
					break
			else:
				result = {"code":ImporterResult.READ_FAIL, "info":"Failed to read group_count"}
				break
			
			
			# Parse groups but don't use them
			for _j in range(0, group_count):
				snode_reader = reader_snode(snodes, snode_reader)
				if snode_reader.idx == -1:
					result = {"code":ImporterResult.READ_FAIL, "info":"Failed to read groups"}
					break
			
			node_data_array.push_back(nd)

	if result["code"] == ImporterResult.OK:
		var ref_root_node : RefNode = build_ref_node_tree(
			node_data_array,
			packed_scene_bundle["names"],
			packed_scene_bundle["variants"],
			packed_scene_bundle["node_paths"],
			packed_scene_bundle["editable_instances"]
		)
		
		if ref_root_node == null:
			result = {
				"code":ImporterResult.FAILED_TO_CREATE_TREE,
				"info":"Could not construct a reference tree from the packed scene bundle"
			}
		else:
			result = scan_ref_node_tree(ref_root_node, false, p_validator)

	var resulting_packed_scene: PackedScene = null
	if result["code"] == ImporterResult.OK:
		resulting_packed_scene = p_packed_scene
		
	if resulting_packed_scene == null:
		push_warning("Validation failure: " + str(result))
	return {"packed_scene":resulting_packed_scene, "result":result}

static func sanitise_packed_scene_for_map(p_packed_scene: PackedScene) -> Dictionary:
	if ProjectSettings.get_setting("ugc/config/sanitize_map_import"):
		print("Sanitising map...")
		var validator: validator_map_const = validator_map_const.new()
		return sanitise_packed_scene(p_packed_scene, validator)
	else:
		push_warning("Map validation is currently disabled.")
		var result: Dictionary = {"code":ImporterResult.OK, "info":""}
		var ret: Dictionary = {"packed_scene":p_packed_scene, "result":result}
		return ret

func sanitise_packed_scene_for_avatar(p_packed_scene: PackedScene) -> Dictionary:
	if ProjectSettings.get_setting("ugc/config/sanitize_avatar_import"):
		print("Sanitising avatar...")
		var validator = validator_avatar_const.new()
		return importer_const.sanitise_packed_scene(p_packed_scene, validator)
	else:
		push_warning("Avatar validation is currently disabled.")
		var result: Dictionary = {"code":ImporterResult.OK, "info":""}
		var ret: Dictionary = {"packed_scene":p_packed_scene, "result":result}
		return ret

func _ready() -> void:
	if !ProjectSettings.has_setting("ugc/config/sanitize_avatar_import"):
		ProjectSettings.set_setting("ugc/config/sanitize_avatar_import", true)
	if !ProjectSettings.has_setting("ugc/config/sanitize_map_import"):
		ProjectSettings.set_setting("ugc/config/sanitize_map_import", true)

func setup() -> void:
	pass
