@tool
extends Node
class_name SarGameEntityComponent

## A node which is meant to act as a component for a game entity which
## can encapsulate state and/or functionality. Their only common baseline is
## having a reference to the root game_entity.
##
## The requirement for all components to maintain a reference to the game
## entity may not actually be required, so the base component class 
## may eventually be rendered obsolete.

func _get_configuration_warnings() -> PackedStringArray:
	if not game_entity:
		return ['Game entity is not assigned to this component.']
	
	if game_entity is SarGameEntity or game_entity is SarGameEntity3D:
		return PackedStringArray()
	else:
		return ['Game entity is not assigned to this component.']

###

## Reference to the root game entity.
@export var game_entity: Node = null:
	set(p_game_entity):
		game_entity = p_game_entity
		if Engine.is_editor_hint():
			update_configuration_warnings()
