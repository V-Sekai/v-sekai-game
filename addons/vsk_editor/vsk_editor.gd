# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_editor.gd
# SPDX-License-Identifier: MIT

@tool
extends Node
class_name VSKEditor

const vsk_progress_dialog_const = preload("./vsk_editor_progress_dialog.tscn")
const vsk_info_dialog_const = preload("./vsk_editor_info_dialog.tscn")

var _vsk_upload_dialog: VSKEditorUploadDialog = null
var _vsk_progress_dialog: VSKEditorProgressDialog = null
var _vsk_info_dialog: VSKEditorInfoDialog = null

#const vsk_types_const = preload("res://addons/vsk_importer_exporter/vsk_types.gd")

var _editor_interface: EditorInterface = null

var _uro_toolbar: VSKEditorUroToolbarContainer = null

signal user_content_submission_requested(p_upload_data, p_callbacks)
signal user_content_submission_cancelled

##
## Uro Pipeline
##


static func _update_uro_pipeline(
	p_edited_scene: Node, p_node: Node, p_id: String, p_update_id: bool
) -> String:
	var pipeline_paths: Variant = p_node.get("vskeditor_pipeline_paths")
	if typeof(pipeline_paths) == TYPE_NIL:
		pipeline_paths = []
	for pipeline_path in pipeline_paths:
		if pipeline_path and typeof(pipeline_path) == TYPE_NODE_PATH:
			var pipeline = p_node.get_node_or_null(pipeline_path)
			if pipeline is VSKUroPipeline:
				if p_update_id and pipeline.database_id != p_id:
					pipeline.database_id = p_id
					return p_id
				else:
					return pipeline.database_id

	var uro_pipeline = VSKUroPipeline.new(p_id)
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
	_update_uro_pipeline(
		EditorInterface.get_edited_scene_root(), p_node, p_id, true
	)

	print("user_content_new_uro_id: %s" % id)

	#var inspector: EditorInspector = editor_interface.get_inspector()
	# FIXME: no longer exists #inspector.refresh()


func user_content_get_uro_id(p_node: Node) -> String:
	var id: String = ""
	var pipeline_paths: Array = p_node.get("vskeditor_pipeline_paths")
	for path in pipeline_paths:
		if path and typeof(path) == TYPE_NODE_PATH:
			var uro_pipeline_node: Node = p_node.get_node_or_null(path)
			if uro_pipeline_node.get_script() == VSKUroPipeline:
				id = uro_pipeline_node.database_id
				break

	print("user_content_get_uro_id: %s" % id)
	return id


##
##
##


static func get_upload_data_for_packed_scene(
	p_vsk_exporter: Node, p_packed_scene: PackedScene
) -> Dictionary:
	if p_vsk_exporter:
		if p_vsk_exporter.create_temp_folder() == OK:
			if (
				p_vsk_exporter.save_user_content_resource("user://temp/autogen.scn", p_packed_scene)
				== OK
			):
				var file: FileAccess = FileAccess.open("user://temp/autogen.scn", FileAccess.READ)
				if file:
					var buffer = file.get_buffer(file.get_length())
					return {
						"filename": "autogen.scn",
						"content_type": "application/octet-stream",
						"data": buffer
					}

			push_error("Failed to get upload data!")
		else:
			push_error("Could not create temp directory")
	else:
		push_error("Could not load VSKExporter")

	return {}


static func get_raw_png_from_image(p_image: Image) -> Dictionary:
	return {
		"filename": "autogen.png", "content_type": "image/png", "data": p_image.save_png_to_buffer()
	}


##
##
##


func show_upload_panel(p_callback: Callable, p_user_content: int) -> void:
	if _vsk_upload_dialog:
		_vsk_upload_dialog.set_export_data_callback(p_callback)
		_vsk_upload_dialog.set_user_content_type(p_user_content)
		_vsk_upload_dialog.popup_centered_ratio()


