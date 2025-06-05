@tool
extends SarGameEntityInterfaceVessel3D
class_name SarGameEntityInterfaceCharacter3D

## Specialized interface for character entities, extending vessel functionality
## with model management. 
##
## Serves as the primary access point for systems interacting with
## character-specific functionality while maintaining component encapsulation.

## Reference to the model component managing the character's visual
## representation. Handles model instantiation, attachment points, and
## visual state.
@export var model_component: SarGameEntityComponentModel3D = null

## Returns the model component for visual representation management.
func get_model_component() -> SarGameEntityComponentModel3D:
	return model_component
