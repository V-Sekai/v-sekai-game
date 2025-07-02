@tool
extends Node3D
class_name SarSimulationVessel3D

## This class is intended to be instantiated by SarGameEntityComponentCharacterSimulation3D and is
## designed to permit and encapsulated simulation space for vessel entities which are entirely
## clientside.
##
## The design implement a set of signal hooks and API callbacks which are setup by the
## SarGameEntityComponentCharacterSimulation3D component where the entity will inform the
## simulation space of events via signal callbacks, as well as permitting the simulation space
## to access information about the vessel entity. It is expected though that simulation spaces
## which instantiate new nodes on the vessel entity will clean these up when the shutdown
## signal is received, as well as keeping track of any modifications to existing nodes which
## so they can be set back to their original state. The design of the simulation space should
## make it easy for designers to implement, for example, very different gameplay logic for
## for players while being able to co-exist in the existing network architecture.

func _on_game_entity_transform_changed(p_new_transform: Transform3D) -> void:
	transform_changed.emit(p_new_transform)

func _on_game_entity_transform_pre_update(p_transform: Transform3D) -> void:
	transform_pre_update.emit(p_transform)
	
func _on_game_entity_transform_post_update(p_transform: Transform3D) -> void:
	transform_post_update.emit(p_transform)

func _on_vessel_possession_component_soul_changed(p_soul: SarSoul) -> void:
	notify_posession_changed(p_soul)

func _on_vessel_movement_component_pre_movement(p_delta: float, p_velocity: Vector3) -> void:
	pre_movement.emit(p_delta, p_velocity)

func _on_vessel_movement_component_post_movement(p_delta: float, p_velocity: Vector3) -> void:
	post_movement.emit(p_delta, p_velocity)
	
func _on_vessel_movement_component_movement_complete(p_delta: float, ) -> void:
	movement_complete.emit(p_delta)

###

## Reference to the callback interface associated with the simulation's
## entity.
var game_entity_interface: SarGameEntityInterfaceVessel3D = null

## Emitted when the currently active game scene has changed.
signal game_scene_changed()

## Emitted when the simulation space is about to be removed and should
## revert all its additional nodes and changes to the game entity back to
## default.
signal shutdown()

## Emitted when the entity's transform has changed.
signal transform_changed(p_transform: Transform3D)
signal transform_pre_update(p_transform: Transform3D)
signal transform_post_update(p_transform: Transform3D)

## Emitted before the movement integration step is about to be executed.
signal pre_movement(p_delta: float, p_velocity: Vector3)
## Emitted after the movement integration step is executed.
signal post_movement(p_delta: float, p_velocity: Vector3)

## Emitted as an additional signal after the post_movement signal has been emitted since components,
## may attempt to do additional integration after the main movement integration step.
signal movement_complete(p_delta: float)

## Emitted when the soul possessing the current vessel has changed.
signal vessel_possession_changed(p_soul: SarSoul)

## Returns the entity's game_entity_interface.
func get_game_entity_interface() -> SarGameEntityInterfaceVessel3D:
	return game_entity_interface

## Assigns the cached reference to the entity's game_entity_interface.
func assign_game_entity_interface(p_gei: SarGameEntityInterfaceVessel3D) -> void:
	game_entity_interface = p_gei
	
## Call to notify the simulation space that the game scene has changed.
func notify_game_scene_changed() -> void:
	game_scene_changed.emit()
	
## Call to notify that we are about to shut down the simulation space.
func notify_shutdown() -> void:
	shutdown.emit()

## Call to notify that the soul possession for this vessel has changed.
func notify_posession_changed(p_soul: SarSoul) -> void:
	vessel_possession_changed.emit(p_soul)

## Returns true if the vessel is currently possessed by a soul.
func is_possessed() -> bool:
	if not SarUtils.assert_true(game_entity_interface, "SarSimulationVessel3D: game_entity_interface is not available"):
		return false
	if game_entity_interface.get_possession_component().get_soul():
		return true
		
	return false
