@tool
extends VSKGameAssetRequest
class_name VSKGameAssetRequestUro

const URO_AVATAR_PREFIX: String = "avatar_"
const URO_MAP_PREFIX: String = "map_"
const URO_PROP_PREFIX: String = "prop_"
const URO_GAME_MODE_PREFIX: String = "game_mode_"

var _uro_service_request: SarGameServiceRequest = null
var _http_game_asset_request: VSKGameAssetRequestHTTP = null

static func _get_full_url_for_uro_request(p_domain: String, p_id: String) -> String:
	return "https://" + p_domain + p_id

func _http_request_complete(p_err: AssetError) -> void:
	if p_err == AssetError.OK:
		_resource = _http_game_asset_request.get_resource()
	else:
		_resource = null
		printerr("Uro content HTTP request returned with error code %s" % p_err)
	
	_http_game_asset_request.request_complete.disconnect(_http_request_complete)
	_http_game_asset_request = null
	
	request_complete.emit(p_err)

func _uro_api_request(p_domain: String, p_id: String, p_asset_type: VSKGameAssetManager.AssetType) -> VSKGameAssetRequest:
	if _uro_service_request:
		printerr("Uro service requester is already active.")
		return
	
	var game_service_manager: SarGameServiceManager = _game_asset_manager.get_tree().get_first_node_in_group("game_service_managers")
	if game_service_manager:
		var service: VSKGameServiceUro = game_service_manager.get_service("Uro")
		if service:
			var async_result: Dictionary = {}
			var user_content_type_string: String = ""
			
			var username_and_domain: Dictionary= GodotUroHelper.get_username_and_domain_from_address(service.get_current_account_address())
			username_and_domain["domain"] = p_domain
			
			_uro_service_request = service.create_request(username_and_domain)
			match p_asset_type:
				GodotUroHelper.UroUserContentType.AVATAR:
					async_result = await service.get_avatar_async(_uro_service_request, p_id)
					user_content_type_string = "avatar"
				GodotUroHelper.UroUserContentType.MAP:
					async_result = await service.get_map_async(_uro_service_request, p_id)
					user_content_type_string = "map"
			_uro_service_request = null
			
			if not async_result is Dictionary:
				_complete_request(VSKGameAssetRequest.AssetError.UNKNOWN_FAILURE)
				return

			if not GodotUroHelper.requester_result_is_ok(async_result):
				print("Uro Request for %s returned with error: %s" % [_request_url, GodotUroHelper.get_full_requester_error_string(async_result)])
				_complete_request(VSKGameAssetRequest.AssetError.UNKNOWN_FAILURE)
				return

			print("Uro Request: %s" % str(async_result["output"]))
			var data_valid: bool = false

			var output: Dictionary = async_result.get("output", {})
			if output.has("data"):
				var data: Dictionary = output.get("data", {})
				if data.has(user_content_type_string):
					var user_content: Dictionary = data.get(user_content_type_string, {})
					if user_content.has("user_content_data"):
						var user_content_data: String = user_content.get("user_content_data", "")
						var http_url: String = _get_full_url_for_uro_request(p_domain, user_content_data)
						
						data_valid = true
						
						# TODO: add a flag to indicate that this link is already
						# cache-busted.
						var http_request_obj = _game_asset_manager.make_request(
							http_url,
							_asset_type)
						
						if not SarUtils.assert_ok(http_request_obj.request_complete.connect(_http_request_complete),
							"Could not connect signal 'http_request_obj.request_complete' to '_http_request_complete'"):
							return
						
						return http_request_obj
						
			if not data_valid:
				print("Uro Request for %s data invalid" % _request_url)
				_complete_request(VSKGameAssetRequest.AssetError.INVALID)

	return null


func _execute_uro_file_request(p_domain: String, p_id: String, p_uro_content_type: int) -> void:
	_http_game_asset_request = await _uro_api_request(p_domain, p_id, p_uro_content_type)
	if _http_game_asset_request:
		_http_game_asset_request.execute_request()

func execute_request() -> void:
	var link: String = _request_url.lstrip("uro:///")
	link = _request_url.lstrip("uro://")
	
	var split_link: PackedStringArray = link.split("/")
	if split_link.size() != 2:
		return
	
	var domain = split_link[0]
	var uro_content_type: int = GodotUroHelper.UroUserContentType.UNKNOWN

	# Find the type of asset this Uro link is for
	var id: String = split_link[1]
	match _asset_type:
		VSKGameAssetManager.AssetType.AVATAR:
			id = id.lstrip(URO_AVATAR_PREFIX)
			uro_content_type = GodotUroHelper.UroUserContentType.AVATAR
		VSKGameAssetManager.AssetType.MAP:
			id = id.lstrip(URO_MAP_PREFIX)
			uro_content_type = GodotUroHelper.UroUserContentType.MAP
		_:
			return

	if id.find("/") == -1:
		_execute_uro_file_request(domain, id, uro_content_type)
	
	return

func is_progress_indeterminate() -> bool:
	if _http_game_asset_request:
		return _http_game_asset_request.is_progress_indeterminate()
	
	return super.is_progress_indeterminate()
	
func get_progress_value() -> float:
	if _http_game_asset_request:
		return _http_game_asset_request.get_progress_value()
	
	return super.get_progress_value()
	
func get_progress_string() -> String:
	if _http_game_asset_request:
		return _http_game_asset_request.get_progress_string()
		
	return super.get_progress_string()
