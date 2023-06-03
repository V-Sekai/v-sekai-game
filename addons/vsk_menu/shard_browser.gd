# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# shard_browser.gd
# SPDX-License-Identifier: MIT

extends "res://addons/vsk_menu/setup_menu.gd"  # setup_menu.gd

var loading_screen = load("res://addons/vsk_menu/main_menu/loading_screen.tscn")
var shard_button_tscn = load("res://addons/vsk_menu/main_menu/shard_button.tscn")
var join_server = load("res://addons/vsk_menu/main_menu/join_server.tscn")

var shard_list_callback: RefCounted = RefCounted.new()

@export var shard_list_nodepath: NodePath = NodePath()
var shard_list: BoxContainer = null

@export var shard_browser_nodepath: NodePath = NodePath()
var shard_browser: Control = null

@export var info_label_nodepath: NodePath = NodePath()
var info_label: Label = null

@export var refresh_button_nodepath: NodePath = NodePath()
var refresh_button: Button = null

var found_servers: Array = []


func _gameflow_state_changed(p_gameflow_state: int):
	if p_gameflow_state == VSKGameFlowManager.GAMEFLOW_STATE_INTERSTITIAL:
		get_navigation_controller().push_view_controller(loading_screen.instantiate(), true)


func shard_button_pressed(p_button) -> void:
	print("Joining shard button: " + str(p_button.address) + ":" + str(p_button.port))
	VSKGameFlowManager.join_server(p_button.address, p_button.port)


func _shard_list_callback(p_shard_list_callback: Dictionary) -> void:
	if p_shard_list_callback.result == OK:
		var shards: Array = p_shard_list_callback.data.shards
		for shard in shards:
			var shard_button = shard_button_tscn.instantiate()
			shard_button.set_name("Shard")

			shard_button["address"] = shard.address
			shard_button["port"] = shard.port
			shard_button["map"] = shard.map
			shard_button["server_name"] = shard.name
			shard_button["current_users"] = shard.current_users
			shard_button["max_users"] = shard.max_users

			shard_button.connect("pressed", self.shard_button_pressed.bind(shard_button))
			shard_list.add_child(shard_button, true)
	else:
		info_label.set_text("Failed...")

	refresh_complete()


func _ready() -> void:
	shard_list = get_node_or_null(shard_list_nodepath)
	shard_browser = get_node_or_null(shard_browser_nodepath)
	info_label = get_node_or_null(info_label_nodepath)
	refresh_button = get_node_or_null(refresh_button_nodepath)

	refresh()


func will_appear() -> void:
	if VSKGameFlowManager.gameflow_state_changed.connect(self._gameflow_state_changed) != OK:
		printerr("Could not connect gameflow_state_changed!")


func will_disappear() -> void:
	if VSKGameFlowManager.gameflow_state_changed.is_connected(self._gameflow_state_changed):
		VSKGameFlowManager.gameflow_state_changed.disconnect(self._gameflow_state_changed)


func refresh() -> void:
	info_label.set_text("Searching...")

	refresh_button.disabled = true
	shard_browser.hide()
	info_label.show()

	for server_button in shard_list.get_children():
		server_button.queue_free()
		shard_list.remove_child(server_button)

	if VSKShardManager.shard_list_callback.connect(self._shard_list_callback, CONNECT_ONE_SHOT) != OK:
		push_error("Failed to connect shard_list_callback signal")
		return

	VSKShardManager.show_shards(shard_list_callback)


func refresh_complete() -> void:
	refresh_button.disabled = false
	shard_browser.show()
	info_label.hide()


func _on_RefreshButton_pressed():
	refresh()


func _on_DirectIPButton_pressed():
	get_navigation_controller().push_view_controller(join_server.instantiate(), true)


func _on_BackButton_pressed() -> void:
	save_changes()
	super.back_button_pressed()
