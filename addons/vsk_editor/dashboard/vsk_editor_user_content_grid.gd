# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_editor_user_content_grid.gd
# SPDX-License-Identifier: MIT

@tool
extends Control
class_name VSKEditorUserContentGrid

signal vsk_content_button_pressed(p_id: String)

@export var grid_container: VSKEditorResponsiveGridContainer = null

const vsk_user_content_item_const = preload("vsk_editor_user_content_grid_item.tscn")


func _vsk_content_button_pressed(p_id: String) -> void:
	vsk_content_button_pressed.emit(p_id)


func add_item(p_id: String, p_name: String, p_url: String) -> void:
	var vsk_user_content_item: Control = vsk_user_content_item_const.instantiate()
	
	vsk_user_content_item.name = "UserContent_" + p_id.replace("/", "")
	vsk_user_content_item.set_id(p_id)
	vsk_user_content_item.set_content_name(p_name)
	vsk_user_content_item.set_url(p_url)
	
	if (
		vsk_user_content_item.vsk_content_button_pressed.connect(self._vsk_content_button_pressed)
		!= OK
	):
		push_error("Could not connect 'vsk_content_button_pressed'")
		
	if grid_container:
		grid_container.add_child(vsk_user_content_item, true)


func clear_all() -> void:
	if grid_container:
		for child in grid_container.get_children():
			child.queue_free()
			child.get_parent().remove_child(child)


func _on_scroll_ended():
	pass
