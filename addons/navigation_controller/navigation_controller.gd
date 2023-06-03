# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# navigation_controller.gd
# SPDX-License-Identifier: MIT

@tool
class_name NavigationController extends "res://addons/navigation_controller/view_controller.gd"

var blocking: bool = false
var view_controller_stack: Array = []

var current_view_node: Control = null


static func is_navigation_controller() -> bool:
	return true


func _input(_event: InputEvent) -> void:
	if blocking:
		get_viewport().set_input_as_handled()


func set_input_blocking(p_blocking: bool) -> void:
	blocking = p_blocking
	if blocking:
		mouse_filter = Control.MOUSE_FILTER_STOP
	else:
		mouse_filter = Control.MOUSE_FILTER_PASS


func get_top_view_controller() -> Node:  # -> ViewController:
	return view_controller_stack.front()


func clear_view_node(p_view_node: Control, p_delete: bool) -> void:
	for child in p_view_node.get_children():
		if child and child is ViewController:
			child.will_disappear()
		if p_delete:
			child.queue_free()
		current_view_node.remove_child(child)


func push_view_controller(p_view_controller: Control, p_animated: bool) -> void:
	if p_animated:
		pass

	view_controller_stack.push_front(p_view_controller)

	clear_view_node(current_view_node, false)

	if p_view_controller and p_view_controller is ViewController:
		p_view_controller.will_appear()
	current_view_node.add_child(get_top_view_controller(), true)


func pop_view_controller(p_animated: bool) -> void:
	if p_animated:
		pass

	clear_view_node(current_view_node, true)

	if !view_controller_stack.is_empty():
		view_controller_stack.pop_front()
		if !view_controller_stack.is_empty():
			current_view_node.add_child(get_top_view_controller(), true)
	else:
		printerr("Tried to pop root view controller")


func clear_view_controller_stack() -> void:
	while !view_controller_stack.is_empty():
		pop_view_controller(false)


func get_view_controllers() -> Array:
	return view_controller_stack


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PREDELETE:
			for view_controller in view_controller_stack:
				if is_instance_valid(view_controller):
					view_controller.queue_free()


func _init():
	current_view_node = Control.new()
	current_view_node.set_anchors_and_offsets_preset(PRESET_FULL_RECT, PRESET_MODE_MINSIZE)
	current_view_node.set_name("Current")
	current_view_node.set_mouse_filter(MOUSE_FILTER_IGNORE)

	add_child(current_view_node, true)
