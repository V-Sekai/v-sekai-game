@tool
extends SarUIViewController
class_name VSKUIViewControllerSessionLoading

signal scene_loaded(p_resource: Resource)

var _request_object: VSKGameAssetRequest = null

func _request_complete(p_err: VSKGameAssetRequest.AssetError) -> void:
	match p_err:
		VSKGameAssetRequest.AssetError.OK:
			var packed_scene: PackedScene = _request_object.get_resource()
			scene_loaded.emit(packed_scene)
			
	_request_object = null
	
func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		if _request_object:
			if view.progress_bar:
				if _request_object.is_progress_indeterminate():
					view.progress_bar.indeterminate = true
				else:
					view.progress_bar.value = _request_object.get_progress_value()
			if view.progress_label:
				view.progress_label.text = _request_object.get_progress_string()
		else:
			view.progress_bar.value = 0.0
			view.progress_label.text = ""

func _ready() -> void:
	if not Engine.is_editor_hint():
		var asset_manager: VSKGameAssetManager = get_tree().get_first_node_in_group("game_asset_managers")
		if asset_manager:
			_request_object = asset_manager.make_request(content_url, VSKGameAssetManager.AssetType.MAP)
			if not SarUtils.assert_ok(_request_object.request_complete.connect(_request_complete),
				"Could not connect signal '_request_object.request_complete' to '_request_complete'"):
				return
			
###

@export var view: VSKUIViewSessionLoading = null
@export var content_url: String = ""
