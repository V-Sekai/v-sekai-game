# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# node_util.gd
# SPDX-License-Identifier: MIT

@tool
extends Node


static func find_nodes_in_group(p_group: String, p_node: Node) -> Array:
	var valid_nodes: Array = Array()

	for group in p_node.get_groups():
		if p_group == group:
			valid_nodes.push_back(p_node)

	for child in p_node.get_children():
		var valid_child_nodes: Array = find_nodes_in_group(p_group, child)
		for valid_child_node in valid_child_nodes:
			valid_nodes.push_back(valid_child_node)

	return valid_nodes


static func set_relative_global_transform(p_root: Node3D, p_node3d: Node3D, p_gt: Transform3D) -> void:
	if p_node3d.get_parent() == p_root:
		p_node3d.set_transform(p_gt)
	else:
		p_node3d.set_transform(get_relative_global_transform(p_root, p_node3d.get_parent()).affine_inverse() * p_gt)


static func get_relative_global_transform(p_root: Node3D, p_node3d: Node3D) -> Transform3D:
	var parent: Node3D = p_node3d.get_parent()
	if parent and parent != p_root:
		return get_relative_global_transform(p_root, parent) * p_node3d.transform
	else:
		return p_node3d.transform
