# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# outgame_root_vr.gd
# SPDX-License-Identifier: MIT

extends Node3D

@export var origin_nodepath: NodePath = NodePath()


func get_origin() -> XROrigin3D:
	var origin: XROrigin3D = get_node_or_null(origin_nodepath)
	if origin:
		return origin
	else:
		return null
