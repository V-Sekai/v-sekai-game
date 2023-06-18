# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vr_render_cache.gd
# SPDX-License-Identifier: MIT

const vr_render_tree_const = preload("vr_render_tree.gd")

var render_mesh_cache: Dictionary = {}


func add_render_mesh(p_mesh_name: String, p_render_mesh: Mesh) -> Mesh:
	if !render_mesh_cache.has(p_mesh_name):
		render_mesh_cache[p_mesh_name] = p_render_mesh
		return p_render_mesh
	printerr("vr_render_cache: attempted to add duplicate render mesh")
	return null


func get_render_mesh(p_mesh_name: String) -> Mesh:
	if render_mesh_cache.has(p_mesh_name):
		return render_mesh_cache[p_mesh_name]
	return null
