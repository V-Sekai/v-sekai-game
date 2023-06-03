# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_user_content_grid_item.gd
# SPDX-License-Identifier: MIT

@tool
extends Control

signal vsk_content_button_pressed(id)

@export var name_label_path: NodePath = NodePath()
@export var texture_rect_url_path: NodePath = NodePath()

var id: String = ""
var vsk_name: String = ""
var vsk_url: String = ""
var is_ready: bool = false


func set_id(p_id: String) -> void:
	id = p_id


func set_content_name(p_name: String) -> void:
	vsk_name = p_name
	var label: Label = get_node_or_null(name_label_path)
	if label:
		if p_name.is_empty():
			label.set_text(" ")
		else:
			label.set_text(vsk_name)


func set_url(p_url: String) -> void:
	vsk_url = p_url
	var texture_rect: TextureRect = get_node_or_null(texture_rect_url_path)
	if texture_rect and self.is_ready:
		texture_rect.textureUrl = p_url


func _ready():
	is_ready = true
	set_content_name(vsk_name)
	set_url(vsk_url)


func _on_pressed():
	vsk_content_button_pressed.emit(id)
