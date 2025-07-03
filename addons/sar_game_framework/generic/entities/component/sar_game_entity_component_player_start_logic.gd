@tool
extends SarGameEntityComponent
class_name SarGameEntityComponentPlayerStartLogic

## The component assigns the game entity to the 'player_start' group
## so it can be used as a reference for spawning player entities.

func _enter_tree() -> void:
	if not Engine.is_editor_hint():
		if not SarUtils.assert_true(game_entity, "SarGameEntityComponentPlayerStartLogic: game_entity is not available"):
			return
		game_entity.add_to_group("player_start")
