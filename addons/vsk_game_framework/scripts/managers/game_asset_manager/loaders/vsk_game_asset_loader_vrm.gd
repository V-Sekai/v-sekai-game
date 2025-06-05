@tool
extends VSKGameAssetLoaderGLB
class_name VSKGameAssetLoaderVRM

static func _get_additional_data_for_type(p_asset_type: VSKGameAssetManager.AssetType) -> Dictionary[StringName, Variant]:
	var additional_data_table: Dictionary[StringName, Variant] = {}
	
	match p_asset_type:
		VSKGameAssetManager.AssetType.AVATAR:
			#additional_data_table["vrm/already_processed"] = false
			additional_data_table["vrm/head_hiding_method"] = 3 # Layers
			additional_data_table["vrm/first_person_layers"] = (1 << 1)
			additional_data_table["vrm/third_person_layers"] = (1 << 2)
		_:
			additional_data_table["vrm/already_processed"] = true
	
	return additional_data_table

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
