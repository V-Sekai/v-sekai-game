@tool
extends RefCounted
class_name VSKGameAssetRequest

## A VSKGameAssetRequest object represents a reference to ongoing or complete
## asset request started by the asset manager.
##
## It can be polled to determine how much loaded and if it has loaded, provide
## a direct handle to the loaded resource. It is designed to be abstracted
## in order to faciliate different types of loading operations, either
## from the local disk or the web. It is also intended that it can support
## asset loading with multiple levels of indirection.

enum AssetFormat {
	UNKNOWN,
	GODOT_SCENE,
	GLB,
	VRM
}

enum AssetError {
	OK,
	UNKNOWN_FAILURE,
	UNAUTHORIZED,
	FORBIDDEN,
	NOT_FOUND,
	INVALID,
	I_AM_A_TEAPOT,
	UNAVAILABLE_FOR_LEGAL_REASONS,
	NOT_IN_ALLOW_LIST,
	FAILED_VALIDATION_CHECK,
	RESOURCE_LOAD_FAILED
}

var _game_asset_manager: VSKGameAssetManager = null
var _request_url: String = ""
var _resource: Resource = null
var _asset_type: VSKGameAssetManager.AssetType = VSKGameAssetManager.AssetType.UNKNOWN

var _bypass_allow_list: bool = true

## This signal is emitted when the asset request has fully finished loading
## and caching.
signal request_complete(p_err: AssetError)

func _complete_request(p_response_code: AssetError) -> void:
	request_complete.emit(p_response_code)
	
func _init(p_game_asset_manager: VSKGameAssetManager, p_request_url: String, p_asset_type: VSKGameAssetManager.AssetType) -> void:
	_game_asset_manager = p_game_asset_manager
	_request_url = p_request_url
	_asset_type = p_asset_type

static func _get_resource_type_from_extension(p_extension: String) -> AssetFormat:
	match p_extension:
		"scn":
			return AssetFormat.GODOT_SCENE
		"tscn":
			return AssetFormat.GODOT_SCENE
		"glb":
			return AssetFormat.GLB
		"vrm":
			return AssetFormat.VRM
		_:
			return AssetFormat.UNKNOWN
	
###

func execute_request() -> void:
	pass
	
## Returns true if the current stage in the asset loading operation
## is considered to be indeterminate. If true, you should display
## an ambigious indicator that the asset is loading, but with no specific
## percentage given as to its completion.
func is_progress_indeterminate() -> bool:
	return true
	
## Returns a floating point value between 0.0 and 1.0 representing the 
## completion of the request operation.
func get_progress_value() -> float:
	return 0.0
	
## Returns a string representation of the current progress to provide
## a more detailed description of how complete the asset load operation is.
func get_progress_string() -> String:
	return ""
	
## Returns the resource loaded by this asset request.
func get_resource() -> Resource:
	return _resource
	
## Returns the initial URL string used to execute this load operation. This
## is distinct from where the resource itself may actually end up.
func get_request_url() -> String:
	return _request_url

func cleanup() -> void:
	pass
