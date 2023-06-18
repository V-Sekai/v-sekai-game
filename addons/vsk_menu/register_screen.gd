# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# register_screen.gd
# SPDX-License-Identifier: MIT

extends "res://addons/vsk_menu/setup_menu.gd"  # setup_menu.gd

const password_input_const = preload("res://addons/vsk_menu/password_input.gd")

@export var username_input_nodepath: NodePath = NodePath()
@export var email_input_nodepath: NodePath = NodePath()
@export var password_input_nodepath: NodePath = NodePath()
@export var password_confirmation_input_nodepath: NodePath = NodePath()
@export var email_notifications_input_nodepath: NodePath = NodePath()

@export var register_cancel_button_input_nodepath: NodePath = NodePath()

@export var status_label_nodepath: NodePath = NodePath()

var username_input: LineEdit = null
var email_input: LineEdit = null
var password_input: HBoxContainer = null  # password_input_const
var password_confirmation_input: HBoxContainer = null  # password_input_const
var email_notifications_input: CheckBox = null

var register_cancel_button: Button = null

var status_label: Label = null

var email: String
var username: String
var password: String
var password_confirmation: String
var email_notifications: bool = false

var pending_registration: bool = false

const status_codes_const = preload("status_codes.gd")


func _gameflow_state_changed(p_state) -> void:
	pass


func will_appear() -> void:
	if VSKGameFlowManager.gameflow_state_changed.connect(self._gameflow_state_changed) != OK:
		printerr("Could not connect gameflow_state_changed!")


func will_disappear() -> void:
	if VSKGameFlowManager.gameflow_state_changed.is_connected(self._gameflow_state_changed):
		VSKGameFlowManager.gameflow_state_changed.disconnect(self._gameflow_state_changed)


func set_status_by_code(p_status_code: int) -> void:
	var string: String = TranslationServer.translate(status_codes_const.STATUS_STRING_MAP[p_status_code])
	if status_label:
		print(string)
		status_label.set_text(string)


func set_status_by_server_message(p_message: String) -> void:
	if status_label:
		print(p_message)
		status_label.set_text(p_message)


func check_if_registration_input_valid(p_username: String, p_email, p_password: String, p_password_confirmation: String) -> bool:
	if p_username.length() == 0:
		set_status_by_code(status_codes_const.STATUS_CODE_NO_USERNAME)
		return false
	if p_username.length() == 0:
		set_status_by_code(status_codes_const.STATUS_CODE_NO_EMAIL)
		return false
	if p_password.length() == 0:
		set_status_by_code(status_codes_const.STATUS_CODE_NO_PASSWORD)
		return false
	if p_password != p_password_confirmation:
		set_status_by_code(status_codes_const.STATUS_CODE_PASSWORD_MISMATCH)
		return false

	return true


func registration_submission_complete(p_result, p_message) -> void:
	pending_registration = false
	update_registration_button()

	set_status_by_server_message(p_message)


func attempt_registration(p_username: String, p_email, p_password: String, p_password_confirmation: String, p_email_notifications) -> void:
	if check_if_registration_input_valid(p_username, p_email, p_password, p_password_confirmation):
		pending_registration = true
		set_status_by_code(status_codes_const.STATUS_CODE_PENDING)
		update_registration_button()

		await VSKAccountManager.register(p_username, p_email, p_password, p_password_confirmation, p_email_notifications)


func cancel_registration() -> void:
	pending_registration = false
	update_registration_button()

	VSKAccountManager.cancel()


func update_registration_button() -> void:
	if username.length() > 0 and email.length() > 0 and password.length() > 0 and password_confirmation.length() > 0:
		register_cancel_button.disabled = false
	else:
		register_cancel_button.disabled = true


func back_button_pressed() -> void:
	save_changes()
	super.back_button_pressed()


func _on_UsernameLineEdit_text_changed(new_text: String) -> void:
	username = new_text
	update_registration_button()


func _on_EmailLineEdit_text_changed(new_text):
	email = new_text
	update_registration_button()


func _on_PasswordInput_text_changed(p_text):
	password = p_text
	update_registration_button()


func _on_PasswordConfirmationInput_text_changed(p_text):
	password_confirmation = p_text
	update_registration_button()


func _on_RegisterCancelButton_pressed():
	if !pending_registration:
		await attempt_registration(username, email, password, password_confirmation, email_notifications)
	else:
		cancel_registration()


func _on_BackButton_pressed() -> void:
	back_button_pressed()


func save_changes() -> void:
	super.save_changes()


func _ready() -> void:
	VSKAccountManager.registration_request_complete.connect(self.registration_submission_complete)

	username_input = get_node_or_null(username_input_nodepath)
	username = username_input.text

	email_input = get_node_or_null(email_input_nodepath)
	email = email_input.text

	password_input = get_node_or_null(password_input_nodepath)
	password = password_input.text

	password_confirmation_input = get_node_or_null(password_confirmation_input_nodepath)
	password_confirmation = password_confirmation_input.text

	email_notifications_input = get_node_or_null(email_notifications_input_nodepath)
	email_notifications = email_notifications_input.button_pressed

	register_cancel_button = get_node_or_null(register_cancel_button_input_nodepath)

	status_label = get_node_or_null(status_label_nodepath)

	update_registration_button()
