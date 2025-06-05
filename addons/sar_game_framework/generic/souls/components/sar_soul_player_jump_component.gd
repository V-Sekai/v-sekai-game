@tool
extends Node
class_name SarSoulPlayerJumpComponent

## A component attached to a SarSoul responsible for taking the jump
## action from the global Input singleton and translating it to the
## possessed entity's input component.

func _input(p_event: InputEvent) -> void:
	if not Engine.is_editor_hint() and is_multiplayer_authority():
		var vessel: SarGameEntityVessel3D = soul.get_possessed_vessel()
		if vessel:
			var input_component: SarGameEntityComponentVesselInput = (vessel.get_game_entity_interface() as SarGameEntityInterfaceVessel3D).get_input_component()
			if input_component:
				if p_event.is_action("jump"):
					input_component.set_input_value_for_action("jump", p_event.get_action_strength("jump"))

###

## The soul this component is attached to.
@export var soul: SarSoul = null
