# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# view_controller.gd
# SPDX-License-Identifier: MIT

@tool
class_name ViewController extends Control

const script_util_const = preload("res://addons/gd_util/script_util.gd")

var navigation_controller = null:
	set = set_navigation_controller,
	get = get_navigation_controller


static func is_navigation_controller() -> bool:
	return false


func will_appear() -> void:
	pass


func will_disappear() -> void:
	pass


func set_navigation_controller(p_navigation_controller) -> void:
	navigation_controller = p_navigation_controller


func get_navigation_controller():
	return navigation_controller


func has_navigation_controller() -> bool:
	return navigation_controller != null


func update_navigation_controller() -> void:
	var control: Control = self
	while control:
		if control != self:
			if script_util_const.does_script_inherit(control.get_script(), script_util_const.get_root_script(get_script())):
				if control.has_method("is_navigation_controller"):
					if control.is_navigation_controller():
						set_navigation_controller(control)
						break

		control = control.get_parent() as Control


func _enter_tree() -> void:
	update_navigation_controller()
	if navigation_controller:
		set_anchors_and_offsets_preset(PRESET_FULL_RECT, PRESET_MODE_MINSIZE)


func _ready() -> void:
	update_navigation_controller()
	if navigation_controller:
		set_anchors_and_offsets_preset(PRESET_FULL_RECT, PRESET_MODE_MINSIZE)
