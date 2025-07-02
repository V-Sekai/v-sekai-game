@tool
extends VSKGameAssetRequest
class_name VSKGameAssetRequestLocal

const HASH_FILE_EXTENSION: String = "localhash"

func execute_request() -> void:
	if _request_url.is_empty():
		_complete_request(AssetError.NOT_FOUND)
		return

	var asset_err: AssetError = AssetError.OK
	
	var extension: String = _request_url.get_extension()
	
	# Derive the type from the file extension.
	var type: AssetFormat = _get_resource_type_from_extension(extension)
	if type == AssetFormat.UNKNOWN:
		_complete_request(VSKGameAssetRequest.AssetError.INVALID)
		return
		
	# For now, only consider local file requests in res://
	if not _request_url.begins_with("res://"):
		_complete_request(VSKGameAssetRequest.AssetError.INVALID)
		return
		
	# If the URL is already locally cached as an internal scene,
	# load it as a scene even if its a GLTF file since we already have
	# this file permenantly cached in the game files. However, we can
	# also choose to import any particular VRM file, which will mean
	# it must be loaded and cached at runtime.
	if ResourceLoader.exists(_request_url, "PackedScene"):
		type = AssetFormat.GODOT_SCENE
		
	var skip_cache: bool = (type == AssetFormat.GODOT_SCENE)

	if _bypass_allow_list or _game_asset_manager.is_in_allow_list(_request_url, _asset_type):
		var stripped_path: String = _request_url.lstrip("file:///")

		var file_exists: bool = FileAccess.file_exists(stripped_path)
		if !file_exists:
			push_error("Local asset not found: %s " % _request_url)
			_resource = _game_asset_manager.avatar_not_found_packed_scene
			asset_err = AssetError.NOT_FOUND
	else:
		_resource = _game_asset_manager.avatar_forbidden_packed_scene
		asset_err = AssetError.NOT_IN_ALLOW_LIST

	if asset_err == AssetError.OK:
		var packed_scene: PackedScene = null
		
		# Perform caching for non scene type resources.
		var file_hash: String = ""
		if not skip_cache:
			var hash_result: Array = [""]
			var hash_reader_lambda = func():
				hash_result[0] = FileAccess.get_md5(_request_url)
						
			# Wait until the task completes
			var hash_reader_task_id: int = WorkerThreadPool.add_task(hash_reader_lambda)
			while not WorkerThreadPool.is_task_completed(hash_reader_task_id):
				await _game_asset_manager.get_tree().process_frame
				
			file_hash = hash_result[0]
			
			var hash_file_path: String = "%s/%s.%s" % [_game_asset_manager.get_asset_cache_path(), String(_request_url).sha256_text(), HASH_FILE_EXTENSION]
			if FileAccess.file_exists(hash_file_path):
				if FileAccess.file_exists(hash_file_path):
					var file: FileAccess = FileAccess.open(hash_file_path, FileAccess.READ)
					if file:
						var stored_file_hash: String = file.get_as_text()
						if file_hash == stored_file_hash:
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
			
		match type:
			AssetFormat.GLB:
				packed_scene = await VSKGameAssetLoaderGLB.load_and_cache_asset_from_file_path(
					_game_asset_manager,
					_request_url,
					_request_url,
					_asset_type,
					0)
			AssetFormat.VRM:
				packed_scene = await VSKGameAssetLoaderVRM.load_and_cache_asset_from_file_path(
					_game_asset_manager,
					_request_url,
					_request_url,
					_asset_type,
					0)
			AssetFormat.GODOT_SCENE:
				packed_scene = await VSKGameAssetLoaderGodotScene.load_and_cache_asset_from_file_path(
					_game_asset_manager,
					_request_url,
					_request_url,
					_asset_type,
					VSKGameAssetLoader.FLAG_SKIP_CACHE | VSKGameAssetLoader.FLAG_SKIP_VALIDATION)
			_:
				asset_err = VSKGameAssetRequest.AssetError.INVALID
		
		# Wait until the task completes
		if not file_hash.is_empty():
			# Now cache the avatar for faster loading in the future.
			var hash_writer_lambda = func():
				# Save etag header
				if not file_hash.is_empty():
					var file_hash_path: String = "%s/%s.%s" % [_game_asset_manager.get_asset_cache_path(), String(_request_url).sha256_text(), HASH_FILE_EXTENSION]
					var file_hash_file: FileAccess = FileAccess.open(file_hash_path, FileAccess.WRITE)
					if file_hash_file:
						file_hash_file.store_string(file_hash)
			
			var hash_writer_task_id: int = WorkerThreadPool.add_task(hash_writer_lambda)
			while not WorkerThreadPool.is_task_completed(hash_writer_task_id):
				await _game_asset_manager.get_tree().process_frame
		
		_resource = packed_scene
		
	if asset_err != AssetError.OK:
		if _asset_type == VSKGameAssetManager.AssetType.AVATAR:
			_resource = _game_asset_manager.avatar_error_packed_scene
		
	_complete_request(asset_err)
	
func get_resource() -> Resource:
	return _resource
