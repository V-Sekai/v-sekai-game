# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_game_service_vroid.gd
# SPDX-License-Identifier: MIT
@tool
extends SarGameService
class_name VSKGameServiceVroid

enum SessionType {
	NONE = 0, # Null state, API calls don't work
	USER = 2
}

signal vroid_sign_in_completed
signal vroid_sign_in_failed(error: String)

var _godot_vroid: GodotVroid = null
var _current_account_address: String = ""
var _session_mode: SessionType = SessionType.NONE
var _active_service_requests: Dictionary[SarGameServiceRequest, GodotRequester] = {}

# Application Public Client id 
var _app_id: String = ""

const DEFAULT_OAUTH_PORT: int = 8553
var _oauth_listener: OAuthRedirectListener = null

func _update_session(
	p_renewal_token: String,
	p_access_token: String,
	p_username: String,
	p_domain: String
) -> void:
	_current_account_address = ""
	
	if not _godot_vroid:
		return
		
	var token_changed: bool = false
	
	var renewal_token: String = ""
	var access_token: String = ""
	
	var tokens: Dictionary = _godot_vroid.get_tokens(p_username, p_domain)
	renewal_token = tokens.get("renewal_token", "")
	access_token = tokens.get("access_token", "")
	
	if renewal_token != p_renewal_token:
		renewal_token = p_renewal_token
		token_changed = true
	if access_token != p_access_token:
		access_token = p_access_token
		token_changed = true

	_godot_vroid.store_tokens(p_username, p_domain, access_token, renewal_token)
	
	_current_account_address = "%s@%s" % [p_username, p_domain]
	_session_mode = SessionType.USER

	_godot_vroid.store_selected_id(_current_account_address)

	if not token_changed:
		return

func _create_session(p_service_request: VSKGameServiceRequestVroid, p_procesed_result: Dictionary) -> void:
	_update_session(
		p_procesed_result.get("renewal_token", ""),
		p_procesed_result.get("access_token", ""),
		p_procesed_result.get("user_username", ""),
		p_service_request.domain
	)


func _clear_local_session() -> void:
	var address_dict: Dictionary = get_current_username_and_domain()
	
	_current_account_address = ""
	_session_mode = SessionType.NONE
	if _godot_vroid and _godot_vroid.get_api():
		_godot_vroid.clear_tokens(address_dict.get("username", ""), address_dict.get("domain", ""))
		_godot_vroid.store_selected_id("")
	
	return

func _process_result_and_update(p_service_request: VSKGameServiceRequestVroid, p_result: Dictionary) -> Dictionary:
	if _godot_vroid:
		var tokens: Dictionary = _godot_vroid.get_tokens("", "")
		var prev_access_token = tokens.get("access_token", "")
		var prev_renewal_token = tokens.get("renewal_token", "")

		var access_token = p_result.get("access_token", prev_access_token)
		var renewal_token = p_result.get("renewal_token", prev_renewal_token)
		var username = p_result.get("username", "")
		var processed_result={"access_token": access_token, "renewal_token": renewal_token, "user_username": username}

		_create_session(p_service_request, processed_result)

		return {}
	else:
		return {}


func _process_result_and_update_session(p_service_request: SarGameServiceRequest, p_result: Dictionary) -> Dictionary:
	var processed_result: Dictionary = _process_result_and_update(p_service_request, p_result)

	_emit_session_request_complete(p_service_request, processed_result)

	return processed_result


func _get_tokens(p_service_request: SarGameServiceRequest) -> Dictionary:
	if not p_service_request is VSKGameServiceRequestVroid:
		push_error("Did not pass a valid VSKGameServiceRequestVroid object to sign in request.")
		return {}

	var domain: String = (p_service_request as VSKGameServiceRequestVroid).domain
	if domain.is_empty():
		push_error("Did not pass a valid domain to sign in request.")
		return {}
		
	var username: String = (p_service_request as VSKGameServiceRequestVroid).username
	if username.is_empty():
		push_error("Did not pass a valid username to sign in request.")
		return {}
	
	var tokens: Dictionary = _godot_vroid.get_tokens(username, domain)
	
	return tokens


func _get_app_id() -> String:	
	return _app_id


func _get_content_async(p_service_request: SarGameServiceRequest, p_callable: Callable, p_params: Array = []):
	if _godot_vroid and _godot_vroid.get_api():
		if not p_service_request is VSKGameServiceRequestVroid:
			push_error("Did not pass a valid VSKGameServiceRequestVroid object to a content request.")
			return {} 
		
		var domain: String = (p_service_request as VSKGameServiceRequestVroid).domain
		var username: String = (p_service_request as VSKGameServiceRequestVroid).username
		var tokens: Dictionary = _godot_vroid.get_tokens(username, domain)
		var access_token = tokens.get("access_token", "")

		# Add this request to the active request pool.
		var godot_vroid_request: GodotRequester = _godot_vroid.create_requester(domain, -1)
		_active_service_requests[p_service_request] = godot_vroid_request

		var args: Array = [godot_vroid_request, access_token]
		if not p_params.is_empty():
			args.append_array(p_params)

		var result: Dictionary = await p_callable.callv(args)
		
		if not stop_request(p_service_request):
			return {}
			
		if result.is_empty():
			return {}

		return result
		
	return {}

	
