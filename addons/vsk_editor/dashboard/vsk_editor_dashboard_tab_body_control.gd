# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_editor_dashboard_tab_body_control.gd
# SPDX-License-Identifier: MIT

@tool
extends Control
class_name VSKEditorDashboardTabBodyControl

func _get_uro_service() -> VSKGameServiceUro:
	var service_manager: VSKGameServiceManager = get_tree().get_first_node_in_group("game_service_managers")
	if service_manager:
		var service: VSKGameServiceUro = service_manager.get_service("Uro")
		return service
		
	return null
