extends Node
class_name VSKSimulationSceneBoundsDetectorComponent3D

## This class is designed for detecting if the player entity's has gone beyond
## a world boundry point and emitting a signal when this happens.

func _physics_process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		if simulation:
			if not default_bounds.has_point(simulation.get_game_entity_interface().get_game_entity().global_position):
				exited_bounds.emit()

###

## Reference to the root simulation.
@export var simulation: SarSimulationVessel3D = null

## Emitted when it has been detected that the player entity's has crossed
## the bounds.
signal exited_bounds

## The default bounds which the player entity is allowed to exist in.
@export var default_bounds: AABB = AABB()
