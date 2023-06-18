# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# join_server.gd
# SPDX-License-Identifier: MIT

extends "res://addons/vsk_menu/menu_view_controller.gd"  # menu_view_controller.gd

var loading_screen = load("res://addons/vsk_menu/main_menu/loading_screen.tscn")

@export var join_button_nodepath: NodePath = NodePath()
@export var ip_input_nodepath: NodePath = NodePath()
@export var port_input_nodepath: NodePath = NodePath()

var join_button = null
var ip_input = null
var port_input = null


func _ready():
	join_button = get_node(join_button_nodepath)
	ip_input = get_node(ip_input_nodepath)
	port_input = get_node(port_input_nodepath)

	ip_input.set_text(NetworkManager.network_constants_const.LOCALHOST_IP)
	port_input.set_value(NetworkManager.default_port)


func _gameflow_state_changed(p_gameflow_state: int):
	if p_gameflow_state == VSKGameFlowManager.GAMEFLOW_STATE_INTERSTITIAL and loading_screen is ViewController:
		get_navigation_controller().push_view_controller(loading_screen.instantiate(), true)


func will_appear() -> void:
	if VSKGameFlowManager.gameflow_state_changed.connect(self._gameflow_state_changed) != OK:
		printerr("Could not connect gameflow_state_changed!")


func will_disappear() -> void:
	if VSKGameFlowManager.gameflow_state_changed.is_connected(self._gameflow_state_changed):
		VSKGameFlowManager.gameflow_state_changed.disconnect(self._gameflow_state_changed)


func set_controls_disabled(p_disabled: bool) -> void:
	join_button.set_disabled(p_disabled)

	ip_input.set_editable(!p_disabled)
	port_input.set_editable(!p_disabled)


var join_server_callable: Callable = VSKGameFlowManager.join_server


func _on_JoinButton_pressed() -> void:
	set_controls_disabled(true)
	join_server_callable.call_deferred(ip_input.text, round(port_input.value))


func _on_BackButton_pressed():
	super.back_button_pressed()
