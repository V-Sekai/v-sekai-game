# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# runtime_avatar_checker.gd
# SPDX-License-Identifier: MIT

extends Node


static func get_runtime_info_mesh(p_mesh: Mesh, p_dictionary: Dictionary = {}) -> Dictionary:
	p_dictionary["MeshCount"] += 1

	var surface_count: int = p_mesh.get_surface_count()

	return p_dictionary


static func get_runtime_avatar_info_for_node(p_node: Node, p_dictionary: Dictionary = {}) -> Dictionary:
	if p_node is MeshInstance3D:
		p_dictionary["MeshInstance3DCount"] += 1
		if p_node.skin:
			p_dictionary["MeshInstance3DWithSkinCount"] += 1

	if p_node is GPUParticles3D:
		p_dictionary["ParticleEmitterCount"] += 1

	if p_node is CPUParticles3D:
		p_dictionary["CPUParticleEmitterCount"] += 1

	for node in p_node.get_children():
		p_dictionary = get_runtime_avatar_info_for_node(p_node, p_dictionary)

	return p_dictionary
