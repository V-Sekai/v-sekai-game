@tool
extends Node3D
class_name SarGameScene3D

## A meta class which should be placed on the root node of a scene
## to denote that it is a valid game scene for the game session
## managers.

func _ready() -> void:
	if not Engine.is_editor_hint():
		get_tree().call_group("game_session_managers", "notify_game_scene_changed")
