@tool
extends Node
class_name SarGameEntityInterface

## Reference to the actual game entity.
@export var game_entity: SarGameEntity = null

## A list of components which the game entity should attempt to mirror
## the public properties onto the root node.
@export var public_components: Array[Node] = []

## Returns the game entity.
func get_game_entity() -> SarGameEntity:
	return game_entity

## Finds and returns all the components with the global name matching p_type.
func find_components_of_global_class_name(p_type: String) -> Array[Node]:
	var components: Array[Node] = []
	for component: Node in public_components:
		if component.get_script():
			if component.get_script().get_global_name() == p_type:
				components.append(component)
		
	return components
