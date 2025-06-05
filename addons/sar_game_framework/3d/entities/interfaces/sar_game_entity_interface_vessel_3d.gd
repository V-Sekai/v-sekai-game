@tool
extends SarGameEntityInterface3D
class_name SarGameEntityInterfaceVessel3D

## Specialized interface for vessel entities, providing direct access to
## vessel-specific components.
##
## Extends the base interface with movement system integration, possession
## (soul control) management, and input handling capabilities.
## This interface acts as the primary access point for systems interacting
## with vessel functionality while maintaining component encapsulation.

## Reference to the movement component managing physics-based locomotion.
## Handles velocity, collision, and transform synchronization.
@export var movement_component: SarGameEntityComponentVesselMovement3D = null

## Reference to the possession component managing soul attachment/detachment.
## Facilitates control transfer between different controllers (player/AI).
@export var possession_component: SarGameEntityComponentVesselPossession = null

## Reference to the input component translating control signals into actions.
## Bridges between raw input and movement/behavior systems.
@export var input_component: SarGameEntityComponentVesselInput = null

## Returns the movement component for physics-based locomotion.
func get_movement_component() -> SarGameEntityComponentVesselMovement3D:
	return movement_component
	
## Returns the possession component for soul management.
func get_possession_component() -> SarGameEntityComponentVesselPossession:
	return possession_component

## Returns the input component for external control.
func get_input_component() -> SarGameEntityComponentVesselInput:
	return input_component
