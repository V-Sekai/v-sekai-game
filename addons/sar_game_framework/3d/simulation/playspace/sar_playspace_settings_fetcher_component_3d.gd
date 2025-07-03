@tool
class_name SarPlayspaceSettingsFetcherComponent3D
extends Node

## Helper node designed to live inside a playspace and interpret
## user configuration settings into modifications of the playspace's
## behaviours.

func _update_fov() -> void:
	playspace.camera.fov = 75.0

func _setting_updated(p_setting: String) -> bool:
	if not p_setting:
		return false
		
	return false

func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		_update_fov()

func _ready() -> void:
	if not Engine.is_editor_hint():
		var settings_manager: SarGameSettingsManager = get_tree().get_first_node_in_group("settings_managers")
		if settings_manager:
			if not SarUtils.assert_ok(settings_manager.setting_updated.connect(_setting_updated),
				"Could not connect signal 'settings_manager.setting_updated' to '_setting_updated'"):
				return

###

## The camera container we want to be able to modify.
@export var playspace: SarPlayerSimulationPlayspaceComponent3D = null
