@tool
extends SarSimulationVessel3D
class_name SarSimulationCharacter3D

## Subclass of SarSimulationVessel3D intended to be used for character entities.

func _on_character_model_component_model_changed(p_new_model: SarModel3D) -> void:
	model_changed.emit(p_new_model)

func _on_character_model_component_pre_model_changed(p_new_model: SarModel3D) -> void:
	model_pre_changed.emit(p_new_model)
	
###

## Emitted when the game entity's model has changed.
signal model_changed(p_new_model: SarModel3D)
## Emitted before the game entity's model changes.
signal model_pre_changed(p_new_model: SarModel3D)

## Returns the entity's game_entity_interface.
func get_game_entity_interface() -> SarGameEntityInterfaceCharacter3D:
	return game_entity_interface

## Assigns the cached reference to the entity's game_entity_interface.
func assign_game_entity_interface(p_gei: SarGameEntityInterfaceVessel3D) -> void:
	if p_gei is not SarGameEntityInterfaceCharacter3D:
		push_error("The game entity interface assigned to a SarSimulationCharacter3D is not valid.")
	
	game_entity_interface = p_gei
