@tool
extends Node
class_name SarSoulPlayerMovementComponent

## This class is responsible for taking InputActions values for movement
## from the main Input singleton and translating them into input values used
## by the possessed entity's input component.

func _process(_delta: float) -> void:
	if not Engine.is_editor_hint() and is_multiplayer_authority():
		
		var vessel: SarGameEntityVessel3D = soul.get_possessed_vessel()
		if vessel:
			var input_component: SarGameEntityComponentVesselInput = (vessel.get_game_entity_interface() as SarGameEntityInterfaceVessel3D).get_input_component()
			if not SarUtils.assert_true(input_component, "SarSoulPlayerMovementComponent: input_component is not available"):
				return
			
			if InputMap.has_action("move_left") and InputMap.has_action("move_right"):
				input_component.set_input_value_for_action("horizontal_movement", Input.get_axis("move_left", "move_right"))
			if InputMap.has_action("move_up") and InputMap.has_action("move_down"):
				input_component.set_input_value_for_action("vertical_movement", Input.get_axis("move_up", "move_down"))
			if InputMap.has_action("move_forwards") and InputMap.has_action("move_backwards"):
				input_component.set_input_value_for_action("depth_movement", Input.get_axis("move_backwards", "move_forwards"))

###

## The soul this component is attached to.
@export var soul: SarSoul = null
