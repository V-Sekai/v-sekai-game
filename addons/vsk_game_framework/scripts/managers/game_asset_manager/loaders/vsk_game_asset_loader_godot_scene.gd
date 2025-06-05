@tool
extends VSKGameAssetLoader
class_name VSKGameAssetLoaderGodotScene

static func load_and_cache_asset_from_file_path(
	p_game_asset_manager: VSKGameAssetManager,
	p_path: String,
	p_request_url: String,
	_asset_type: VSKGameAssetManager.AssetType,
	p_flags: int) -> PackedScene:
	var packed_scene_container: Array[PackedScene] = [null]
	var packed_scene_validator_and_saver_lambda = func():
		if (p_flags & FLAG_SKIP_VALIDATION) or VSKResourceParser.validate_resource(p_path, {}, {}, true):
			var packed_scene: PackedScene = ResourceLoader.load(p_path, "PackedScene", ResourceLoader.CACHE_MODE_REUSE)
			
			if not (p_flags & FLAG_SKIP_CACHE):
				var save_path: String = "%s/%s.%s" % [p_game_asset_manager.get_asset_cache_path(), String(p_request_url as String).sha256_text(), p_game_asset_manager.get_cache_file_extension()]
				ResourceSaver.save(packed_scene, save_path, CACHE_FLAGS)
			
			packed_scene_container[0] = packed_scene
			
	# Wait until the task completes
	var packed_scene_validator_and_saver_task_id: int = WorkerThreadPool.add_task(packed_scene_validator_and_saver_lambda)
	while not WorkerThreadPool.is_task_completed(packed_scene_validator_and_saver_task_id):
		await p_game_asset_manager.get_tree().process_frame
	
	return packed_scene_container[0]
