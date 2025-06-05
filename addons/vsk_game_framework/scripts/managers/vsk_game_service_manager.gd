# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_game_session_manager.gd
# SPDX-License-Identifier: MIT

@tool
extends SarGameServiceManager
class_name VSKGameServiceManager

func _enter_tree() -> void:
	add_service(VSKGameServiceUro.get_service_name(), VSKGameServiceUro)
	add_to_group("game_service_managers")
	
func _exit_tree() -> void:
	remove_service(VSKGameServiceUro.get_service_name())
