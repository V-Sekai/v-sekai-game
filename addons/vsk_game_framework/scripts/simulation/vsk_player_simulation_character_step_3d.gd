@tool
extends Node
class_name VSKSimulationCharacterStepComponent3D

## This class is designed for customizing
## an entity's CharacterBody3D from a simulation node with step-up and
## step-down behaviour and restoring its original settings when the simulation
## is shut down.

var _stairs_character: StairsCharacter = null

func _integration(_delta: float) -> Vector3:
	var velocity: Vector3 = Vector3()
	if _stairs_character:
		_stairs_character.move_and_stair_step()
		velocity = _stairs_character.velocity
				
	return velocity

func _ground_test() -> bool:
	if _stairs_character:
		return _stairs_character.grounded
		
	return false

func _ready() -> void:
	if not Engine.is_editor_hint():
		if simulation:
			var entity_interface: SarGameEntityInterfaceVessel3D = simulation.get_game_entity_interface() as SarGameEntityInterfaceVessel3D
			if entity_interface:
				var character_body_3d: CharacterBody3D = entity_interface.get_movement_component().get_physics_body()
				if character_body_3d:
					character_body_3d.set_script(StairsCharacter)
					_stairs_character = character_body_3d
					
					_stairs_character._step_height = step_height
					_stairs_character.set_physics_process(true)
					
					# Assign the callbacks to the entity's movement component
					entity_interface.get_movement_component().assign_custom_integration_method(_integration)
					entity_interface.get_movement_component().assign_custom_is_grounded_method(_ground_test)
		
		# If we have an auxiliary motion component, also wire up its integration callback.
		if auxiliary_motion:
			auxiliary_motion.auxiliary_movement_integration_callable = _integration
				
func _on_simulation_shutdown() -> void:
	if not Engine.is_editor_hint():
		if simulation:
			var entity_interface: SarGameEntityInterfaceVessel3D = simulation.get_game_entity_interface() as SarGameEntityInterfaceVessel3D
			if entity_interface:
				var character_body_3d: CharacterBody3D = entity_interface.get_movement_component().get_physics_body()
				if character_body_3d:
					character_body_3d.set_script(null)
					character_body_3d.set_physics_process(false)
					
					# Since we're shutting down the simulation, remove the callbacks from the
					# entity's movement component.
					entity_interface.get_movement_component().assign_custom_integration_method(Callable())
					entity_interface.get_movement_component().assign_custom_is_grounded_method(Callable())

###

## Reference to the root simulation.
@export var simulation: SarSimulationVessel3D = null
## Reference to the auxiliary motion component.
@export var auxiliary_motion: SarSimulationComponentAuxiliaryMotion3D = null
# How high we are allowed to step-up and down.
@export var step_height: float = 0.75
