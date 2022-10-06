@tool
extends Node

const node_util_const = preload("res://addons/gd_util/node_util.gd")

# Returns true if this node is a valid physics node
static func is_valid_physics_node(p_node: Node) -> bool:
	if p_node is CollisionShape3D:
		return true
	return false

# Returns true if this node is a valid visual node
static func is_valid_visual_node(p_node: Node) -> bool:
	if p_node is VisualInstance3D:
		if p_node is GeometryInstance3D:
			if p_node is MeshInstance3D:
				return true
	return false

# Recursively walks a node and its children returning the dictionary passed in
# as the argument with the valid nodes appended to it
static func recursive_node_walk(p_node: Node, p_model_node_lists: Dictionary) -> Dictionary:
	if is_valid_visual_node(p_node):
		p_model_node_lists["visual"].push_back(p_node)
	if is_valid_physics_node(p_node):
		p_model_node_lists["physics"].push_back(p_node)

	for child in p_node.get_children():
		p_model_node_lists = recursive_node_walk(child, p_model_node_lists)

	return p_model_node_lists

# Returns a dictionary containing lists of valid nodes required to construct
# a model tree
static func get_valid_node_list(p_root_node: Node3D) -> Dictionary:
	var model_node_lists = {"visual": [], "physics": []}

	model_node_lists = recursive_node_walk(p_root_node, model_node_lists)

	return model_node_lists

# Returns a dictionary containing nodes required for a valid model tree
static func build_model_trees(p_root_node: Node3D) -> Dictionary:
	var model_node_trees = {"visual": null, "physics": null}

	var visual: Array = []
	var physics: Array = []

	var model_node_lists = get_valid_node_list(p_root_node)

	for visual_node in model_node_lists.visual:
		var transform: Transform3D = node_util_const.get_relative_global_transform(
			p_root_node, visual_node
		)
		var parent :Node = visual_node.get_parent()
		if parent != null:
			for child in visual_node.get_children():
				visual_node.remove_child(child)
				parent.add_child(child)
				child.owner = parent.owner
			parent.remove_child(visual_node)
		visual_node.transform = transform
		visual.push_back(visual_node)

	for physics_node in model_node_lists.physics:
		var transform: Transform3D = node_util_const.get_relative_global_transform(
			p_root_node, physics_node
		)
		var parent :Node = physics_node.get_parent()
		if parent != null:
			for child in physics_node.get_children():
				physics_node.remove_child(child)
				parent.add_child(child)
				child.owner = parent.owner
			parent.remove_child(physics_node)
		physics_node.transform = transform
		physics.push_back(physics_node)

	model_node_trees.visual = visual
	model_node_trees.physics = physics

	p_root_node.queue_free()

	return model_node_trees
