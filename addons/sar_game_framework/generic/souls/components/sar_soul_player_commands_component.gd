@tool
extends Node
class_name SarSoulPlayerCommandsComponent

## This component is respnosible for taking a list of named commands
## from the global Input singleton and translating them to the possessed
## entity's input component.

func _process(_delta: float) -> void:
	if not Engine.is_editor_hint() and is_multiplayer_authority():
		var vessel: SarGameEntityVessel3D = soul.get_possessed_vessel()
		if vessel:
			var input_component: SarGameEntityComponentVesselInput = (vessel.get_game_entity_interface() as SarGameEntityInterfaceVessel3D).get_input_component()
			assert(input_component)
			
			for command: String in commands:
				if InputMap.has_action(command):
					input_component.set_input_value_for_action(command, Input.get_action_strength(command))

###

## A list of commands to translate to the posssessed entity's input component.
@export var commands: Array[String] = []
## The soul this component is attached to.
@export var soul: SarSoul = null
