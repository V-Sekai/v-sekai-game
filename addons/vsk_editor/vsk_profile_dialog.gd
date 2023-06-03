# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_profile_dialog.gd
# SPDX-License-Identifier: MIT

@tool
extends AcceptDialog

var vsk_editor: Node = null

const WINDOW_SIZE = Vector2(650, 800)

var control: Control = null

var vsk_login_control_script_const = preload("vsk_login_editor_control.gd")
var vsk_profile_control_script_const = preload("vsk_profile_editor_control.gd")

# const vsk_profile_control_const = preload("vsk_profile_editor_control.tscn")
var vsk_profile_control_const = load("res://addons/vsk_editor/vsk_profile_editor_control.tscn")


func _clear_children() -> void:
	if control:
		control.queue_free()
		control.get_parent().remove_child(control)
	control = null


func _instance_login_child_control() -> void:
	set_title("Sign in")

	if control and control.get_script() != vsk_login_control_script_const:
		_clear_children()

	if !control:
		control = vsk_login_control_script_const.new(vsk_editor)
		if control.session_request_successful.connect(self._state_changed) != OK:
			printerr("Could not connect 'session_request_successful'")

		add_child(control, true)

		control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE)


func _instance_profile_child_control() -> void:
	set_title("Profile")

	if control and not is_instance_of(control.get_script(), vsk_profile_control_script_const):
		_clear_children()

	if !control:
		control = vsk_profile_control_const.instantiate()
		control.set_vsk_editor(vsk_editor)
		if control.session_deletion_successful.connect(self._state_changed) != OK:
			printerr("Could not connect 'session_deletion_successful'")

		add_child(control, true)

		control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE)


func _instance_child_control() -> void:
	if VSKAccountManager.is_signed_in():
		_instance_profile_child_control()
	else:
		_instance_login_child_control()


func _about_to_popup() -> void:
	_state_changed()


func _state_changed() -> void:
	_instance_child_control()


func _about_to_close() -> void:
	self.hide()


func _ready() -> void:
	if about_to_popup.connect(self._about_to_popup) != OK:
		printerr("Could not connect to about_to_popup")
	close_requested.connect(self._about_to_close)

	popup_window = false

	var ok_button: Button = get_ok_button()
	if ok_button:
		ok_button.hide()


func _init(p_vsk_editor: Node):
	popup_window = false

	vsk_editor = p_vsk_editor

	set_title("Sign in")
	set_size(WINDOW_SIZE)
