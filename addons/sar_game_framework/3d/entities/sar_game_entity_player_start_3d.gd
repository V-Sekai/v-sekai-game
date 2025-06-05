@tool
extends SarGameEntity3D
class_name SarGameEntity3DPlayerStart

## Helper entity which provides an entry point when spawning player instances.

func get_game_entity_valid_scene_path() -> String:
	return "res://addons/sar_game_framework/3d/entities/sar_game_entity_player_start_3d.tscn"
