# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vr_render_tree.gd
# SPDX-License-Identifier: MIT

extends Node3D

var tree: Node3D = null


func create_attachment_point(p_name: String) -> Node3D:
	var attachment: Node3D = Node3D.new()
	attachment.set_name(p_name)
	var attachment_attach = Node3D.new()
	attachment_attach.set_name("attach")
	attachment.add_child(attachment_attach, true)
	return attachment


func setup_dummy_attachment(p_name: StringName) -> Node3D:
	var spatial: Node3D = create_attachment_point(p_name)
	spatial.translate(Vector3(0.0, -0.01, 0.05))
	spatial.rotate_x(deg_to_rad(-45))

	return spatial


func load_render_tree(p_vrmanager: Node, p_name: String) -> bool:
	var result: bool = false
	var controller_name: String = p_name.substr(0, p_name.length() - 2)

	if tree:
		tree.queue_free()
		tree.get_parent().remove_child(tree)
		tree = null

	tree = Node3D.new()

	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	mesh_instance.set_name("mesh")
	tree.add_child(mesh_instance)

	var render_mesh: Mesh = null
	var render_cache = p_vrmanager.get_render_cache()

	if render_cache:
		render_mesh = render_cache.get_render_mesh(controller_name)

	if render_mesh != null:
		mesh_instance.set_mesh(render_mesh)

	# Create dummy attachments
	tree.add_child(setup_dummy_attachment("base"))
	tree.add_child(setup_dummy_attachment("handgrip"))
	tree.add_child(setup_dummy_attachment("tip"))

	result = true
	if tree:
		tree.set_name("RenderTree")
		add_child(tree)

	return result


func get_attachment_point(p_name: StringName) -> Node3D:
	if tree:
		if tree.has_node(NodePath(p_name)):
			var render_mesh_instance = tree.get_node(NodePath(p_name))
			if render_mesh_instance.has_node("attach"):
				return render_mesh_instance.get_node("attach")

	return null


func update_render_tree() -> void:
	if tree and tree.has_method("update_tree"):
		tree.update_tree()


func _init() -> void:
	pass
