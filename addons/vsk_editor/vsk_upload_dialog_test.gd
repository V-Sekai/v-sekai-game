# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_upload_dialog_test.gd
# SPDX-License-Identifier: MIT

extends Control

const vsk_types_const = preload("res://addons/vsk_importer_exporter/vsk_types.gd")


func export_data() -> Dictionary:
	return {}


func _on_ShowDialogButton_pressed():
	var vsk_editor: Node = get_node_or_null("/root/VSKEditor")
	if vsk_editor:
		var func_ref: Callable = self.export_data

		vsk_editor.show_upload_panel(func_ref, vsk_types_const.UserContentType.Avatar)
	else:
		push_error("Could not load VSKEditor")


func _ready():
	var vsk_editor: Node = get_node_or_null("/root/VSKEditor")
	if vsk_editor:
		vsk_editor.setup_editor(self, null, null)
	else:
		push_error("Could not load VSKEditor")


static func generate_test_image() -> Dictionary:
	var new_image: Image = Image.new()
	new_image.resize(128, 128, Image.INTERPOLATE_NEAREST)

	return {"filename": "autogen.png", "content_type": "image/png", "data": new_image.save_png_to_buffer()}


static func generate_test_binary_data() -> Dictionary:
	var data: PackedByteArray = "TestBinary".to_utf8_buffer()

	return {"filename": "autogen.scn", "content_type": "application/octet-stream", "data": data}


func _on_TestUploadButton_pressed():
	if GodotUro.godot_uro_api:
		var result = await (GodotUro.godot_uro_api.dashboard_create_avatar_async({"name": "test_avatar", "description": "test_avatar_description", "user_content_data": generate_test_binary_data(), "user_content_preview": generate_test_image()}))

		print(result)
