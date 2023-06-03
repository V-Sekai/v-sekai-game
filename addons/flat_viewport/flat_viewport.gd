# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# flat_viewport.gd
# SPDX-License-Identifier: MIT

@tool
extends Control

const flat_viewport_const = preload("flat_viewport.gdshader")
var texture_rect_ingame: TextureRect = null
var texture_rect_menu: TextureRect = null

signal menu_gui_input(p_event)


func emit_menu_gui_input(p_event: InputEvent) -> void:
	menu_gui_input.emit(p_event)


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 0)
	set_focus_mode(FOCUS_NONE)
	set_mouse_filter(MOUSE_FILTER_IGNORE)

	if !Engine.is_editor_hint():
		texture_rect_ingame = TextureRect.new()
		texture_rect_ingame.set_name("TextureRect")
		texture_rect_ingame.set_focus_mode(FOCUS_NONE)
		texture_rect_ingame.size_flags_horizontal = TextureRect.SIZE_EXPAND
		texture_rect_ingame.size_flags_vertical = TextureRect.SIZE_EXPAND
		texture_rect_ingame.set_mouse_filter(MOUSE_FILTER_IGNORE)
		texture_rect_ingame.set_flip_v(false)
		texture_rect_ingame.set_stretch_mode(TextureRect.STRETCH_KEEP_ASPECT_COVERED)

		var shader_material: ShaderMaterial = ShaderMaterial.new()
		shader_material.shader = flat_viewport_const
		var hack = shader_material
		texture_rect_ingame.material = hack

		add_child(texture_rect_ingame, true)
		texture_rect_ingame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 0)

		##
		texture_rect_menu = TextureRect.new()
		texture_rect_menu.set_name("OverlayRoot")
		texture_rect_menu.set_focus_mode(FOCUS_NONE)
		texture_rect_menu.set_mouse_filter(MOUSE_FILTER_PASS)
		texture_rect_menu.size_flags_horizontal = TextureRect.SIZE_EXPAND
		texture_rect_menu.size_flags_vertical = TextureRect.SIZE_EXPAND
		texture_rect_menu.set_flip_v(false)
		texture_rect_menu.set_stretch_mode(TextureRect.STRETCH_SCALE)

		if texture_rect_menu.gui_input.connect(self.emit_menu_gui_input) != OK:
			printerr("Could could connect gui_input signal!")

		add_child(texture_rect_menu, true)
		texture_rect_menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 0)
