# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# spatial_game_viewport_manager.gd
# SPDX-License-Identifier: MIT

@tool
extends Node

var spatial_game_viewport: SubViewport = null
var spatial_secondary_viewport: SubViewport = null

signal viewport_updated(p_viewport)


func update_viewports() -> void:
	if spatial_game_viewport:
		_update_viewport(spatial_game_viewport, VRManager.is_xr_active())

	if spatial_secondary_viewport:
		_update_viewport(spatial_secondary_viewport, false)


func _update_viewport(p_viewport: SubViewport, p_use_vr: bool) -> void:
	p_viewport.use_xr = p_use_vr

	if p_use_vr:
		p_viewport.size = VRManager.xr_interface.get_render_target_size()
	else:
		p_viewport.size = DisplayServer.window_get_size(0)

	# msaa is broken in XR + Forward Clustered 2022-05-18 # p_viewport.msaa = GraphicsManager.msaa
	p_viewport.audio_listener_enable_2d = true
	p_viewport.audio_listener_enable_3d = true

	viewport_updated.emit(p_viewport)


func create_spatial_secondary_viewport() -> SubViewport:
	if spatial_secondary_viewport:
		printerr("SpatialGameCameraViewport has already been created")
		return spatial_secondary_viewport

	spatial_secondary_viewport = SubViewport.new()
	spatial_secondary_viewport.name = "SecondaryViewport"

	spatial_secondary_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS

	return spatial_secondary_viewport


func create_spatial_game_viewport() -> SubViewport:
	if spatial_game_viewport:
		printerr("SpatialGameViewport has already been created!")
		return spatial_game_viewport

	spatial_game_viewport = SubViewport.new()
	spatial_game_viewport.name = "GameViewport"
	spatial_game_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS

	return spatial_game_viewport


func _ready() -> void:
	if !Engine.is_editor_hint():
		var viewport_result = get_viewport().size_changed.connect(self.update_viewports)
		if viewport_result != OK:
			print("Failed to connect size_changed signal")
			return

		var graphics_result = GraphicsManager.graphics_changed.connect(self.update_viewports)
		if graphics_result != OK:
			print("Failed to connect graphics_changed signal")
			return

		var xr_result = VRManager.xr_mode_changed.connect(self.update_viewports)
		if xr_result != OK:
			print("Failed to connect xr_mode_changed signal")
			return
