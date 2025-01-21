# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_editor.gd
# SPDX-License-Identifier: MIT

@tool
extends Node

const vsk_editor_const = preload("res://addons/vsk_editor/vsk_editor.gd")

const vsk_uro_pipeline_const = preload("res://addons/vsk_importer_exporter/vsk_uro_pipeline.gd")

const vsk_upload_dialog_const = preload("vsk_upload_dialog.gd")
var vsk_upload_dialog: Node = null

# const vsk_progress_dialog_const = preload("vsk_progress_dialog.tscn")
var vsk_progress_dialog_const = load("res://addons/vsk_editor/vsk_progress_dialog.tscn")
var vsk_progress_dialog: Window = null

# const vsk_info_dialog_const = preload("vsk_info_dialog.tscn")
var vsk_info_dialog_const = load("res://addons/vsk_editor/vsk_info_dialog.tscn")
var vsk_info_dialog: AcceptDialog = null

const vsk_profile_dialog_const = preload("vsk_profile_dialog.gd")
var vsk_profile_dialog: Node = null

const vsk_types_const = preload("res://addons/vsk_importer_exporter/vsk_types.gd")

var vsk_account_manager: Node = null
var vsk_exporter: Node = null

var editor_interface: EditorInterface = null

var session_request_pending: bool = true
var display_name: String

var uro_button: Button = null

signal user_content_submission_requested(p_upload_data, p_callbacks)
signal user_content_submission_cancelled

signal sign_in_submission_complete(p_result)

signal session_request_complete(p_code, p_message)
signal session_deletion_complete(p_code, p_message)

##
## Uro Pipeline
##

const vsk_pipeline_uro_const = preload("res://addons/vsk_importer_exporter/vsk_uro_pipeline.gd")


static func _update_uro_pipeline(p_edited_scene: Node, p_node: Node, p_id: String, p_update_id: bool) -> String:
	var pipeline_paths: Variant = p_node.get("vskeditor_pipeline_paths")
	if typeof(pipeline_paths) == TYPE_NIL:
		pipeline_paths = []
	for pipeline_path in pipeline_paths:
		if pipeline_path and typeof(pipeline_path) == TYPE_NODE_PATH:
			var pipeline = p_node.get_node_or_null(pipeline_path)
			if pipeline is vsk_pipeline_uro_const:
				if p_update_id and pipeline.database_id != p_id:
					pipeline.database_id = p_id
					return p_id
				else:
					return pipeline.database_id

	var uro_pipeline = vsk_pipeline_uro_const.new(p_id)
	uro_pipeline.set_name("UroPipeline")

	p_node.add_child(uro_pipeline, true)
	uro_pipeline.set_owner(p_edited_scene)
	if p_node.has_method("add_pipeline"):
		p_node.add_pipeline(uro_pipeline)
	else:
		return ""

	p_node.notify_property_list_changed()

	return p_id


func user_content_new_uro_id(p_node: Node, p_id: String) -> void:
	var id: String = ""
	vsk_editor_const._update_uro_pipeline(editor_interface.get_edited_scene_root(), p_node, p_id, true)

	print("user_content_new_uro_id: %s" % id)

	#var inspector: EditorInspector = editor_interface.get_inspector()
	# FIXME: no longer exists #inspector.refresh()


func user_content_get_uro_id(p_node: Node) -> String:
	var id: String = ""
	var pipeline_paths: Array = p_node.get("vskeditor_pipeline_paths")
	for path in pipeline_paths:
		if path and typeof(path) == TYPE_NODE_PATH:
			var uro_pipeline_node: Node = p_node.get_node_or_null(path)
			if uro_pipeline_node.get_script() == vsk_uro_pipeline_const:
				id = uro_pipeline_node.database_id
				break

	print("user_content_get_uro_id: %s" % id)
	return id


##
##
##


