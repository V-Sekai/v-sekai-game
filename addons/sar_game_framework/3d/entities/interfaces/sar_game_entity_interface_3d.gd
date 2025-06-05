@tool
extends Node
class_name SarGameEntityInterface3D

## Central hub for entity component management and access. Implements the
## Composition pattern for SarGameEntity3D systems. Acts as component registry,
## dependency injection and a public API facade
##
## Its key responsibilities are to maintain references to an entity's functional
## components, provide component discovery services and mediate entity-component
## communication.

## Reference to the parent entity this interface services. This bidirectional
## link enables components to access their owning entity while maintaining
## encapsulation.
@export var game_entity: SarGameEntity3D = null

## Publicly exposed components that can be accessed through the entity's
## property system. Components here become available via namespaced properties
## (components/[Type]/[Property]) and can be queried through type-based lookups.
@export var public_components: Array[Node] = []

## Returns the parent game entity. Prefer using interface methods over direct
## entity access to maintain component isolation.
func get_game_entity() -> SarGameEntity3D:
	return game_entity

## Component discovery method. Returns all components implementing a specific
## global class type. Enables system-agnostic component access.
func find_components_of_global_class_name(p_type: String) -> Array[Node]:
	var components: Array[Node] = []
	for component: Node in public_components:
		if component.get_script():
			if component.get_script().get_global_name() == p_type:
				components.append(component)
		
	return components
