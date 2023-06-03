# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# sprite_gizmo.gd
# SPDX-License-Identifier: MIT

@tool
extends EditorNode3DGizmo

const immediate_shape_util_const = preload("immediate_shape_util.gd")

var plugin = null
var texture = Texture.new()


func get_handle_name(p_idx: int) -> String:
	return ""


func get_handle_value(p_idx: int) -> int:
	return 0


func set_handle(p_idx, p_spatial, p_point):
	pass


func commit_handle(index, restore, cancel = false):
	pass


func redraw():
	clear()
	var icon_material: Material = immediate_shape_util_const.create_icon_material(texture, Color())
	add_unscaled_billboard(icon_material, 0.05)


func _init(p_plugin, p_texture):
	texture = p_texture
	plugin = p_plugin