static func get_upload_data_for_packed_scene(p_vsk_exporter: Node, p_packed_scene: PackedScene) -> Dictionary:
	if p_vsk_exporter:
		if p_vsk_exporter.create_temp_folder() == OK:
			if p_vsk_exporter.save_user_content_resource("user://temp/autogen.scn", p_packed_scene) == OK:
				var file: FileAccess = FileAccess.open("user://temp/autogen.scn", FileAccess.READ)
				if file:
					var buffer = file.get_buffer(file.get_length())
					return {"filename": "autogen.scn", "content_type": "application/octet-stream", "data": buffer}

			push_error("Failed to get upload data!")
		else:
			push_error("Could not create temp directory")
	else:
		push_error("Could not load VSKExporter")

	return {}


static func get_raw_png_from_image(p_image: Image) -> Dictionary:
	return {"filename": "autogen.png", "content_type": "image/png", "data": p_image.save_png_to_buffer()}


##
##
##


func show_profile_panel() -> void:
	if vsk_profile_dialog:
		vsk_profile_dialog.popup_centered_ratio()
		vsk_profile_dialog.popup_window = false
	else:
		push_error("Profile dialog is null!")


func show_upload_panel(p_callback: Callable, p_user_content: int) -> void:
	if vsk_upload_dialog:
		vsk_upload_dialog.set_export_data_callback(p_callback)
		vsk_upload_dialog.set_user_content_type(p_user_content)
		vsk_upload_dialog.popup_centered_ratio()


func set_session_request_pending(p_is_pending: bool) -> void:
	print("VSKEditor::set_session_request_pending")
	session_request_pending = p_is_pending
	if uro_button:
		uro_button.set_disabled(false)  # session_request_pending)


func sign_out() -> void:
	print("VSKEditor::sign_out")
	assert(vsk_account_manager)

	vsk_account_manager.sign_out()


func sign_in(username_or_email: String, password: String) -> void:
	print("VSKEditor::sign_in")
	if not vsk_account_manager:
		session_request_complete.emit(FAILED, "VSK Account manager is not loaded.")
		return

	await vsk_account_manager.sign_in(username_or_email, password)
	sign_in_submission_complete.emit(OK)


func _submit_button_pressed(p_upload_data: Dictionary) -> void:
	print("VSKEditor::_submit_button_pressed")

	if vsk_progress_dialog:
		vsk_progress_dialog.popup_centered_ratio()
		vsk_progress_dialog.set_progress_label_text("")
		vsk_progress_dialog.set_progress_bar_value(0.0)

		var packed_scene_created_callback: Callable = self._packed_scene_created_callback

		var packed_scene_creation_failed_callback: Callable = self._packed_scene_creation_failed_created_callback

		var packed_scene_pre_uploading_callback: Callable = self._packed_scene_pre_uploading_callback

		var packed_scene_uploaded_callback: Callable = self._packed_scene_uploaded_callback

		var packed_scene_upload_failed_callback: Callable = self._packed_scene_upload_failed_callback

		user_content_submission_requested.emit(p_upload_data, {"packed_scene_created": packed_scene_created_callback, "packed_scene_creation_failed": packed_scene_creation_failed_callback, "packed_scene_pre_uploading": packed_scene_pre_uploading_callback, "packed_scene_uploaded": packed_scene_uploaded_callback, "packed_scene_upload_failed": packed_scene_upload_failed_callback})
	else:
		push_error("Progress dialog is null!")


func _cancel_button_pressed() -> void:
	user_content_submission_cancelled.emit()


func _user_content_get_failed(p_result: Dictionary) -> void:
	vsk_upload_dialog.hide()
	vsk_progress_dialog.hide()

	vsk_info_dialog.set_info_text("Failed with error: %s" % GodotUro.godot_uro_helper_const.get_full_requester_error_string(p_result))
	vsk_info_dialog.popup_centered_ratio()


func _requesting_user_content(p_user_content_type: int, p_database_id: String, p_callback: Callable) -> void:
	var user_content: Dictionary = {}
	var database_id: String = ""

	match p_user_content_type:
		vsk_types_const.UserContentType.Avatar:
			if not p_database_id.is_empty():
				var result = await GodotUro.godot_uro_api.dashboard_get_avatar_async(p_database_id)
				if GodotUro.godot_uro_helper_const.requester_result_is_ok(result):
					var output: Dictionary = result["output"]
					var data: Dictionary = output["data"]
					if data.has("avatar"):
						user_content = data["avatar"]
						database_id = p_database_id
				else:
					_user_content_get_failed(result)

		vsk_types_const.UserContentType.Map:
			if not p_database_id.is_empty():
				var result = await GodotUro.godot_uro_api.dashboard_get_map_async(p_database_id)
				if GodotUro.godot_uro_helper_const.requester_result_is_ok(result):
					var output: Dictionary = result["output"]
					var data: Dictionary = output["data"]
					if data.has("map"):
						user_content = data["map"]
						database_id = p_database_id
				else:
					_user_content_get_failed(result)

	p_callback.call(database_id, user_content)


