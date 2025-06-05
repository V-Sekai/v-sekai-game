# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_editor_dashboard_dialog_control.gd
# SPDX-License-Identifier: MIT

@tool
extends Control
class_name VSKEditorDashboardDialogControl

var vsk_editor: Node = null

const MARGIN_SIZE = 32

func _ready():
	pass
	#var avatars_grid_node: Control = get_node_or_null(avatars_grid)
	#if avatars_grid_node:
	#	if avatars_grid_node.vsk_content_button_pressed.connect(self._avatar_selected) != OK:
	#		push_error("Could not connect signal 'vsk_content_button_pressed'")

	#var maps_grid_node: Control = get_node_or_null(maps_grid)
	#if maps_grid_node:
	#	if maps_grid_node.vsk_content_button_pressed.connect(self._map_selected) != OK:
	#		push_error("Could not connect signal 'vsk_content_button_pressed'")


func _avatar_selected(p_id: String) -> void:
	pass
	#if avatar_dictionary.has(p_id):
	#	DisplayServer.clipboard_set(p_id)
	#else:
	#	push_error("Could not select avatar %s" % p_id)


func _map_selected(p_id: String) -> void:
	pass
	#if map_dictionary.has(p_id):
	#	DisplayServer.clipboard_set(p_id)
	#else:
	#	push_error("Could not select map %s" % p_id)


func _on_tab_changed(tab):
	pass
	#var tab_child: Control = get_node(tab_container).get_child(tab)
	#if tab_child == get_node(profile_tab):
	#	pass
	#elif tab_child == get_node(avatars_tab):
	#	await _reload_avatars()
	#elif tab_child == get_node(maps_tab):
	#	await _reload_maps()

func set_vsk_editor(p_vsk_editor: Node) -> void:
	vsk_editor = p_vsk_editor
	
