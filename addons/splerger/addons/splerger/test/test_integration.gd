# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# test_integration.gd
# SPDX-License-Identifier: MIT

extends GutTest

var root : Node3D
var mesh_count : int = 0
const sperlger_const = preload("res://addons/splerger/split_splerger.gd")


func before_each():
	root = Node3D.new()
	sperlger_const.save_scene(root, "res://packed_scene.tscn")
	var cube_mesh = BoxMesh.new()
	cube_mesh.size = Vector3(4, 4, 4) * cube_mesh.get_aabb().size
	var cube = MeshInstance3D.new()
	root.add_child(cube, true)
	cube.owner = root
	cube.set_mesh(cube_mesh)

func after_each():
	root.queue_free()

func test_cube_mesh_count():
	sperlger_const.traverse_root_and_split(root, 0.5, 0.5)
	root.get_child(0).queue_free()
	for child: MeshInstance3D in root.find_children("*", "MeshInstance3D"):
		mesh_count += 1
	sperlger_const.save_scene(root, "res://packed_scene.tscn")
	assert_eq(mesh_count, 1, "Cube should only have one mesh")