##
## Setup user interfaces
##


func _setup_progress_panel(p_root: Control) -> void:
	print("VSKEditor::_setup_progress_panel")

	vsk_progress_dialog = vsk_progress_dialog_const.instantiate() as Window
	vsk_progress_dialog.visible = false

	p_root.add_child(vsk_progress_dialog, true)

	if vsk_progress_dialog.cancel_button_pressed.connect(self._cancel_button_pressed) != OK:
		push_error("Could not connect signal 'cancel_button_pressed'")


func _setup_info_panel(p_root: Control) -> void:
	print("VSKEditor::_setup_info_panel")

	vsk_info_dialog = vsk_info_dialog_const.instantiate() as AcceptDialog
	vsk_info_dialog.visible = false

	p_root.add_child(vsk_info_dialog, true)


func _setup_upload_panel(p_root: Control) -> void:
	print("VSKEditor::_setup_upload_panel")

	vsk_upload_dialog = vsk_upload_dialog_const.new(self)
	vsk_upload_dialog.visible = false

	p_root.add_child(vsk_upload_dialog, true)

	if vsk_upload_dialog.submit_button_pressed.connect(self._submit_button_pressed) != OK:
		push_error("Could not connect signal 'submit_button_pressed'")
	if vsk_upload_dialog.requesting_user_content.connect(self._requesting_user_content) != OK:
		push_error("Could not connect signal 'requesting_user_content'")


func _setup_profile_panel(p_root: Control) -> void:
	print("VSKEditor::_setup_profile_panel")

	vsk_profile_dialog = vsk_profile_dialog_const.new(self)
	vsk_profile_dialog.visible = false

	p_root.add_child(vsk_profile_dialog, true)


func setup_editor(p_root: Control, p_uro_button: Button, p_editor_interface: EditorInterface) -> void:
	print("VSKEditor::setup_editor")

	if p_uro_button:
		uro_button = p_uro_button
		uro_button.set_disabled(false)  # session_request_pending)
		uro_button.pressed.connect(self.show_profile_panel)

	_setup_profile_panel(p_root)
	_setup_upload_panel(p_root)
	_setup_progress_panel(p_root)
	_setup_info_panel(p_root)

	editor_interface = p_editor_interface


##
## Teardown user interfaces
##


func _teardown_progress_panel() -> void:
	print("VSKEditor::_teardown_progress_panel")

	if vsk_progress_dialog:
		vsk_progress_dialog.queue_free()


func _teardown_info_panel() -> void:
	print("VSKEditor::_teardown_info_panel")

	if vsk_info_dialog:
		vsk_info_dialog.queue_free()


func _teardown_upload_panel() -> void:
	print("VSKEditor::_teardown_upload_panel")

	if vsk_upload_dialog:
		vsk_upload_dialog.queue_free()


func _teardown_profile_panel() -> void:
	print("VSKEditor::_teardown_profile_panel")

	if vsk_profile_dialog:
		vsk_profile_dialog.queue_free()


func teardown_editor():
	print("VSKEditor::teardown_editor")

	_teardown_profile_panel()
	_teardown_upload_panel()
	_teardown_progress_panel()
	_teardown_info_panel()

	if uro_button:
		if uro_button.pressed.is_connected(self.show_profile_panel):
			uro_button.pressed.disconnect(self.show_profile_panel)


##
## Submission callbacks
##


func _packed_scene_created_callback() -> void:
	print("VSKEditor::_packed_scene_created_callback")

	vsk_progress_dialog.title = "Scene packaging complete!"
	vsk_progress_dialog.set_progress_label_text("Scene packaging complete!")
	vsk_progress_dialog.set_progress_bar_value(100.0)


