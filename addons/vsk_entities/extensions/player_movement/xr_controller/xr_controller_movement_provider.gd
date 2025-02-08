# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# xr_controller_movement_provider.gd
# SPDX-License-Identifier: MIT

extends Node

var _player_movement_controller: Node = null
var _origin: XROrigin3D = null

# Controller node
@onready var _controller: XRController3D = get_parent()


func _ready():
	if not _controller:
		push_error("Could not find '_controller' at xr_controller_movement_provider")
		return
	_origin = _controller.get_parent()
	if not _origin:
		push_error("Could not find '_origin' at xr_controller_movement_provider")
		return
	_player_movement_controller = _origin.player_movement_controller
