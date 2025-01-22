# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_login_editor_control.gd
# SPDX-License-Identifier: MIT

@tool
extends Control

signal session_request_successful

var vsk_editor: Node = null

const MARGIN_SIZE = 32

var vbox_container: VBoxContainer = null

var sign_in_label: Label = null

var sign_in_vbox_container: VBoxContainer = null
var username_or_email_label: Label = null
var username_or_email_lineedit: LineEdit = null
var password_label: Label = null
var password_lineedit: LineEdit = null

var submit_button: Button = null
var result_label: Label = null


func _session_request_submitted() -> void:
	username_or_email_lineedit.editable = false
	password_lineedit.editable = false

	submit_button.disabled = true


func _session_request_complete(p_result: int, p_message: String) -> void:
	username_or_email_lineedit.editable = true
	password_lineedit.editable = true

	submit_button.disabled = false

	result_label.set_text(p_message)

	if p_result == GodotUro.godot_uro_helper_const.RequesterCode.OK:
		session_request_successful.emit()
	else:
		password_lineedit.text = ""


func _submit_button_pressed() -> void:
	var username_or_email: String = username_or_email_lineedit.text
	var password: String = password_lineedit.text

	_session_request_submitted()
	await vsk_editor.sign_in(username_or_email, password)


func _init(p_vsk_editor: Node):
	vsk_editor = p_vsk_editor

	vbox_container = VBoxContainer.new()
	vbox_container.alignment = VBoxContainer.ALIGNMENT_BEGIN

	add_child(vbox_container, true)

	sign_in_label = Label.new()
	sign_in_label.set_text("")
	sign_in_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox_container.add_child(sign_in_label, true)

	sign_in_vbox_container = VBoxContainer.new()
	sign_in_vbox_container.alignment = BoxContainer.ALIGNMENT_CENTER
	sign_in_vbox_container.size_flags_vertical = SIZE_EXPAND_FILL

	username_or_email_label = Label.new()
	username_or_email_label.set_text("Email/Username")

	username_or_email_lineedit = LineEdit.new()
	username_or_email_lineedit.alignment = HORIZONTAL_ALIGNMENT_CENTER

	password_label = Label.new()
	password_label.set_text("Password")

	password_lineedit = LineEdit.new()
	password_lineedit.secret = true
	password_lineedit.alignment = HORIZONTAL_ALIGNMENT_CENTER

	sign_in_vbox_container.add_child(username_or_email_label, true)
	sign_in_vbox_container.add_child(username_or_email_lineedit, true)
	sign_in_vbox_container.add_child(password_label, true)
	sign_in_vbox_container.add_child(password_lineedit, true)

	vbox_container.add_child(sign_in_vbox_container, true)

	submit_button = Button.new()
	submit_button.set_text("Submit")
	if submit_button.pressed.connect(self._submit_button_pressed) != OK:
		push_error("Could not connected signal 'pressed'")

	vbox_container.add_child(submit_button, true)

	result_label = Label.new()
	result_label.set_text("")
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox_container.add_child(result_label, true)

	vbox_container.set_anchors_and_offsets_preset(PRESET_FULL_RECT, PRESET_MODE_MINSIZE, 0)
	vbox_container.offset_top = 0
	vbox_container.offset_left = MARGIN_SIZE
	vbox_container.offset_bottom = -MARGIN_SIZE
	vbox_container.offset_right = -MARGIN_SIZE

	if not vsk_editor:
		push_error("Could not find 'vsk_editor' at vsk_login_editor_control")
		return
	if vsk_editor.session_request_complete.connect(self._session_request_complete) != OK:
		push_error("Could not connection signal 'session_request_complete'")