func _packed_scene_creation_failed_created_callback(p_error_message: String) -> void:
	push_error("VSKEditor::_packed_scene_creation_failed_created_callback: " + p_error_message)

	vsk_upload_dialog.hide()
	vsk_progress_dialog.hide()

	vsk_info_dialog.set_info_text(p_error_message)
	vsk_info_dialog.popup_centered_ratio()


func _create_upload_dictionary(p_name: String, p_description: String, p_packed_scene: PackedScene, p_image: Image, p_is_public: bool) -> Dictionary:
	var dictionary: Dictionary = {"name": p_name, "description": p_description, "is_public": p_is_public}
	if p_packed_scene:
		var user_content_data: Dictionary = vsk_editor_const.get_upload_data_for_packed_scene(vsk_exporter, p_packed_scene)
		if !user_content_data.is_empty():
			dictionary["user_content_data"] = user_content_data
		else:
			return {}

	if p_image:
		dictionary["user_content_preview"] = vsk_editor_const.get_raw_png_from_image(p_image)

	return dictionary


func _packed_scene_pre_uploading_callback(p_packed_scene: PackedScene, p_upload_data: Dictionary, p_callbacks: Dictionary) -> void:
	print("VSKEditor::_packed_scene_pre_uploading_callback")

	vsk_progress_dialog.title = "Scene uploading..."
	vsk_progress_dialog.set_progress_label_text("Scene uploading...")
	vsk_progress_dialog.set_progress_bar_value(100.0)

	###
	var export_data_callback = p_upload_data["export_data_callback"]
	var export_data: Dictionary = export_data_callback.call()

	var node: Node = export_data["node"]

	var database_id: String = user_content_get_uro_id(node)

	if GodotUro.godot_uro_api:
		var upload_data_name: String = p_upload_data.get("name", "")
		var upload_data_description: String = p_upload_data.get("description", "")
		var upload_data_preview_image: Image = p_upload_data.get("preview_image", null)
		var upload_data_is_public: bool = p_upload_data.get("is_public", false)

		var result: Dictionary = {}
		var type: int = p_upload_data["user_content_type"]
		var upload_dictionary: Dictionary = _create_upload_dictionary(upload_data_name, upload_data_description, p_packed_scene, upload_data_preview_image, upload_data_is_public)

		if !upload_dictionary.is_empty():
			if database_id == "":
				match type:
					vsk_types_const.UserContentType.Avatar:
						result = await GodotUro.godot_uro_api.dashboard_create_avatar_async(upload_dictionary)
					vsk_types_const.UserContentType.Map:
						result = await GodotUro.godot_uro_api.dashboard_create_map_async(upload_dictionary)
			else:
				match type:
					vsk_types_const.UserContentType.Avatar:
						result = await GodotUro.godot_uro_api.dashboard_update_avatar_async(database_id, upload_dictionary)
					vsk_types_const.UserContentType.Map:
						result = await GodotUro.godot_uro_api.dashboard_update_map_async(database_id, upload_dictionary)

			if GodotUro.godot_uro_helper_const.requester_result_is_ok(result):
				var output: Dictionary = result["output"]
				var data: Dictionary = output["data"]
				database_id = data["id"]

				p_callbacks["packed_scene_uploaded"].call(database_id)

				user_content_new_uro_id(node, database_id)
			else:
				p_callbacks["packed_scene_upload_failed"].call("Upload failed with error: %s" % GodotUro.godot_uro_helper_const.get_full_requester_error_string(result))
		else:
			p_callbacks["packed_scene_upload_failed"].call("Could not process upload data!")
	else:
		p_callbacks["packed_scene_upload_failed"].call("Could not load Godot Uro API")


func _packed_scene_uploaded_callback(p_database_id: String) -> void:
	print("VSKEditor::_packed_scene_uploaded_callback: " + p_database_id)

	vsk_progress_dialog.hide()
	vsk_upload_dialog.hide()

	vsk_info_dialog.set_info_text("Uploaded successfully!")
	vsk_info_dialog.popup_centered_ratio()