func _submit_button_pressed(p_upload_data: Dictionary) -> void:
	print("VSKEditor::_submit_button_pressed")

	if _vsk_progress_dialog:
		_vsk_progress_dialog.popup_centered_ratio()
		_vsk_progress_dialog.set_progress_label_text("")
		_vsk_progress_dialog.set_progress_bar_value(0.0)

		var packed_scene_created_callback: Callable = self._packed_scene_created_callback

		var packed_scene_creation_failed_callback: Callable = (
			self._packed_scene_creation_failed_created_callback
		)

		var packed_scene_pre_uploading_callback: Callable = (
			self._packed_scene_pre_uploading_callback
		)

		var packed_scene_uploaded_callback: Callable = self._packed_scene_uploaded_callback

		var packed_scene_upload_failed_callback: Callable = (
			self._packed_scene_upload_failed_callback
		)

		user_content_submission_requested.emit(
			p_upload_data,
			{
				"packed_scene_created": packed_scene_created_callback,
				"packed_scene_creation_failed": packed_scene_creation_failed_callback,
				"packed_scene_pre_uploading": packed_scene_pre_uploading_callback,
				"packed_scene_uploaded": packed_scene_uploaded_callback,
				"packed_scene_upload_failed": packed_scene_upload_failed_callback
			}
		)
	else:
		push_error("Progress dialog is null!")


func _cancel_button_pressed() -> void:
	user_content_submission_cancelled.emit()


func _user_content_get_failed(p_result: Dictionary) -> void:
	_vsk_upload_dialog.hide()
	_vsk_progress_dialog.hide()

	_vsk_info_dialog.set_info_text(
		(
			"Failed with error: %s"
			% GodotUroHelper.get_full_requester_error_string(p_result)
		)
	)
	_vsk_info_dialog.popup_centered_ratio()


func _requesting_user_content(
	p_user_content_type: int, p_database_id: String, p_callback: Callable
) -> void:
	"""
	var user_content: Dictionary = {}
	var database_id: String = ""

	match p_user_content_type:
		vsk_types_const.UserContentType.Avatar:
			if not p_database_id.is_empty():
				var result = await GodotUro.godot_uro_api.dashboard_get_avatar_async(p_database_id)
				if GodotUroHelper.requester_result_is_ok(result):
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
				if GodotUroHelper.requester_result_is_ok(result):
					var output: Dictionary = result["output"]
					var data: Dictionary = output["data"]
					if data.has("map"):
						user_content = data["map"]
						database_id = p_database_id
				else:
					_user_content_get_failed(result)

	p_callback.call(database_id, user_content)
	"""

##
## Setup user interfaces
##


func _setup_progress_panel(p_root: Control) -> void:
	print("VSKEditor::_setup_progress_panel")

	_vsk_progress_dialog = vsk_progress_dialog_const.instantiate() as VSKEditorProgressDialog
	if _vsk_progress_dialog:
		_vsk_progress_dialog.visible = false

		p_root.add_child(_vsk_progress_dialog, true)

		if _vsk_progress_dialog.cancel_button_pressed.connect(self._cancel_button_pressed) != OK:
			push_error("Could not connect signal 'cancel_button_pressed'")


func _setup_info_panel(p_root: Control) -> void:
	print("VSKEditor::_setup_info_panel")

	_vsk_info_dialog = vsk_info_dialog_const.instantiate() as VSKEditorInfoDialog
	if _vsk_info_dialog:
		if _vsk_info_dialog:
			_vsk_info_dialog.visible = false

			p_root.add_child(_vsk_info_dialog, true)
		else:
			printerr("Could not instantiate info dialog.")


func _setup_upload_panel(p_root: Control) -> void:
	print("VSKEditor::_setup_upload_panel")

	_vsk_upload_dialog = VSKEditorUploadDialog.new(self)
	_vsk_upload_dialog.visible = false

	p_root.add_child(_vsk_upload_dialog, true)

	if _vsk_upload_dialog.submit_button_pressed.connect(self._submit_button_pressed) != OK:
		push_error("Could not connect signal 'submit_button_pressed'")
	if _vsk_upload_dialog.requesting_user_content.connect(self._requesting_user_content) != OK:
		push_error("Could not connect signal 'requesting_user_content'")


func setup_editor(
	p_root: Control, p_uro_toolbar: VSKEditorUroToolbarContainer, p_editor_interface: EditorInterface
) -> void:
	print("VSKEditor::setup_editor")

	_uro_toolbar = p_uro_toolbar
	
	if _uro_toolbar:
		_uro_toolbar.setup(self)

	_setup_upload_panel(p_root)
	_setup_progress_panel(p_root)
	_setup_info_panel(p_root)

	_editor_interface = p_editor_interface


