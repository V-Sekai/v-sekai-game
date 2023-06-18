# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# create_server.gd
# SPDX-License-Identifier: MIT

extends "res://addons/vsk_menu/menu_view_controller.gd"  # menu_view_controller.gd

var loading_screen = load("res://addons/vsk_menu/main_menu/loading_screen.tscn")

@export var host_button_nodepath: NodePath = NodePath()
@export var max_players_input_nodepath: NodePath = NodePath()
@export var port_input_nodepath: NodePath = NodePath()
@export var map_browse_line_edit_nodepath: NodePath = NodePath()
@export var map_browse_button_nodepath: NodePath = NodePath()
@export var server_name_nodepath: NodePath = NodePath()
@export var dedicated_server_toggle_nodepath: NodePath = NodePath()
@export var public_server_toggle_nodepath: NodePath = NodePath()

var host_button = null
var max_players_input = null
var port_input = null
var map_browse_line_edit = null
var map_browse_button = null
var server_name_line_edit = null
var dedicated_server_toggle = null
var public_server_toggle = null


func _ready():
	server_name_line_edit = get_node_or_null(server_name_nodepath)
	host_button = get_node_or_null(host_button_nodepath)
	max_players_input = get_node_or_null(max_players_input_nodepath)
	port_input = get_node_or_null(port_input_nodepath)
	map_browse_line_edit = get_node_or_null(map_browse_line_edit_nodepath)
	map_browse_button = get_node_or_null(map_browse_button_nodepath)
	dedicated_server_toggle = get_node_or_null(dedicated_server_toggle_nodepath)
	public_server_toggle = get_node_or_null(public_server_toggle_nodepath)

	port_input.value = float(ProjectSettings.get_setting("network/config/default_port"))

	if server_name_line_edit:
		server_name_line_edit.text = VSKNetworkManager.DEFAULT_SERVER_NAME

	if $MapSelectorPopup.path_selected.connect(self._map_path_selected) != OK:
		push_error("Failed to connect path_selected signal.")
		return


func _gameflow_state_changed(p_gameflow_state: int):
	if p_gameflow_state == VSKGameFlowManager.GAMEFLOW_STATE_INTERSTITIAL:
		get_navigation_controller().push_view_controller(loading_screen.instantiate() as ViewController, true)


func will_appear() -> void:
	if VSKGameFlowManager.gameflow_state_changed.connect(self._gameflow_state_changed) != OK:
		printerr("Could not connect gameflow_state_changed!")


func will_disappear() -> void:
	if VSKGameFlowManager.gameflow_state_changed.is_connected(self._gameflow_state_changed):
		VSKGameFlowManager.gameflow_state_changed.disconnect(self._gameflow_state_changed)


func _map_path_selected(p_path: String) -> void:
	map_browse_line_edit.set_text(p_path)


func set_controls_disabled(p_disabled: bool) -> void:
	host_button.set_disabled(p_disabled)

	max_players_input.set_editable(!p_disabled)
	port_input.set_editable(!p_disabled)

	map_browse_line_edit.set_editable(!p_disabled)
	map_browse_button.set_disabled(p_disabled)

	dedicated_server_toggle.set_disabled(p_disabled)
	public_server_toggle.set_disabled(p_disabled)


var host_server_callable = VSKGameFlowManager.host_server


func _on_HostButton_pressed() -> void:
	var next_map_path: String = ""
	var next_game_mode_path: String = VSKGameModeManager.DEFAULT_GAME_MODE_PATH

	if map_browse_line_edit.text == "":
		next_map_path = VSKMapManager.get_default_map_path()
	else:
		next_map_path = map_browse_line_edit.text

	host_server_callable.call_deferred(server_name_line_edit.text, next_map_path, next_game_mode_path, int(port_input.value), int(max_players_input.value), dedicated_server_toggle.button_pressed, public_server_toggle.button_pressed, VSKNetworkManager.DEFAULT_MAX_RETRIES)


func _on_BackButton_pressed():
	super.back_button_pressed()


func _on_map_browse_button_pressed() -> void:
	$MapSelectorPopup.popup_centered_ratio()
