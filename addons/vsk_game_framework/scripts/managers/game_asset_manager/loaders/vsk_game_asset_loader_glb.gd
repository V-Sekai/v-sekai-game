@tool
extends VSKGameAssetLoader
class_name VSKGameAssetLoaderGLB

static func _load_from_local_gltf_document_from_path(p_path: String, p_additional_data_table: Dictionary[StringName, Variant]) -> Node3D:
	var asset_root_node: Node3D = null
	
	var gltf_document: GLTFDocument = GLTFDocument.new()
	
	var gltf_state: GLTFState = GLTFState.new()

	for key: String in p_additional_data_table:
		gltf_state.set_additional_data(key, p_additional_data_table[key])
		
	var error: Error = gltf_document.append_from_file(p_path, gltf_state)
	if error == OK:
		asset_root_node = gltf_document.generate_scene(gltf_state)
	else:
		printerr("Failed to load GLTF scene. Returned error code %s" % str(error))

	return asset_root_node
		
static func load_glb_asset_from_path(p_game_asset_manager: VSKGameAssetManager, p_path: String, p_additional_data_table: Dictionary[StringName, Variant]) -> PackedScene:
	# Couldn't find it in the cache, so generate it from GLTF documents.
	var asset_container: Array[Node3D] = [null]  # Single-element array to hold the result
	var glb_loader_lambda = func():
		asset_container[0] = _load_from_local_gltf_document_from_path(p_path, p_additional_data_table)
	
	# Wait until the task completes
	var glb_loader_task_id: int = WorkerThreadPool.add_task(glb_loader_lambda, false, "")
	while not WorkerThreadPool.is_task_completed(glb_loader_task_id):
		await p_game_asset_manager.get_tree().process_frame
	
	var packed_scene_container: Array[PackedScene] = [null]
	if asset_container[0]:
		var glb_saver_lambda = func():
			var packed_scene: PackedScene = PackedScene.new()
			var error: Error = packed_scene.pack(asset_container[0])
			if error == OK:
				packed_scene_container[0] = packed_scene
			else:
				printerr("Failed to pack cached GLTF scene. Returned error code %s" % str(error))
				
		# Wait until the task completes
		var glb_saver_task_id: int = WorkerThreadPool.add_task(glb_saver_lambda)
		while not WorkerThreadPool.is_task_completed(glb_saver_task_id):
			await p_game_asset_manager.get_tree().process_frame

	return packed_scene_container[0]
	
static func _get_additional_data_for_type(_asset_type: VSKGameAssetManager.AssetType) -> Dictionary[StringName, Variant]:
	var additional_data_table: Dictionary[StringName, Variant] = {}
	return additional_data_table

static func _load_and_cache_asset_from_file_path_internal(
	p_game_asset_manager: VSKGameAssetManager,
	p_path: String,
	p_request_url: String,
	p_asset_type: VSKGameAssetManager.AssetType,
	p_flags: int,
	p_additional_data_callable: Callable) -> PackedScene:
		
	var packed_scene: PackedScene = null
	var additional_data_table: Dictionary[StringName, Variant] = p_additional_data_callable.call(p_asset_type)
	match p_asset_type:
		VSKGameAssetManager.AssetType.AVATAR:
			packed_scene = await load_glb_asset_from_path(p_game_asset_manager, p_path, additional_data_table)
			if not (p_flags & FLAG_SKIP_CACHE):
				var packed_scene_saver_lambda = func():
					var save_path: String = "%s/%s.%s" % [
						p_game_asset_manager.get_asset_cache_path(),
						String(p_request_url as String).sha256_text(),
						p_game_asset_manager.get_cache_file_extension()]
						
					var error: Error = ResourceSaver.save(packed_scene, save_path, CACHE_FLAGS)
					if error != OK:
						printerr("Failed to save cached GLTF scene. Returned error code %s" % str(error))
				
				# Wait until the task completes
				var packed_scene_saver_task_id: int = WorkerThreadPool.add_task(packed_scene_saver_lambda)
				while not WorkerThreadPool.is_task_completed(packed_scene_saver_task_id):
					await p_game_asset_manager.get_tree().process_frame
				
	return packed_scene

static func load_and_cache_asset_from_file_path(
	p_game_asset_manager: VSKGameAssetManager,
	p_path: String,
	p_request_url: String,
	p_asset_type: VSKGameAssetManager.AssetType,
	p_flags: int) -> PackedScene:
		
	return await _load_and_cache_asset_from_file_path_internal(
		p_game_asset_manager,
		p_path,
		p_request_url,
		p_asset_type,
		p_flags,
		_get_additional_data_for_type)
