# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# viewport_manager.gd
# SPDX-License-Identifier: MIT

@tool
extends Node


func create_viewport(p_name):
	var viewport = SubViewport.new()
	viewport.set_name(p_name)
	add_child(viewport, true)

	return viewport
