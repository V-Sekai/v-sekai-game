# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_editor_uro_toolbar_container.gd
# SPDX-License-Identifier: MIT

@tool
extends HBoxContainer
class_name VSKEditorUroToolbarContainer

var _request: SarGameServiceRequest = null

func _on_sign_in_button_pressed() -> void:
	sign_in_window.hide()
	sign_in_window.popup_centered(Vector2i(300, 500))

enum State {
	PENDING,
	NOT_SIGNED_IN,
	SIGNED_IN
}

func _get_uro_service() -> VSKGameServiceUro:
	var service_manager: VSKGameServiceManager = get_tree().get_first_node_in_group("game_service_managers")
	if service_manager:
		var service: VSKGameServiceUro = service_manager.get_service("Uro")
		return service
		
	return null
		
func _update_state(p_state: State) -> void:
	match p_state:
		State.PENDING:
			if pending_control:
				pending_control.show()
			if sign_in_button:
				sign_in_button.hide()
			if account_options_control:
				account_options_control.hide()
		State.NOT_SIGNED_IN:
			if pending_control:
				pending_control.hide()
			if sign_in_button:
				sign_in_button.show()
			if account_options_control:
				account_options_control.hide()
			if sign_in_window:
				sign_in_window.hide()
		State.SIGNED_IN:
			if pending_control:
				pending_control.hide()
			if sign_in_button:
				sign_in_button.hide()
			if account_options_control:
				account_options_control.show()
	
func _on_sign_in_session_request_successful() -> void:
	_update_state(State.SIGNED_IN)
	
	sign_in_window.hide()
	
	# Change the tooltip text to match the account address.
	if account_options_button:
		var service: VSKGameServiceUro = _get_uro_service()
		account_options_button.tooltip_text = service.get_current_account_address()
	
func _node_added(p_node: Node) -> void:
	if p_node is VSKGameServiceManager:
		_attempt_service_access()
	
func _attempt_service_access() -> void:
	if get_tree().node_added.is_connected(_node_added):
		get_tree().node_added.disconnect(_node_added)
	
	var service: VSKGameServiceUro = _get_uro_service()
	if service:
		var id: String = service.get_selected_id()
		var address_dictionary: Dictionary[String, String] = GodotUroHelper.get_username_and_domain_from_address(id)
		if not (address_dictionary["username"].is_empty() and address_dictionary["domain"].is_empty()):
			var username: String = address_dictionary["username"]
			var domain: String = address_dictionary["domain"]
			
			if sign_in_window:
				if sign_in_window.vsk_editor_sign_in_dialog_control:
					sign_in_window.vsk_editor_sign_in_dialog_control.update_fields(domain, username, "")
			
			var result: Dictionary = await renew_session(domain, username)
			if GodotUroHelper.requester_result_is_ok(result):
				_update_state(State.SIGNED_IN)
				return
	
		_update_state(State.NOT_SIGNED_IN)
		
		return
		
	# No service managers? Register a callback so we can wait for one to be added.
	if not get_tree().node_added.is_connected(_node_added):
		if not SarUtils.assert_ok(get_tree().node_added.connect(_node_added),
			"Could not connect signal 'get_tree().node_added' to '_node_added'"):
			return
			
func _account_id_option_pressed(p_id: int) -> void:
	match p_id:
		# Dashboard Option
		0:
			if dashboard_window:
				dashboard_window.hide()
				dashboard_window.popup_centered_ratio()
			else:
				push_error("Dashboard window is not assigned.")
		# Sign Out Option
		99:
			var service: VSKGameServiceUro = _get_uro_service()
			if service:
				var address_dictionary: Dictionary[String, String] = GodotUroHelper.get_username_and_domain_from_address(service.get_current_account_address())
				if not (address_dictionary["username"].is_empty() and address_dictionary["domain"].is_empty()):
					var username: String = address_dictionary["username"]
					var domain: String = address_dictionary["domain"]
					
					_update_state(State.PENDING)
					
					var processed_result: Dictionary = await sign_out(domain, username)
					
					if GodotUroHelper.requester_result_is_ok(processed_result):
						_update_state(State.NOT_SIGNED_IN)
					else:
						# If the attempt to formally sign out failed, attempt
						# to restore state with whatever we might have cached.
						_attempt_service_access()
		_:
			pass
			
func _ready() -> void:
	if not get_tree().edited_scene_root:
		if not SarUtils.assert_ok(account_options_button.get_popup().id_pressed.connect(_account_id_option_pressed),
			"Could not connect signal 'account_options_button.get_popup().id_pressed' to '_account_id_option_pressed'"):
			return
		
		_update_state(State.PENDING)
		_attempt_service_access()
###

@export var sign_in_window: VSKEditorSignInDialog = null
@export var dashboard_window: VSKEditorDashboardDialog = null

@export var pending_control: Control = null
@export var info_label: Label = null
@export var sign_in_button: Button = null
@export var account_options_button: MenuButton = null
@export var account_options_control: Control

func setup(_vsk_editor: VSKEditor) -> void:
	sign_in_window.setup(self)
	
func teardown() -> void:
	sign_in_window.teardown(self)
	
func sign_in(p_domain: String, p_username_or_email: String, p_password: String) -> Dictionary:
	if _request:
		push_error("A request is already active.")
		return {}

	var service: VSKGameServiceUro = _get_uro_service()
	if service:
		_request = service.create_request({"domain":p_domain})
		var processed_result: Dictionary = await service.sign_in(_request, {"username_or_email":p_username_or_email, "password":p_password})
		_request = null
		
		if processed_result.has("response_code") and \
		processed_result.has("message"):
			return processed_result
			
	return {}

func cancel_sign_in() -> void:
	if _request:
		var service: VSKGameServiceUro = _get_uro_service()
		if service:
			if service:
				if service.stop_request(_request):
					_request = null
				else:
					push_error("Could not cancel request" % str(_request))
					
func renew_session(p_domain: String, p_username: String) -> Dictionary:
	if _request:
		push_error("A request is already active.")
		return {}
		
	if p_domain.is_empty():
		push_error("domain is empty")
		return {}
		
	if p_username.is_empty():
		push_error("username is empty")
		return {}
		
	var service: VSKGameServiceUro = _get_uro_service()
	if service:
		_request = service.create_request({"username":p_username, "domain":p_domain})
		var result: Dictionary = await service.renew_session(_request)
		_request = null
		return result

	return {}

func sign_out(p_domain: String, p_username: String) -> Dictionary:
	if _request:
		push_error("A request is already active.")
		return {}
	
	var service: VSKGameServiceUro = _get_uro_service()
	if service:
		_request = service.create_request({"username":p_username, "domain":p_domain})
		var result: Dictionary = await service.sign_out(_request)
		_request = null
		return result
		
	return {}
