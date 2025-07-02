# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_editor_dashboard_content_control.gd
# SPDX-License-Identifier: MIT

@tool
extends VSKEditorDashboardTabBodyControl
class_name VSKEditorDashboardContentControl

var _fetch_request: VSKGameServiceRequestUro = null
var _content_dictionary: Dictionary = {}
var _upload_request: SarGameServiceRequest = null

func _fetch_content(_p_service: VSKGameServiceUro, _p_username: String, _p_domain: String) -> Dictionary:
	return {}

func _reload_content() -> void:
	if not content_grid:
		push_error("Not content grid assigned.")
		return
		
	if _fetch_request:
		return
		
	content_grid.clear_all()
	
	var service: VSKGameServiceUro = _get_uro_service()
	if service:
		var current_account_address: String = service.get_current_account_address()
		if current_account_address.is_empty():
			return
		
		var address_dictionary: Dictionary = GodotUroHelper.get_username_and_domain_from_address(current_account_address)
		
		@warning_ignore("redundant_await")
		var async_result: Dictionary = await _fetch_content(service, address_dictionary["username"], address_dictionary["domain"])
		_fetch_request = null
		
		if GodotUroHelper.requester_result_is_ok(async_result):
			var content_list = async_result["output"]["data"]["avatars"]
			_content_dictionary = {}

			for content in content_list:
				var id: String = content["id"]
				
				_content_dictionary[id] = {
					"name": content["name"],
					"description": content["description"],
					"user_content_preview_url":
						address_dictionary["domain"] + content["user_content_preview"],
					"user_content_data_url":
						address_dictionary["domain"] + content["user_content_data"]
				}

				content_grid.add_item(
					id, content["name"], "https://" + address_dictionary["domain"] + content["user_content_preview"]
				)
		else:
			push_error(
				(
					"Dashboard avatars returned with error %s"
					% GodotUroHelper.get_full_requester_error_string(async_result)
				)
			)
			
func _on_content_button_pressed(p_id: String) -> void:
	print(p_id)
	
func _on_upload_progress_dialog_cancel_button_pressed() -> void:
	if _upload_request:
		var service: VSKGameServiceUro = _get_uro_service()
		if service:
			service.stop_request(_upload_request)
			_upload_request = null
			
func _on_fetch_button_pressed() -> void:
	content_grid.clear_all()
	
	fetch_button.disabled = true
	await _reload_content()
	fetch_button.disabled = false

func _process(_delta: float) -> void:
	pass

###

@export var fetch_button: Button = null
@export var content_grid: VSKEditorUserContentGrid = null
@export var upload_file_dialog: FileDialog = null
@export var upload_progress_dialog: VSKEditorProgressDialog = null
