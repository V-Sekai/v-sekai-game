# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# player_teleport_controller.gd
# SPDX-License-Identifier: MIT

extends Node

var player_controller: Node = null

var teleport_flag: bool = false
var teleport_transform: Transform3D = Transform3D()


func _respawn() -> void:
	teleport_to(VSKNetworkManager.get_random_spawn_transform())


func check_respawn_bounds() -> void:
	if player_controller.get_global_origin().y < VSKMapManager.RESPAWN_HEIGHT:
		_respawn()


func _teleport_to_internal(p_transform: Transform3D) -> void:
	player_controller.set_global_transform(p_transform, true)


func teleport_to(p_transform: Transform3D) -> void:
	teleport_flag = true
	teleport_transform = p_transform


func can_teleport() -> bool:
	return true


func check_teleport() -> void:
	if InputManager.is_ingame_action_just_pressed("respawn"):
		_respawn()

	if teleport_flag:
		_teleport_to_internal(teleport_transform)
		player_controller._target_smooth_node.teleport()
		teleport_flag = false


func setup(p_player_controller: Node) -> void:
	player_controller = p_player_controller

	# Teleport callback
	var teleport: Node3D = VRManager.xr_origin.get_component_by_name("TeleportComponent")
	if teleport:
		teleport.assign_can_teleport_funcref(self, "can_teleport")
		teleport.assign_teleport_callback_funcref(self, "teleport_to")
