@tool
extends SarPlayerSimulationInputComponent
class_name VSKPlayerSimulationInputComponent

signal respawn_requested()
signal menu_toggle_requested()

func _update_input(p_input_component: SarGameEntityComponentVesselInput, p_disabled: bool) -> void:
	super._update_input(p_input_component, p_disabled)

	if not p_disabled:
		if p_input_component.is_action_just_pressed("request_respawn"):
			respawn_requested.emit()
	
	if p_input_component.is_action_just_pressed("menu"):
		menu_toggle_requested.emit()
