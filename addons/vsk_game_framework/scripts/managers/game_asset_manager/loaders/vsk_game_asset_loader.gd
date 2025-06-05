@tool
extends RefCounted
class_name VSKGameAssetLoader

## A VSKGameAssetLoader provides an abstract interface for loading an asset.
## It should be subclassed in order to provide support for different formats
## which can be loaded and how the asset can be represented, as well as
## implementing safety checks for potentially unsafe assets from unidentified
## sources.

const CACHE_FLAGS: int = ResourceSaver.FLAG_COMPRESS

const FLAG_SKIP_CACHE = 1 << 0
const FLAG_SKIP_VALIDATION = 1 << 1

static func load_and_cache_asset_from_file_path(
	_game_asset_manager: VSKGameAssetManager,
	_path: String,
	_request_url: String,
	_asset_type: VSKGameAssetManager.AssetType,
	_flags: int) -> PackedScene:
	return null
