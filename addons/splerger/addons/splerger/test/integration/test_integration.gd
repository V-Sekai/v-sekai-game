# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# test_integration.gd
# SPDX-License-Identifier: MIT

extends GutTest

var cube : MeshInstance3D
var mesh_count : int = 0
const sperlger_const = preload("res://addons/splerger/split_splerger.gd")


func before_each():
	var cube_mesh = BoxMesh.new()
	cube_mesh.size = Vector3(2, 2, 2) * cube_mesh.get_aabb().size
	cube = MeshInstance3D.new()
	cube.set_mesh(cube_mesh)
	get_tree().get_root().add_child(cube)
	sperlger_const.traverse_root_and_split(cube, 1.0, 1.0)

func teardown():
	cube.queue_free()

func test_cube_mesh_count():
	for child in cube.get_children():
		if child is MeshInstance3D:
			mesh_count += 1
	assert_eq(mesh_count, 1, "Cube should only have one mesh")

func test_assert_eq_integration_string_equal():
	assert_eq("Integration", "Integration", "Should pass")
