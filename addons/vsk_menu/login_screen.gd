# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# login_screen.gd
# SPDX-License-Identifier: MIT

extends "res://addons/vsk_menu/setup_menu.gd"  # setup_menu.gd

@export var username_or_email_input_nodepath: NodePath = NodePath()
@export var password_input_nodepath: NodePath = NodePath()
@export var status_label_nodepath: NodePath = NodePath()

@export var login_cancel_button_input_nodepath: NodePath = NodePath()

var pending_login: bool = false

var username_or_email_input: LineEdit = null
var password_input: LineEdit = null
var login_cancel_button: Button = null
var status_label: Label = null

var username_or_email: String = ""
var password: String = ""

const status_codes_const = preload("status_codes.gd")


func set_status_by_code(p_status_code: int) -> void:
	var string: String = TranslationServer.translate(status_codes_const.STATUS_STRING_MAP[p_status_code])
	if status_label:
		print(string)
		status_label.set_text(string)


func set_status_by_server_message(p_message: String) -> void:
	if status_label:
		print(p_message)
		status_label.set_text(p_message)


func check_if_login_input_valid(p_username_or_email: String, p_password: String) -> bool:
	if p_username_or_email.length() == 0:
		set_status_by_code(status_codes_const.STATUS_CODE_NO_USERNAME)
		return false
	if p_password.length() == 0:
		set_status_by_code(status_codes_const.STATUS_CODE_NO_PASSWORD)
		return false

	return true


func _session_request_complete(p_code: GodotUro.godot_uro_helper_const.RequesterCode, p_message: String) -> void:
	pending_login = false
	update_login_button()
	set_status_by_server_message(p_message)
	if p_code == GodotUro.godot_uro_helper_const.RequesterCode.OK:
		if has_navigation_controller():
			get_navigation_controller().pop_view_controller(true)


func attempt_sign_in(p_username_or_email: String, p_password: String) -> void:
	if check_if_login_input_valid(p_username_or_email, p_password):
		pending_login = true
		set_status_by_code(status_codes_const.STATUS_CODE_PENDING)
		update_login_button()

		await VSKAccountManager.sign_in(p_username_or_email, p_password)


func cancel_sign_in() -> void:
	pending_login = false
	update_login_button()
	if VSKAccountManager.has_method("cancel"):
		VSKAccountManager.cancel()


func _ready() -> void:
	if !Engine.is_editor_hint():
		if VSKAccountManager.session_request_complete.connect(self._session_request_complete) != OK:
			push_error("Failed to connect session_request_complete signal.")
			return

	username_or_email_input = get_node_or_null(username_or_email_input_nodepath)
	password_input = get_node_or_null(password_input_nodepath)
	status_label = get_node_or_null(status_label_nodepath)

	login_cancel_button = get_node_or_null(login_cancel_button_input_nodepath)

	update_login_button()


func _gameflow_state_changed(_p_state) -> void:
	pass


func will_appear() -> void:
	if VSKGameFlowManager.gameflow_state_changed.connect(self._gameflow_state_changed) != OK:
		printerr("Could not connect gameflow_state_changed!")


func will_disappear() -> void:
	if VSKGameFlowManager.gameflow_state_changed.is_connected(self._gameflow_state_changed):
		VSKGameFlowManager.gameflow_state_changed.disconnect(self._gameflow_state_changed)


func update_login_button() -> void:
	if pending_login:
		login_cancel_button.set_text(TranslationServer.translate("TR_MENU_LOGIN_CANCEL"))
	else:
		login_cancel_button.set_text(TranslationServer.translate("TR_MENU_LOGIN_LOGIN"))
		if username_or_email.length() > 0 and password.length() > 0:
			login_cancel_button.disabled = false
		else:
			login_cancel_button.disabled = true

		login_cancel_button.disabled = false


func _on_UsernameEmailLineEdit_text_changed(new_text: String) -> void:
	username_or_email = new_text
	update_login_button()


func _on_PasswordInput_text_changed(p_text: String) -> void:
	password = p_text
	update_login_button()


func _on_LoginButton_pressed():
	if !pending_login:
		attempt_sign_in(username_or_email, password)
	elif VSKAccountManager:
		cancel_sign_in()


func _on_BackButton_pressed() -> void:
	save_changes()
	super.back_button_pressed()


func back_button_pressed() -> void:
	save_changes()
	super.back_button_pressed()


func save_changes() -> void:
	super.save_changes()


func _on_login_cancel_button_button_up():
	_on_LoginButton_pressed()
	super.back_button_pressed()
