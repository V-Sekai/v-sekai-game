extends Node
class_name SarGameAssetManager

## The AssetManager class is designed to be a base class for fetching and
## caching assets from external sources, such as GLTF files.

func get_asset_cache_path() -> String:
	return "user://asset_cache"
	
func get_unvalidated_assets_path() -> String:
	return "user://unvalidated_assets"
	
func get_cache_file_extension() -> String:
	return "scn"

var _global_extensions: Array[GLTFDocumentExtension] = []

func _fetch_global_extensions() -> void:
	pass

func _register_global_ingame_extensions() -> void:	
	for extension in _global_extensions:
		GLTFDocument.register_gltf_document_extension(extension, true)
	
func _unregister_global_ingame_extensions() -> void:
	for extension in _global_extensions:
		GLTFDocument.unregister_gltf_document_extension(extension)
	
func _enter_tree() -> void:
	if not Engine.is_editor_hint():
		add_to_group("game_asset_managers")
		
		_fetch_global_extensions()
		
		_register_global_ingame_extensions()
		
func _exit_tree() -> void:
	if not Engine.is_editor_hint():
		_unregister_global_ingame_extensions()
