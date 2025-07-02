@tool
extends SarGameEntityComponent
class_name VSKGameEntityComponentAvatarLoader

## This component is intended to be an interface to a VSKGameAssetManager
## for loading avatars.
##
## The component is responsible for making asset requests when it receives
## signals that the entity's asset path has changed. When it receives a
## call to `_on_requested_avatar_path_changed` with a new path,
## it will request that the VSKGameAssetManager fetch the desired asset
## if the asset path passes validation if it belongs to a remote peer,
## (for example, disallowing local abitrary asset paths on remote peers).

var _requested_avatar_path: String = ""
var _current_asset_request: VSKGameAssetRequest = null

# This method is only called on non-authoritive peers and is
# meant to validate that the path for the avatar is correct.
# It will, for example, refuse local file requests since those
# would not be replictable to remote peers.
func _validate_remote_request_path(p_request_path: String) -> bool:
	if p_request_path.begins_with("https://") or \
	p_request_path.begins_with("http://"):
		return true
		
	return false

# Callback method for when the asset request is complete. When received,
# it will get resource, disconnect the request_complete signal, and set the model
# on the model component.
func _on_request_complete(p_asset_err: VSKGameAssetRequest.AssetError) -> void:
	var packed_scene: PackedScene = _current_asset_request.get_resource()
	
	# Clean up the existing asset request.
	if _current_asset_request:
		if _current_asset_request.request_complete.is_connected(_on_request_complete):
			_current_asset_request.request_complete.disconnect(_on_request_complete)
		_current_asset_request = null

	if not SarUtils.assert_true(avatar_component, "VSKGameEntityComponentAvatarLoader._on_request_complete: avatar_component is not available"):
		return

	if p_asset_err == VSKGameAssetRequest.AssetError.OK:
		avatar_component.set_model_scene(packed_scene)
	else:
		var game_asset_manager: VSKGameAssetManager = get_tree().get_first_node_in_group("game_asset_managers")
		if game_asset_manager:
			var error_avatar_path: String = game_asset_manager.get_error_path_for_asset_type(VSKGameAssetManager.AssetType.AVATAR, p_asset_err)
			var error_avatar_scene: PackedScene = null
			if not error_avatar_path.is_empty():
				error_avatar_scene = ResourceLoader.load(error_avatar_path)
				avatar_component.set_model_scene(error_avatar_scene)
		else:
			printerr("Could not access game asset manager")
			avatar_component.set_model_scene(null)
			
# Called when a new avatar request is made.
func _request_avatar_asset() -> void:
	# Find if we have an asset manager.
	var game_asset_manager: VSKGameAssetManager = get_tree().get_first_node_in_group("game_asset_managers")
	if game_asset_manager:
		# If we already have a pending asset request, disconnect it
		# and attempt to cancel it.
		if _current_asset_request:
			if _current_asset_request.request_complete.is_connected(_on_request_complete):
				_current_asset_request.request_complete.disconnect(_on_request_complete)
			game_asset_manager.attempt_to_cancel_request(_current_asset_request.get_request_url())
			_current_asset_request = null
		
		# By default we assume a request is valid.
		var is_request_path_valid: bool = true
		if _requested_avatar_path:
			# For the remote peers only, check if the avatar request is actually
			# valid before attempting to load it.
			if not is_multiplayer_authority():
				is_request_path_valid = _validate_remote_request_path(_requested_avatar_path)
			
			# If the request path is valid, make the request to the asset manager.
			if is_request_path_valid:
				_current_asset_request = game_asset_manager.make_request(_requested_avatar_path, VSKGameAssetManager.AssetType.AVATAR)
		
		if not SarUtils.assert_true(avatar_component, "VSKGameEntityComponentAvatarLoader._request_avatar_asset: avatar_component is not available"):
			return
		
		if not is_request_path_valid:
			# If the request path is NOT valid, forcefully change the avatar the error placeholder.
			avatar_component.set_model_scene(game_asset_manager.avatar_error_packed_scene)
		else:
			# The request is valid, but first, set the avatar to the loading avatar.
			avatar_component.set_model_scene(game_asset_manager.loading_avatar_packed_scene)
			
			# Finally, wire up the callback signal for when the request is complete.
			if _current_asset_request:
				if not SarUtils.assert_ok(_current_asset_request.request_complete.connect(_on_request_complete),
					"Could not connect signal '_current_asset_request.request_complete' to '_on_request_complete'"):
					return
			else:
				avatar_component.set_model_scene(game_asset_manager.avatar_error_packed_scene)
				printerr("Could not create request object for path %s" % _requested_avatar_path)
	else:
		# This shouldn't happen, if we have the VSKGameAssetManager available as a signal.
		printerr("Could not locate a valid VSKGameAssetManager. The custom avatar at %s cannot be loaded." % _requested_avatar_path)

# Called when the request avatar path has changed and a new asset
# request should be made.
func _on_requested_avatar_path_changed(p_new_path: String) -> void:
	_requested_avatar_path = p_new_path
	
	if is_node_ready():
		_request_avatar_asset()

# By default, assign the loading avatar to this player while we wait
# for their actual avatar to appear.
func _ready() -> void:
	if not Engine.is_editor_hint():
		var game_asset_manager: VSKGameAssetManager = get_tree().get_first_node_in_group("game_asset_managers")
		if game_asset_manager:
			if not SarUtils.assert_true(avatar_component, "VSKGameEntityComponentAvatarLoader: avatar_component is not available"):
				return
			avatar_component.set_model_scene(game_asset_manager.loading_avatar_packed_scene)
		
		if _requested_avatar_path:
			_request_avatar_asset()
			
###

## The model component used by this game entity.
@export var avatar_component: SarGameEntityComponentAvatar3D = null
