@tool
extends VSKGameAssetRequest
class_name VSKGameAssetRequestHTTP

const HTTP_DOWNLOAD_CHUNK_SIZE: int = 65536

const ETAG_FILE_EXTENSION: String = "etag"

var _http_request: HTTPRequest = null

func _clear_http_request_node() -> void:
	if _http_request:
		_http_request.cancel_request()
		_http_request.queue_free()
		_http_request = null

func _full_http_request_completed(p_result: int, p_response_code: int, p_headers: PackedStringArray, _body: PackedByteArray) -> void:
	_clear_http_request_node()
	
	var response_code: VSKGameAssetRequest.AssetError = VSKGameAssetRequest.AssetError.UNKNOWN_FAILURE

	if p_result != OK:
		_complete_request(response_code)
		return
	
	match p_response_code:
		HTTPClient.RESPONSE_OK:
			var base_url: String = _request_url.split("?", true, 1)[0]
			var packed_scene: PackedScene = null
			var download_path: String = "%s/%s" % [_game_asset_manager.get_unvalidated_assets_path(), String(_request_url).sha256_text()]
			
			var resource_type: AssetFormat = _get_resource_type_from_extension(base_url.get_extension())
				
			match resource_type:
				AssetFormat.GLB:
					packed_scene = await VSKGameAssetLoaderGLB.load_and_cache_asset_from_file_path(_game_asset_manager, download_path, _request_url, _asset_type, 0)
				AssetFormat.VRM:
					packed_scene = await VSKGameAssetLoaderVRM.load_and_cache_asset_from_file_path(_game_asset_manager, download_path, _request_url, _asset_type, 0)
				AssetFormat.GODOT_SCENE:
					packed_scene = await VSKGameAssetLoaderGodotScene.load_and_cache_asset_from_file_path(_game_asset_manager, download_path, _request_url, _asset_type, 0)
				
			if packed_scene:
				# Now cache the asset for faster loading in the future.
				var etag_writer_lambda = func():
					# Save etag header
					var etag: String = ""
					for header in p_headers:
						if header.to_lower().begins_with("etag:"):
							etag = header.substr(len("etag:")).strip_edges()
							break
					if not etag.is_empty():
						var etag_path: String = "%s/%s.%s" % [_game_asset_manager.get_asset_cache_path(), String(_request_url).sha256_text(), ETAG_FILE_EXTENSION]
						var etag_file: FileAccess = FileAccess.open(etag_path, FileAccess.WRITE)
						if etag_file:
							etag_file.store_string(etag)
							
				# Wait until the task completes
				var etag_writer_task_id: int = WorkerThreadPool.add_task(etag_writer_lambda)
				while not WorkerThreadPool.is_task_completed(etag_writer_task_id):
					await _game_asset_manager.get_tree().process_frame
				
				_resource = packed_scene
				response_code = VSKGameAssetRequest.AssetError.OK
			else:
				# If we are requesting an avatar, use avatar_not_found_packed_scene
				# as a fallback.
				if _asset_type == VSKGameAssetManager.AssetType.AVATAR:
					_resource = _game_asset_manager.avatar_not_found_packed_scene
				response_code = VSKGameAssetRequest.AssetError.NOT_FOUND
		HTTPClient.RESPONSE_NOT_MODIFIED:
			var cached_file_path: String = "%s/%s.%s" % [_game_asset_manager.get_asset_cache_path(), String(_request_url).sha256_text(), _game_asset_manager.get_cache_file_extension()]
			if ResourceLoader.exists(cached_file_path):
				var request_result: Error = ResourceLoader.load_threaded_request(cached_file_path)
				if request_result == OK:
					while ResourceLoader.load_threaded_get_status(cached_file_path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
						await _game_asset_manager.get_tree().process_frame
					
					if ResourceLoader.load_threaded_get_status(cached_file_path) == ResourceLoader.THREAD_LOAD_LOADED:
						_resource = ResourceLoader.load_threaded_get(cached_file_path)
						_complete_request(VSKGameAssetRequest.AssetError.OK)
						
						return
		HTTPClient.RESPONSE_UNAUTHORIZED:
			_resource = ResourceLoader.load(_game_asset_manager.get_error_path_for_asset_type(_asset_type, VSKGameAssetRequest.AssetError.UNAUTHORIZED))
			response_code = VSKGameAssetRequest.AssetError.FORBIDDEN
		HTTPClient.RESPONSE_FORBIDDEN:
			_resource = ResourceLoader.load(_game_asset_manager.get_error_path_for_asset_type(_asset_type, VSKGameAssetRequest.AssetError.FORBIDDEN))
			response_code = VSKGameAssetRequest.AssetError.FORBIDDEN
		HTTPClient.RESPONSE_NOT_FOUND:
			_resource = ResourceLoader.load(_game_asset_manager.get_error_path_for_asset_type(_asset_type, VSKGameAssetRequest.AssetError.NOT_FOUND))
			response_code = VSKGameAssetRequest.AssetError.NOT_FOUND
		HTTPClient.RESPONSE_IM_A_TEAPOT:
			_resource = ResourceLoader.load(_game_asset_manager.get_error_path_for_asset_type(_asset_type, VSKGameAssetRequest.AssetError.I_AM_A_TEAPOT))
			response_code = VSKGameAssetRequest.AssetError.I_AM_A_TEAPOT
		HTTPClient.RESPONSE_UNAVAILABLE_FOR_LEGAL_REASONS:
			_resource = ResourceLoader.load(_game_asset_manager.get_error_path_for_asset_type(_asset_type, VSKGameAssetRequest.AssetError.UNAVAILABLE_FOR_LEGAL_REASONS))
			response_code = VSKGameAssetRequest.AssetError.UNAVAILABLE_FOR_LEGAL_REASONS
		_:
			_resource = ResourceLoader.load(_game_asset_manager.get_error_path_for_asset_type(_asset_type, VSKGameAssetRequest.AssetError.UNKNOWN_FAILURE))
			response_code = VSKGameAssetRequest.AssetError.UNKNOWN_FAILURE

	_complete_request(response_code)

func _send_get_request(p_skip_etag_validation: bool) -> void:
	var download_path: String = "%s/%s" % [_game_asset_manager.get_unvalidated_assets_path(), String(_request_url).sha256_text()]

	_http_request = HTTPRequest.new()
	_http_request.name = "httpreq"
	_http_request.use_threads = true
	_http_request.download_file = download_path
	_http_request.download_chunk_size = HTTP_DOWNLOAD_CHUNK_SIZE
	_game_asset_manager.add_child(_http_request, true)
	
	var custom_headers: PackedStringArray = PackedStringArray()

	if not p_skip_etag_validation:
		var etag_path: String = "%s/%s.%s" % [_game_asset_manager.get_asset_cache_path(), String(_request_url).sha256_text(), ETAG_FILE_EXTENSION]
		if FileAccess.file_exists(etag_path):
			if FileAccess.file_exists(etag_path):
				var file: FileAccess = FileAccess.open(etag_path, FileAccess.READ)
				if file:
					var stored_etag: String = file.get_as_text().strip_edges()
					custom_headers.append("If-None-Match: " + stored_etag)

	if _http_request.request_completed.connect(self._full_http_request_completed.bind()) != OK:
		printerr("Could not connect signal 'request_complete'!")

	if _http_request.request(_request_url, custom_headers) != OK:
		_resource = ResourceLoader.load(_game_asset_manager.get_error_path_for_asset_type(_asset_type, VSKGameAssetRequest.AssetError.UNKNOWN_FAILURE))
		_complete_request(VSKGameAssetRequest.AssetError.UNKNOWN_FAILURE)

func execute_request() -> void:
	if not _bypass_allow_list and not _game_asset_manager.is_in_allow_list(_request_url, _asset_type):
		_resource = ResourceLoader.load(_game_asset_manager.get_error_path_for_asset_type(_asset_type, VSKGameAssetRequest.AssetError.NOT_IN_ALLOW_LIST))
		_complete_request(VSKGameAssetRequest.AssetError.NOT_IN_ALLOW_LIST)
		return

	_send_get_request(false)
	
func is_progress_indeterminate() -> bool:
	if _http_request:
		return false
	
	return super.is_progress_indeterminate()
	
func get_progress_value() -> float:
	if _http_request:
		return float(_http_request.get_downloaded_bytes()) / float(_http_request.get_body_size())
	
	return super.get_progress_value()
	
func get_progress_string() -> String:
	if _http_request:
		return "Downloading..."
		
	return super.get_progress_string()
	
func cleanup() -> void:
	super.cleanup()
	_clear_http_request_node()
