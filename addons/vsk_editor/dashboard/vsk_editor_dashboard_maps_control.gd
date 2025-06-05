# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_editor_dashboard_maps_control.gd
# SPDX-License-Identifier: MIT

@tool
extends VSKEditorDashboardContentControl
class_name VSKEditorDashboardMapsControl

func _fetch_content(p_service: VSKGameServiceUro, p_username: String, p_domain: String) -> Dictionary:
	_fetch_request = p_service.create_request({"username":p_username, "domain":p_domain})
	var async_result: Dictionary = await p_service.get_dashboard_maps_async(_fetch_request)
	return async_result
