# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_editor_sign_in_editor_control.gd
# SPDX-License-Identifier: MIT

@tool
extends Control
class_name VSKEditorSignInDialogControl

signal session_request_successful

var _toolbar_container: VSKEditorUroToolbarContainer = null

func _domain_confirmed() -> void:
	if domain_label:
		domain_label.text = domain_selector_window.line_edit.text
	domain_selector_window.hide()

func _session_request_submitted() -> void:
	if username_or_email_lineedit:
		username_or_email_lineedit.editable = false
	if password_lineedit:
		password_lineedit.editable = false

	if change_domain_button:
		change_domain_button.disabled = true
	if submit_button:
		submit_button.disabled = true
		submit_button.hide()
	if cancel_button:
		cancel_button.disabled = false
		cancel_button.show()

func _session_request_complete(p_result: GodotUroHelper.RequesterCode, p_message: String) -> void:
	if username_or_email_lineedit:
		username_or_email_lineedit.editable = true
	if password_lineedit:
		password_lineedit.editable = true
		
	if change_domain_button:
		change_domain_button.disabled = false
	if submit_button:
		submit_button.disabled = false
		submit_button.show()
	if cancel_button:
		cancel_button.disabled = true
		cancel_button.hide()

	if p_result == GodotUroHelper.RequesterCode.OK:
		password_lineedit.text = ""
		result_label.set_text("")
		session_request_successful.emit()
	else:
		if result_label:
			result_label.set_text(p_message)


func _submit_button_pressed() -> void:
	var domain: String = domain_label.text.to_lower()
	var username_or_email: String = username_or_email_lineedit.text.to_lower()
	var password: String = password_lineedit.text

	_session_request_submitted()
	
	var _processed_result: Dictionary = await _toolbar_container.sign_in(domain, username_or_email, password)
	
	if _processed_result.is_empty():
		_session_request_complete(-1, "FAILED WITH EMPTY")
	else:
		_session_request_complete(_processed_result.get("requester_code"), _processed_result.get("message", "No Message."))

func _on_cancel_button_pressed() -> void:
	_toolbar_container.cancel_sign_in()
	_session_request_complete(GodotUroHelper.RequesterCode.CANCELLED, "")

func _change_domain_called() -> void:
	if domain_selector_window.is_inside_tree():
		domain_selector_window.get_parent().remove_child(domain_selector_window)
	domain_selector_window.popup_exclusive_centered(self, Vector2i(300, 300))
	
	domain_selector_window.line_edit.text = domain_label.text
	
func _ready():
	if self != get_tree().edited_scene_root:
		pass

###

@export var domain_selector_window: VSKEditorDomainSelector = null

@export var signing_into_label: Label = null
@export var domain_label: Label = null

@export var username_or_email_lineedit: LineEdit = null
@export var password_lineedit: LineEdit = null

@export var change_domain_button: Button = null
@export var submit_button: Button = null
@export var cancel_button: Button = null
@export var result_label: Label = null

func setup(p_toolbar_container: VSKEditorUroToolbarContainer) -> void:
	_toolbar_container = p_toolbar_container
	
func update_fields(p_domain: String, p_username: String, p_password: String) -> void:
	if domain_label:
		domain_label.text = p_domain
	if username_or_email_lineedit:
		username_or_email_lineedit.text = p_username
	if password_lineedit:
		password_lineedit.text = p_password
