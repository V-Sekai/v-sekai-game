# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# title_screen.gd
# SPDX-License-Identifier: MIT

extends "res://addons/vsk_menu/menu_view_controller.gd"  # menu_view_controller.gd

var shard_browser = load("res://addons/vsk_menu/main_menu/shard_browser.tscn")
var create_server = load("res://addons/vsk_menu/main_menu/create_server.tscn")
var join_server = load("res://addons/vsk_menu/main_menu/join_server.tscn")
var options_screen = load("res://addons/vsk_menu/main_menu/options_screen.tscn")
var credits_screen = load("res://addons/vsk_menu/main_menu/credits_screen.tscn")
var login_screen = load("res://addons/vsk_menu/main_menu/login_screen.tscn")
const vsk_version_const = preload("res://addons/vsk_version/vsk_version.gd")


func _callback_state(p_state: int, p_callback_dictionary: Dictionary) -> void:
	if p_state != VSKGameFlowManager.CALLBACK_STATE_NONE:
		$AcceptDialog.set_title(tr(""))
		var callback_string: String = ""
		match p_state:
			VSKGameFlowManager.CALLBACK_STATE_KICKED_FROM_SERVER:
				callback_string = "TR_MENU_CALLBACK_STATE_KICKED_FROM_SERVER"
			VSKGameFlowManager.CALLBACK_STATE_SERVER_DISCONNECTED:
				callback_string = "TR_MENU_CALLBACK_STATE_SERVER_DISCONNECTED"
			VSKGameFlowManager.CALLBACK_STATE_MAP_UNKNOWN_FAILURE:
				callback_string = "TR_MENU_CALLBACK_STATE_MAP_UNKNOWN_FAILURE"
			VSKGameFlowManager.CALLBACK_STATE_MAP_NETWORK_FETCH_FAILED:
				callback_string = "TR_MENU_CALLBACK_STATE_MAP_NETWORK_FETCH_FAILED"
			VSKGameFlowManager.CALLBACK_STATE_MAP_RESOURCE_FAILED_TO_LOAD:
				callback_string = "TR_MENU_CALLBACK_STATE_MAP_RESOURCE_FAILED_TO_LOAD"
			VSKGameFlowManager.CALLBACK_STATE_MAP_NOT_WHITELISTED:
				callback_string = "TR_MENU_CALLBACK_STATE_MAP_NOT_WHITELISTED"
			VSKGameFlowManager.CALLBACK_STATE_MAP_FAILED_VALIDATION:
				callback_string = "TR_MENU_MAP_FAILED_VALIDATION"

			VSKGameFlowManager.CALLBACK_STATE_GAME_MODE_LOAD_FAILED:
				callback_string = "TR_MENU_CALLBACK_STATE_GAME_MODE_LOAD_FAILED"
			VSKGameFlowManager.CALLBACK_STATE_GAME_MODE_NOT_WHITELISTED:
				callback_string = "TR_MENU_CALLBACK_STATE_GAME_MODE_NOT_WHITELISTED"

			VSKGameFlowManager.CALLBACK_STATE_HOST_GAME_FAILED:
				callback_string = "TR_MENU_CALLBACK_STATE_HOST_GAME_FAILED"
			VSKGameFlowManager.CALLBACK_STATE_SHARD_REGISTRATION_FAILED:
				callback_string = "TR_MENU_CALLBACK_STATE_SHARD_REGISTRATION_FAILED"
			VSKGameFlowManager.CALLBACK_STATE_INVALID_MAP:
				callback_string = "TR_MENU_CALLBACK_STATE_INVALID_MAP"
			VSKGameFlowManager.CALLBACK_STATE_NO_SERVER_INFO:
				callback_string = "TR_MENU_CALLBACK_STATE_NO_SERVER_INFO"
			VSKGameFlowManager.CALLBACK_STATE_NO_SERVER_INFO_VERSION:
				callback_string = "TR_MENU_CALLBACK_STATE_NO_SERVER_INFO_VERSION"
			VSKGameFlowManager.CALLBACK_STATE_SERVER_INFO_VERSION_MISMATCH:
				callback_string = "TR_MENU_CALLBACK_STATE_SERVER_INFO_VERSION_MISMATCH"

		$AcceptDialog.set_text(tr(callback_string).format(p_callback_dictionary))
		$AcceptDialog.popup_centered_ratio()

	VSKGameFlowManager.set_callback_state(VSKGameFlowManager.CALLBACK_STATE_NONE, {})


func get_encompasing_theme(p_node: Node) -> Theme:
	if p_node == null:
		push_warning("Somehow every Control and Window has null Theme.")
		return Theme.new()

	var current_theme: Theme
	if p_node is Control:
		current_theme = p_node.theme
	if p_node is Window:
		current_theme = p_node.theme

	var node_parent: Object = p_node.get_parent()
	if current_theme:
		return current_theme
	elif node_parent == null and p_node.get_viewport() != p_node:
		return get_encompasing_theme(p_node.get_viewport())
	elif typeof(node_parent) == TYPE_OBJECT and node_parent != null:
		return get_encompasing_theme(node_parent)
	else:
		return get_encompasing_theme(null)


func _ready() -> void:
	_callback_state(VSKGameFlowManager.callback_state, VSKGameFlowManager.callback_dictionary)

	var build_label: Label = $BuildLabel
	build_label.set_text(vsk_version_const.get_build_label())

	var exit_dialog: ConfirmationDialog = $ExitDialog
	exit_dialog.get_ok_button().set_text(tr("Yes"))
	exit_dialog.get_cancel_button().set_text(tr("No"))

	if exit_dialog.confirmed.connect(self.quit) != OK:
		printerr("Could not connected exit_dialog confirmed!")


func _on_HostButton_pressed() -> void:
	if has_navigation_controller():
		get_navigation_controller().push_view_controller(create_server.instantiate(), true)


func _on_BrowseServers_pressed():
	if has_navigation_controller():
		get_navigation_controller().push_view_controller(shard_browser.instantiate(), true)


func _on_JoinButton_pressed() -> void:
	if has_navigation_controller():
		get_navigation_controller().push_view_controller(join_server.instantiate(), true)


func _on_OptionsButton_pressed() -> void:
	if has_navigation_controller():
		get_navigation_controller().push_view_controller(options_screen.instantiate(), true)


func _on_CreditsButton_pressed():
	if has_navigation_controller():
		get_navigation_controller().push_view_controller(credits_screen.instantiate(), true)


func _on_ExitButton_pressed() -> void:
	$ExitDialog.popup_centered_ratio()


func _on_sign_in_button_pressed(p_session_controller):
	if has_navigation_controller():
		p_session_controller.sign_in(get_navigation_controller(), login_screen)


func _on_sign_out_button_pressed(p_session_controller):
	if has_navigation_controller():
		p_session_controller.sign_out()


func _on_DisconnectButton_pressed():
	await VSKGameFlowManager.go_to_title(false)


func quit() -> void:
	VSKGameFlowManager.request_quit()
