# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# setup_menu.gd
# SPDX-License-Identifier: MIT

extends "res://addons/vsk_menu/menu_view_controller.gd"  # menu_view_controller.gd

@export var restart_notification_nodepath: NodePath = NodePath()


static func update_menu_button_text(p_menu_button: MenuButton, p_value: int, p_names: PackedStringArray):
	if p_value < p_names.size() and p_value >= 0:
		p_menu_button.set_text(p_names[p_value])
	else:
		p_menu_button.set_text("")


static func setup_menu_button(p_menu_button: MenuButton, p_value: int, p_names: PackedStringArray):
	update_menu_button_text(p_menu_button, p_value, p_names)

	var popup: PopupMenu = p_menu_button.get_popup()
	for i in range(0, p_names.size()):
		popup.add_item(TranslationServer.translate(p_names[i]), i)


func unindicate_restart_required() -> void:
	var restart_notificaiton = get_node_or_null(restart_notification_nodepath)
	if restart_notificaiton is Label:
		restart_notificaiton.visible_characters = 0


func indicate_restart_required() -> void:
	var restart_notificaiton = get_node_or_null(restart_notification_nodepath)
	if restart_notificaiton is Label:
		restart_notificaiton.visible_characters = -1


func save_changes() -> void:
	pass


func _on_BackButton_pressed() -> void:
	save_changes()
	super.back_button_pressed()
