@tool
extends SarGameEntityComponent
class_name SarGameEntityComponentPlayerStartLogic

## The component assigns the game entity to the 'player_start' group
## so it can be used as a reference for spawning player entities.

func _enter_tree() -> void:
	if not Engine.is_editor_hint():
		assert(game_entity)
		game_entity.add_to_group("player_start")
