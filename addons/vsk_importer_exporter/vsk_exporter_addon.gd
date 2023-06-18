# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_exporter_addon.gd
# SPDX-License-Identifier: MIT

@tool
extends RefCounted


func preprocess_scene(p_node: Node, _p_validator: RefCounted) -> Node:
	return p_node


func get_name() -> String:
	return "UnnamedAddon"
