# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_editor_dashboard_avatars_control.gd
# SPDX-License-Identifier: MIT

@tool
extends VSKEditorDashboardContentControl
class_name VSKEditorDashboardAvatarsControl

func _fetch_content(p_service: VSKGameServiceUro, p_username: String, p_domain: String) -> Dictionary:
	_fetch_request = p_service.create_request({"username":p_username, "domain":p_domain})
	var async_result: Dictionary = await p_service.get_dashboard_avatars_async(_fetch_request)
	return async_result

func _on_upload_button_pressed() -> void:
	if upload_file_dialog:
		upload_file_dialog.popup_centered()
	else:
		printerr("No file dialog assigned.")

func _upload_vrm(p_path: String) -> void:
	if _upload_request:
		printerr("Upload is already in progress.")
		return
		
	if not FileAccess.file_exists(p_path):
		printerr("File at path %s does not exist." % p_path)
		return
	
	print("Attempting to upload %s" % p_path)
	
	var gltf_document: GLTFDocument = GLTFDocument.new()
	var gltf_state: GLTFState = GLTFState.new()
	var error: Error = gltf_document.append_from_file(p_path, gltf_state)
	if error == OK:
		var json: Dictionary = gltf_state.json
		if not json.is_empty():
			var extensions: Dictionary = json.get("extensions", {})
			var vrm: Dictionary = extensions.get("VRM", {})
			var meta: Dictionary = vrm.get("meta", {})
			
			var allowed_user_name: String = meta.get("allowedUserName", "")
			var commercial_usage_name: String = meta.get("commercialUssageName", "")
			var contact_information: String = meta.get("contactInformation", "")
			var license_name: String = meta.get("licenseName", "")
			var author: String = meta.get("title", "")
			var title: String = meta.get("title", "")
			var version: String = meta.get("version", "")
			var thumbnail_texture_id: int = meta.get("texture", -1)

			var images: Array[Texture2D] = gltf_state.get_images()
			
			var thumbnail_image: Image = null
			
			if thumbnail_texture_id >= 0 and thumbnail_texture_id < images.size():
				var thumbnail_texture: Texture2D = images[thumbnail_texture_id]
				if thumbnail_texture:
					thumbnail_image = thumbnail_texture.get_image()
				
			var service: VSKGameServiceUro = _get_uro_service()
			if service:
				var username_and_domain: Dictionary= GodotUroHelper.get_username_and_domain_from_address(service.get_current_account_address())
				var upload_dictionary: Dictionary = GodotUroHelper.create_content_upload_dictionary(title, "", p_path, thumbnail_image, false)
				if upload_dictionary.is_empty():
					printerr("Upload dictionary for VRM file %s returned empty." % p_path)
					return
				
				upload_button.disabled = true
				upload_progress_dialog.popup_centered_clamped(Vector2i(300, 200))
				
				print("Uploading VRM for %s" % service.get_current_account_address())
				_upload_request = service.create_request(username_and_domain)
				var result: Dictionary = await service.upload_avatar_async(_upload_request, upload_dictionary)
				_upload_request = null
				
				upload_button.disabled = false
				upload_progress_dialog.hide()
				
				if GodotUroHelper.requester_result_is_ok(result):
					print("Upload was successful.")
				else:
					printerr("Requester code %s" % str(result.get("requester_code", GodotUroHelper.RequesterCode.UNKNOWN_STATUS_ERROR)))
			else:
				printerr("Could not accquire Uro service.")
		else:
			printerr("VRM file %s JSON is empty" % p_path)
	else:
		printerr("VRM file %s returned with a parse error code: %s" % [p_path, str(error)])
		
func _on_upload_file_dialog_files_selected(p_paths: PackedStringArray) -> void:
	print("Upload multiple")
	for path: String in p_paths:
		_upload_vrm(path)

func _on_upload_file_dialog_file_selected(p_path: String) -> void:
	print("Upload single")
	_upload_vrm(p_path)

###

@export var upload_button: Button = null
