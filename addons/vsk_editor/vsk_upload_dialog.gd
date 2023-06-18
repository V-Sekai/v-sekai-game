# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_upload_dialog.gd
# SPDX-License-Identifier: MIT

@tool
extends AcceptDialog

const vsk_types_const = preload("res://addons/vsk_importer_exporter/vsk_types.gd")

signal submit_button_pressed(p_submission_data)
signal requesting_user_content(user_content_type, p_database_id, p_callback)

const LOGIN_REQUIRED_STRING = "Please log in to upload content"
const INVALID_PERMISSIONS = "Your account does not currently have permission to upload this type of content"

const TITLE_STRING = "Upload"
const WINDOW_RESOLUTION = Vector2(1280, 720)

# const upload_panel_content_const = preload("vsk_upload_panel_contents.tscn")
var upload_panel_content_const = load("res://addons/vsk_editor/vsk_upload_panel_contents.tscn")

var vsk_editor: Node = null

var export_data_callback: Callable = Callable()
var user_content_type: int = -1
var current_database_id: String = ""

var control: Control = null

var upload_data: Dictionary = {}


func _submit_pressed(p_submission_data: Dictionary) -> void:
	print("Submitting " + str(p_submission_data))
	submit_button_pressed.emit(p_submission_data)


func set_export_data_callback(p_callback: Callable) -> void:
	export_data_callback = p_callback


func set_user_content_type(p_user_content_type: int) -> void:
	user_content_type = p_user_content_type


func _clear_children() -> void:
	if control:
		control.queue_free()
		control.get_parent().remove_child(control)
	control = null


func _instance_upload_panel_child_control() -> void:
	set_title(TITLE_STRING)

	_clear_children()

	if !control:
		control = upload_panel_content_const.instantiate()
		control.set_export_data_callback(export_data_callback)
		control.set_user_content_type(user_content_type)
		add_child(control, true)

		if control.submit_button_pressed.connect(self._submit_pressed) == OK:
			var user_content_node: Node = null
			var export_data: Dictionary = export_data_callback.call()
			user_content_node = export_data.get("node")

			current_database_id = ""
			if user_content_node:
				current_database_id = vsk_editor.user_content_get_uro_id(user_content_node)

			_request_user_content(user_content_type, current_database_id)

			control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE)
		else:
			printerr("Could ")


func _instance_info_child_control(p_string: String) -> void:
	set_title(TITLE_STRING)

	_clear_children()

	if !control:
		var info_label: Label = Label.new()
		info_label.set_text(p_string)
		info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		info_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

		control = info_label
		add_child(info_label, true)

		control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE)


func _received_user_content_data(p_database_id: String, p_user_content_data: Dictionary) -> void:
	print(
		"_received user content for: '%s'. current_database_id: '%s'" % [str(p_database_id), str(current_database_id)]
	)
	control.update_user_content_data(p_user_content_data, not p_database_id.is_empty())


func _request_user_content(p_user_content_type: int, p_database_id: String) -> void:
	var callback: Callable = self._received_user_content_data

	requesting_user_content.emit(p_user_content_type, p_database_id, callback)


func _user_content_can_be_uploaded_by_current_account() -> bool:
	match user_content_type:
		vsk_types_const.UserContentType.Avatar:
			if VSKAccountManager.can_upload_avatars:
				return true
		vsk_types_const.UserContentType.Map:
			if VSKAccountManager.can_upload_maps:
				return true

	return false


func _instance_child_control() -> void:
	if VSKAccountManager.is_signed_in():
		if _user_content_can_be_uploaded_by_current_account():
			_instance_upload_panel_child_control()
		else:
			_instance_info_child_control(INVALID_PERMISSIONS)
	else:
		_instance_info_child_control(LOGIN_REQUIRED_STRING)


func _about_to_popup() -> void:
	_state_changed()


func _state_changed() -> void:
	_instance_child_control()


func _ready() -> void:
	borderless = false
	transient = false
	var ok_button: Button = get_ok_button()
	if ok_button:
		ok_button.hide()

	if about_to_popup.connect(self._about_to_popup) != OK:
		printerr("Could not connect to about_to_popup")


func _init(p_vsk_editor: Node):
	vsk_editor = p_vsk_editor

	set_title(TITLE_STRING)
	set_size(WINDOW_RESOLUTION)


func _enter_tree():
	pass
	#VSKAccountManager.session_renew_started.connect(self, "_session_renew_started")
	#VSKAccountManager.session_request_complete.connect(self, "_session_request_complete")
	#VSKAccountManager.session_deletion_complete.connect(self, "_session_deletion_complete")


func _exit_tree():
	pass
	#VSKAccountManager.session_renew_started.disconnect(self, "_session_renew_started")
	#VSKAccountManager.session_request_complete.disconnect(self, "_session_request_complete")
	#VSKAccountManager.session_deletion_complete.disconnect(self, "_session_deletion_complete")