## Returns a dictionary containing information about current user.
func get_profile_async(p_service_request: SarGameServiceRequest) -> Dictionary:
	if _godot_vroid and _godot_vroid.get_api():		
		return await _get_content_async(p_service_request, _godot_vroid.get_api().get_profile_async)
	
	return {}

## Returns a dictionary containing information about a specific avatar id.
func get_model_details_async(p_service_request: SarGameServiceRequest, p_id: String) -> Dictionary:
	if _godot_vroid and _godot_vroid.get_api():		
		return await _get_content_async(p_service_request, _godot_vroid.get_api().get_model_details_async, [p_id])
	
	return {}

## Returns a dictionary containing a list of personal uploaded avatars.
func get_uploaded_avatars_async(p_service_request: SarGameServiceRequest, p_filter: Dictionary = {}, p_max_id: String = "", p_count: int = 0) -> Dictionary:
	if _godot_vroid and _godot_vroid.get_api():		
		return await _get_content_async(p_service_request, _godot_vroid.get_api().get_uploaded_avatars_async, [p_filter, p_max_id, p_count])
	
	return {}

## Returns a dictionary containing a list of liked avatars.
func get_liked_avatars_async(p_service_request: SarGameServiceRequest, p_filter: Dictionary = {}, p_max_id: String = "", p_count: int = 0) -> Dictionary:
	if _godot_vroid and _godot_vroid.get_api():		
		var app_id = _get_app_id()
		return await _get_content_async(p_service_request, _godot_vroid.get_api().get_liked_avatars_async, [app_id, p_filter, p_max_id, p_count])
	
	return {}

## Returns a dictionary containing a list of Vroid staff selected avatars.
func get_staff_picks_async(p_service_request: SarGameServiceRequest, p_max_id: String = "", p_count: int = 0) -> Dictionary:
	if _godot_vroid and _godot_vroid.get_api():		
		return await _get_content_async(p_service_request, _godot_vroid.get_api().get_staff_picks_async, [p_max_id, p_count])
	
	return {}

## Search using keyword and filter.
## Returns a dictionary containing a list of avatars.
func search_models_async(p_service_request: SarGameServiceRequest, p_keyword: String, p_filter: Dictionary = {}, p_search_after: String = "", p_sort: String = "", p_count: int = 0) -> Dictionary:
	if _godot_vroid and _godot_vroid.get_api():		
		return await _get_content_async(p_service_request, _godot_vroid.get_api().search_models_async, [p_keyword, p_filter, p_search_after, p_sort, p_count])
	
	return {}

## Search using keyword and filter.
## Returns a dictionary containing a list of avatars.
func get_model_download_url_async(p_service_request: SarGameServiceRequest, p_id: String) -> String:
	if _godot_vroid and _godot_vroid.get_api():
		var license = await _get_content_async(p_service_request, _godot_vroid.get_api().request_download_license_async, [p_id, false])
		var license_id = license.output.data.id
	
		var model: Dictionary = await _get_content_async(p_service_request, _godot_vroid.get_api().request_download_url_async, [license_id])
		var model_url: String = ""
		if model.response_code == 302:
			model_url = model.response_headers.get("location", "")
		else:
			push_error("Unexpected response code from 'request_download_url: %s'" % model.response_code)
		return model_url
		
	return ""

func _ready() -> void:
	add_child(_godot_vroid)

func _init() -> void:
	_godot_vroid = GodotVroid.new()

###

## Returns a dictionary containing the current active account username and domain
## we are signed in with. On failure it will return a dictionary with an empty username
## and domain.
func get_current_username_and_domain() -> Dictionary[String, String]:
	var account_address: String = get_current_account_address()
	var result_dictionary: Dictionary[String, String] = GodotVroidHelper.get_username_and_domain_from_address(account_address)
	return result_dictionary

## Returns a string containing the currently active user account and domain
## we are signed in with.
func get_current_account_address() -> String:
	return _current_account_address

## Returns current SessionType.
func get_current_session_mode() -> SessionType:
	return _session_mode

## Returns the name of the service.
static func get_service_name() -> String:
	return "Vroid"

func _get_uro_service() -> VSKGameServiceUro:
	var service_manager: SarGameServiceManager = get_tree().get_first_node_in_group("game_service_managers")
	if service_manager:
		var uro_service: VSKGameServiceUro = service_manager.get_service("Uro")
		return uro_service
		
	return null