##
## Teardown user interfaces
##


func _teardown_progress_panel() -> void:
	print("VSKEditor::_teardown_progress_panel")

	if _vsk_progress_dialog:
		_vsk_progress_dialog.queue_free()


func _teardown_info_panel() -> void:
	print("VSKEditor::_teardown_info_panel")

	if _vsk_info_dialog:
		_vsk_info_dialog.queue_free()


func _teardown_upload_panel() -> void:
	print("VSKEditor::_teardown_upload_panel")

	if _vsk_upload_dialog:
		_vsk_upload_dialog.queue_free()


func teardown_editor():
	print("VSKEditor::teardown_editor")

	if _uro_toolbar:
		_uro_toolbar.teardown()

	_teardown_upload_panel()
	_teardown_progress_panel()
	_teardown_info_panel()


##
## Submission callbacks
##


func _packed_scene_created_callback() -> void:
	print("VSKEditor::_packed_scene_created_callback")

	_vsk_progress_dialog.title = "Scene packaging complete!"
	_vsk_progress_dialog.set_progress_label_text("Scene packaging complete!")
	_vsk_progress_dialog.set_progress_bar_value(100.0)


func _packed_scene_creation_failed_created_callback(p_error_message: String) -> void:
	push_error("VSKEditor::_packed_scene_creation_failed_created_callback: " + p_error_message)

	_vsk_upload_dialog.hide()
	_vsk_progress_dialog.hide()

	_vsk_info_dialog.set_info_text(p_error_message)
	_vsk_info_dialog.popup_centered_ratio()


func _packed_scene_pre_uploading_callback(
	p_packed_scene: PackedScene, p_upload_data: Dictionary, p_callbacks: Dictionary
) -> void:
	"""
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
		var upload_dictionary: Dictionary = _create_upload_dictionary(
			upload_data_name,
			upload_data_description,
			p_packed_scene,
			upload_data_preview_image,
			upload_data_is_public
		)

		if !upload_dictionary.is_empty():
			if database_id == "":
				match type:
					vsk_types_const.UserContentType.Avatar:
						result = await GodotUro.godot_uro_api.dashboard_create_avatar_async(
							upload_dictionary
						)
					vsk_types_const.UserContentType.Map:
						result = await GodotUro.godot_uro_api.dashboard_create_map_async(
							upload_dictionary
						)
			else:
				match type:
					vsk_types_const.UserContentType.Avatar:
						result = await GodotUro.godot_uro_api.dashboard_update_avatar_async(
							database_id, upload_dictionary
						)
					vsk_types_const.UserContentType.Map:
						result = await GodotUro.godot_uro_api.dashboard_update_map_async(
							database_id, upload_dictionary
						)

			if GodotUroHelper.requester_result_is_ok(result):
				var output: Dictionary = result["output"]
				var data: Dictionary = output["data"]
				database_id = data["id"]

				p_callbacks["packed_scene_uploaded"].call(database_id)

				user_content_new_uro_id(node, database_id)
			else:
				p_callbacks["packed_scene_upload_failed"].call(
					(
						"Upload failed with error: %s"
						% GodotUroHelper.get_full_requester_error_string(result)
					)
				)
		else:
			p_callbacks["packed_scene_upload_failed"].call("Could not process upload data!")
	else:
		p_callbacks["packed_scene_upload_failed"].call("Could not load Godot Uro API")
	"""

func _packed_scene_uploaded_callback(p_database_id: String) -> void:
	print("VSKEditor::_packed_scene_uploaded_callback: " + p_database_id)

	_vsk_progress_dialog.hide()
	_vsk_upload_dialog.hide()

	_vsk_info_dialog.set_info_text("Uploaded successfully!")
	_vsk_info_dialog.popup_centered_ratio()


func _packed_scene_upload_failed_callback(p_error_message: String) -> void:
	push_error("VSKEditor::_packed_scene_upload_failed_callback: " + str(p_error_message))

	_vsk_progress_dialog.hide()
	_vsk_upload_dialog.hide()

	_vsk_info_dialog.set_info_text(p_error_message)
	_vsk_info_dialog.popup_centered_ratio()


##
## Tree functions
##

func _enter_tree():
	pass


func _exit_tree():
	teardown_editor()
