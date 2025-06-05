@tool
extends Node
class_name SarSimulationComponentJump3D

## This class provides a complimantary component to the motor designed for
## handling basic jumping behaviour.

var _movement_component: SarGameEntityComponentVesselMovementCharacter3D = null

func _physics_process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		# Calculate movement basis 
		var game_entity_interface: SarGameEntityInterface3D = simulation.get_game_entity_interface()
		assert(game_entity_interface)
		
		if _movement_component.is_grounded():
			if should_jump:
				_movement_component.set_velocity(_movement_component.get_velocity() + (_movement_component.get_up_direction() * jump_velocity))

func _ready() -> void:
	if not Engine.is_editor_hint():
		var game_entity_interface: SarGameEntityInterface3D = simulation.get_game_entity_interface()
		assert(game_entity_interface)
		
		_movement_component = game_entity_interface.get_movement_component()
		assert(_movement_component)
		
###

## Reference to the root simulation.
@export var simulation: SarSimulationVessel3D = null

## The amount of velocity to apply for a jump.
@export var jump_velocity: float = 4.5

## Flag to indicate that we should perform a jump.
var should_jump: bool = false