func start_oauth_sign_in() -> Error:
	# TODO: web support for oauth redirect
	if OS.get_name() == "Web":
		push_error("Web platform Vroid API support is not implemented")
		return FAILED

	var godot_uro = _get_uro_service()
	if not SarUtils.assert_true(godot_uro and godot_uro._godot_uro.get_api(),
		"Uro service is not available"):
		return FAILED

	var _username_domain = godot_uro.get_current_username_and_domain()
	var uro_request = godot_uro.create_request(_username_domain)

	var provider = get_service_name().to_lower()
	var result: Dictionary = await godot_uro.get_oauth_redirect(uro_request, provider)
	if not GodotUroHelper.requester_result_is_ok(result):
		push_error("Error fetching redirect url from server: %s" % result.response_code)
		return FAILED
	if not SarUtils.assert_equal(result.is_empty(), false,
		"Could not get OAuth redirect url"):
		return FAILED
	var redirect_url: String = result.output.url

	# Set public app id
	_app_id = SarNetworkUtilities.extract_query_param(redirect_url, "client_id")

	# Start server listener
	_oauth_listener = OAuthRedirectListener.new(DEFAULT_OAUTH_PORT)
	if not SarUtils.assert_ok(_oauth_listener.oauth_redirect_success.connect(_on_oauth_redirect_success),
		"Could not connect signal '_oauth_listener.oauth_redirect_success' to '_on_oauth_redirect_success'"):
		return FAILED
	if not SarUtils.assert_ok(_oauth_listener.oauth_redirect_failure.connect(_on_oauth_redirect_failure),
		"Could not connect signal '_oauth_listener.oauth_redirect_failure' to '_on_oauth_redirect_failure'"):
		return FAILED

	add_child(_oauth_listener)

	if not SarUtils.assert_ok(_oauth_listener.start_listen(),
		"Failed to start OAuth redirect listener"):
		return FAILED

	# Open browser
	var err = FAILED
	if OS.get_name() == "Linux":
		# Prevent thread blocking
		# https://github.com/godotengine/godot/issues/49946
		var pid = OS.create_process("xdg-open", [redirect_url])
		if pid != -1:
			err = OK
	else:
		err = OS.shell_open(redirect_url)
	
	if not SarUtils.assert_ok(err,
		"Failed to start browser at %s" % redirect_url):
		return FAILED

	return OK

func _on_oauth_redirect_success(data) -> void:	
	var vroid_request: VSKGameServiceRequestVroid = create_request({})
	# Set token for first request
	_process_result_and_update_session(vroid_request, data)

	# Update username
	var username: String = ""
	var profile = await get_profile_async(vroid_request)
	if GodotVroidHelper.requester_result_is_ok(profile):
		# Maybe use 'id'?
		username = profile.output.data.user_detail.user.get("name", "")
	else:
		push_error("Could not fetch username")
	data["username"] = username
	_process_result_and_update_session(vroid_request, data)

	if _oauth_listener:
		remove_child(_oauth_listener)
		_oauth_listener.queue_free()
		_oauth_listener = null
	vroid_sign_in_completed.emit()
	return

func _on_oauth_redirect_failure(err) -> void:
	push_error("Vroid OAuth error: %s" % err)
	if _oauth_listener:
		remove_child(_oauth_listener)
		_oauth_listener.queue_free()
		_oauth_listener = null
	vroid_sign_in_failed.emit(err)
	return


## Creates a service request object. This can then be passed into
## into the request API to keep track of the status and callbacks of
## the request.
func create_request(p_data: Dictionary) -> SarGameServiceRequest:
	var service_request: VSKGameServiceRequestVroid = VSKGameServiceRequestVroid.new()
	service_request.username = p_data.get("username", "")
	service_request.domain = GodotVroidHelper.get_domain()
	return service_request

## Will attempt to cancel an ongoing service request. Will return true
## if the request was active and subsequently stopped, and false if
## the request wasn't active and there was nothing to stop.
func stop_request(p_service_request: SarGameServiceRequest) -> bool:
	if is_request_active(p_service_request):
		var godot_vroid_request: GodotRequester = _active_service_requests.get(p_service_request)
		if godot_vroid_request:
			_active_service_requests.erase(p_service_request)
			_godot_vroid.get_api().cancel(godot_vroid_request)
			return true
	
	return super.stop_request(p_service_request)
	
## Returns true if the request is active.
func is_request_active(p_service_request: SarGameServiceRequest) -> bool:
	if _active_service_requests.has(p_service_request):
		return true
	
	return super.is_request_active(p_service_request)

## Gets the selected username and domain for the currently active service
## session from local keystore.
func get_selected_id() -> String:
	return _godot_vroid.load_selected_id()
		
	