func _packed_scene_upload_failed_callback(p_error_message: String) -> void:
	push_error("VSKEditor::_packed_scene_upload_failed_callback: " + str(p_error_message))

	vsk_progress_dialog.hide()
	vsk_upload_dialog.hide()

	vsk_info_dialog.set_info_text(p_error_message)
	vsk_info_dialog.popup_centered_ratio()


##
## Session callbacks
##


func _session_renew_started() -> void:
	print("VSKEditor::_session_renew_started")
	set_session_request_pending(true)


func _session_request_complete(p_code: GodotUro.godot_uro_helper_const.RequesterCode, p_message: String) -> void:
	print("VSKEditor::_session_request_complete")

	if vsk_account_manager and p_code == GodotUro.godot_uro_helper_const.RequesterCode.OK:
		display_name = vsk_account_manager.account_display_name
		print("Logged into V-Sekai as %s" % display_name)
	else:
		display_name = ""
		print("Could not log into V-Sekai (%s)..." % p_message)

	set_session_request_pending(false)
	session_request_complete.emit(p_code, p_message)


func _session_deletion_complete(p_code: GodotUro.godot_uro_helper_const.RequesterCode, p_message: String) -> void:
	print("VSKEditor::_session_deletion_complete")

	display_name = ""

	session_deletion_complete.emit(p_code, p_message)


##
## Linking
##

func _link_vsk_account_manager(p_node: Node) -> void:	
	if p_node == vsk_account_manager:
		return
	
	if vsk_account_manager:
		_unlink_vsk_account_manager()
	
	vsk_account_manager = p_node

	if vsk_account_manager:
		print("Linking VSKAccountManager to VSKEditor...")
		
		var result: Error = OK
		
		result = vsk_account_manager.session_renew_started.connect(self._session_renew_started)
		if result != OK:
			push_error("Could not connect signal 'session_renew_started'. Result %s" % str(result))
		result = vsk_account_manager.session_request_complete.connect(self._session_request_complete)
		if result != OK:
			push_error("Could not connect signal 'session_request_complete'. Result %s" % str(result))
		result = vsk_account_manager.session_deletion_complete.connect(self._session_deletion_complete)
		if result != OK:
			push_error("Could not connect signal 'session_deletion_complete'. Result %s" % str(result))

		vsk_account_manager.call_deferred("start_session")


func _unlink_vsk_account_manager() -> void:
	if vsk_account_manager:
		print("Unlinking VSKAccountManager from VSKEditor...")

		vsk_account_manager.session_renew_started.disconnect(self._session_renew_started)
		vsk_account_manager.session_request_complete.disconnect(self._session_request_complete)
		vsk_account_manager.session_deletion_complete.disconnect(self._session_deletion_complete)

		vsk_account_manager = null

		if uro_button:
			uro_button.set_disabled(false)  # true)


func _link_vsk_exporter(p_node: Node) -> void:
	if p_node == vsk_exporter:
		return
	
	if vsk_exporter:
		_unlink_vsk_exporter()
	
	vsk_exporter = p_node
	
	if vsk_exporter:
		print("Linking VSKExporter to VSKEditor...")


func _unlink_vsk_exporter() -> void:
	if vsk_exporter:
		print("Unlinking VSKExporter from VSKEditor...")
		vsk_exporter = null

func _node_added(p_node: Node) -> void:
	var parent_node: Node = p_node.get_parent()
	if parent_node:
		if !parent_node.get_parent():
			match p_node.get_name():
				"VSKAccountManager":
					_link_vsk_account_manager(p_node)
				"VSKExporter":
					_link_vsk_exporter(p_node)


func _node_removed(p_node: Node) -> void:
	if p_node == vsk_account_manager:
		_unlink_vsk_account_manager()
	if p_node == vsk_exporter:
		_unlink_vsk_exporter()


##
## Tree functions
##


func _enter_tree():
	if Engine.is_editor_hint():
		assert(get_tree().node_added.connect(self._node_added) == OK)
		assert(get_tree().node_removed.connect(self._node_removed) == OK)

	_link_vsk_account_manager(VSKAccountManager)
	_link_vsk_exporter(VSKExporter)


func _exit_tree():
	teardown_editor()
