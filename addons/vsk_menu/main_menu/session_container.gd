# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# session_container.gd
# SPDX-License-Identifier: MIT

extends HBoxContainer

@export var sign_in_container_nodepath: NodePath = NodePath()
@export var sign_out_container_nodepath: NodePath = NodePath()
@export var reconnect_container_nodepath: NodePath = NodePath()
@export var session_info_nodepath: NodePath = NodePath()

var pending_action: bool = false
var display_name: String = ""

var response_code: int = GodotUro.godot_uro_helper_const.RequesterCode.OK

signal sign_in_button_pressed(p_session_container)
signal sign_out_button_pressed(p_session_container)


func _on_sign_in_button_pressed() -> void:
	sign_in_button_pressed.emit(self)


func _on_sign_out_button_pressed() -> void:
	sign_out_button_pressed.emit(self)


func _on_reconnect_button_pressed():
	await reconnect()


func is_pending() -> bool:
	return pending_action


func set_connection_failure_message(p_string: String) -> void:
	get_node(sign_in_container_nodepath).hide()
	get_node(sign_out_container_nodepath).hide()
	get_node(reconnect_container_nodepath).show()
	get_node(session_info_nodepath).show()
	get_node(session_info_nodepath).text = TranslationServer.translate(p_string)


func update_from_response(p_response: int) -> void:
	if p_response == GodotUro.godot_uro_helper_const.RequesterCode.OK and VSKAccountManager.is_signed_in():
		get_node(sign_in_container_nodepath).hide()
		get_node(sign_out_container_nodepath).show()
		get_node(reconnect_container_nodepath).hide()
		get_node(session_info_nodepath).show()
		get_node(session_info_nodepath).text = str(TranslationServer.translate("TR_MENU_SESSION_SIGNED_IN_AS")).format({"display_name": display_name})
	elif p_response == GodotUro.godot_uro_helper_const.RequesterCode.CANT_CONNECT:
		set_connection_failure_message("TR_MENU_SESSION_CANT_CONNECT")
	elif p_response == GodotUro.godot_uro_helper_const.RequesterCode.CANT_RESOLVE:
		set_connection_failure_message("TR_MENU_SESSION_CANT_RESOLVE")
	elif p_response == GodotUro.godot_uro_helper_const.RequesterCode.SSL_HANDSHAKE_ERROR:
		set_connection_failure_message("TR_MENU_SESSION_SSL_HANDSHAKE_ERROR")
	elif p_response == GodotUro.godot_uro_helper_const.RequesterCode.DISCONNECTED:
		set_connection_failure_message("TR_MENU_SESSION_DISCONNECTED")
	elif p_response == GodotUro.godot_uro_helper_const.RequesterCode.CONNECTION_ERROR:
		set_connection_failure_message("TR_MENU_SESSION_CONNECTION_ERROR")
	else:
		get_node(sign_in_container_nodepath).show()
		get_node(sign_out_container_nodepath).hide()
		get_node(session_info_nodepath).hide()


func set_pending(p_pending: bool) -> void:
	pending_action = p_pending
	if pending_action:
		get_node(sign_in_container_nodepath).hide()
		get_node(sign_out_container_nodepath).hide()
		get_node(reconnect_container_nodepath).hide()
		get_node(session_info_nodepath).show()
		get_node(session_info_nodepath).text = TranslationServer.translate("TR_MENU_SESSION_PENDING")
	else:
		update_from_response(response_code)


func _session_renew_started() -> void:
	pass  # Do nothing


func _session_request_complete(p_code: int, p_message: String) -> void:
	print("session_container:_session_request_complete: %s" % p_message)

	response_code = p_code

	if response_code == GodotUro.godot_uro_helper_const.RequesterCode.OK:
		display_name = VSKAccountManager.account_display_name
	else:
		display_name = ""

	set_pending(false)


func _session_deletion_complete(_p_code: int, p_message: String) -> void:
	print("session_container:_session_deletion_complete: %s" % p_message)

	display_name = ""

	set_pending(false)


func reconnect() -> void:
	if !is_pending():
		set_pending(true)
		await VSKAccountManager.get_profile_info()


func attempt_to_fetch_profile_info() -> void:
	await reconnect()


func _notification(what):
	match what:
		NOTIFICATION_VISIBILITY_CHANGED:
			if is_visible_in_tree():
				await attempt_to_fetch_profile_info()


func sign_in(p_navigation_controller: NavigationController, p_login_screen):
	p_navigation_controller.push_view_controller(p_login_screen.instantiate(), true)


func sign_out():
	if !is_pending():
		set_pending(true)
		await VSKAccountManager.sign_out()


func _ready():
	if VSKAccountManager.session_renew_started.connect(self._session_renew_started) != OK:
		push_error("Failed to connect session_renew_started signal")
		return

	if VSKAccountManager.session_request_complete.connect(self._session_request_complete) != OK:
		push_error("Failed to connect session_request_complete signal")
		return

	if VSKAccountManager.session_deletion_complete.connect(self._session_deletion_complete) != OK:
		push_error("Failed to connect session_deletion_complete signal")
		return
