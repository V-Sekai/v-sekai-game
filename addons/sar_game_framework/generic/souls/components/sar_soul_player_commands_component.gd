@tool
extends Node
class_name SarSoulPlayerCommandsComponent

## This component is responsible for taking a list of named commands
## from the global Input singleton and translating them to the possessed
## entity's input component.

var active_commands: Dictionary = {}

func _input(p_event: InputEvent) -> void:
	if not Engine.is_editor_hint() and is_multiplayer_authority():
		var vessel: SarGameEntityVessel3D = soul.get_possessed_vessel()
		if vessel:
			var input_component: SarGameEntityComponentVesselInput = (vessel.get_game_entity_interface() as SarGameEntityInterfaceVessel3D).get_input_component()
			assert(input_component)

			# Workaround to persist action for one _process() frame in SarGameEntityComponentVesselInput _input_table
			# This is needed because _input_table is processed with _physics_process() -> _update_input() in VSKPlayerSimulationInputComponent
			for command: String in commands:
				if InputMap.has_action(command) and p_event.is_action_pressed(command) and not p_event.is_echo():
					var strength = Input.get_action_strength(command)
					active_commands[command] = {"time": Time.get_ticks_usec() / 1_000_000.0, "strength": strength}
					input_component.set_input_value_for_action(command, strength)

func _physics_process(delta: float):
	if not Engine.is_editor_hint() and is_multiplayer_authority():
		var vessel: SarGameEntityVessel3D = soul.get_possessed_vessel()
		if vessel:
			var input_component: SarGameEntityComponentVesselInput = (vessel.get_game_entity_interface() as SarGameEntityInterfaceVessel3D).get_input_component()
			assert(input_component)
			var time = Time.get_ticks_usec() / 1_000_000.0
			for command in active_commands:
					var trigger_time = active_commands[command].get("time")
					if time > (trigger_time + delta):
						input_component.set_input_value_for_action(command, 0.0)
						active_commands.erase(command)

## A list of commands to translate to the posssessed entity's input component.
@export var commands: Array[String] = []
## The soul this component is attached to.
@export var soul: SarSoul = null
