# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# entity_manager_functions.gd
# SPDX-License-Identifier: MIT

@tool
class_name EntityManagerFunctions extends Node


static func check_if_dependency_is_cyclic(p_root_entity: Node, p_current_enity: Node, p_is_root: bool) -> bool:
	var is_cyclic: bool = false

	for strong_exclusive_dependency in p_current_enity.strong_exclusive_dependencies:
		is_cyclic = check_if_dependency_is_cyclic(p_root_entity, strong_exclusive_dependency, false)

	if !p_is_root and p_root_entity == p_current_enity:
		is_cyclic = true

	return is_cyclic
