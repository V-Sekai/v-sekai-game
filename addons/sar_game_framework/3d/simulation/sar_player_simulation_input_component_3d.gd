@tool
extends Node
class_name SarPlayerSimulationInputComponent

var _blocked_input_counter: int = 0

@export var simulation: SarSimulationVessel3D = null

@export var playspace: SarPlayerSimulationFPSTPSXRHybridPlayspaceComponent3D = null
@export var motor: SarSimulationComponentMotor3D = null
@export var jump: SarSimulationComponentJump3D = null

func block_input() -> void:
	_blocked_input_counter += 1
	
func unblock_input() -> void:
	if _blocked_input_counter > 0:
		_blocked_input_counter -= 1

func _is_input_disabled() -> bool:
	return _blocked_input_counter > 0
	
func _update_input(p_input_component: SarGameEntityComponentVesselInput, p_disabled: bool) -> void:
	if not p_disabled:
		if playspace:
			playspace.turn_velocity.x = p_input_component.get_input_value_for_action("camera_rotation_horizontal")
			playspace.turn_velocity.y = p_input_component.get_input_value_for_action("camera_rotation_vertical")
		
		if motor:
			motor.movement_input.x = p_input_component.get_input_value_for_action("horizontal_movement")
			motor.movement_input.y = p_input_component.get_input_value_for_action("depth_movement")
		
		if jump:
			jump.should_jump = p_input_component.is_action_pressed("jump")
	else:
		if playspace:
			playspace.turn_velocity.x = 0.0
			playspace.turn_velocity.y = 0.0
		
		if motor:
			motor.movement_input.x = 0.0
			motor.movement_input.y = 0.0
		
		if jump:
			jump.should_jump = false

func _physics_process(_p_delta: float) -> void:
	if not Engine.is_editor_hint():
		if simulation and simulation.is_possessed():
			var input_component: SarGameEntityComponentVesselInput = simulation.get_game_entity_interface().get_input_component()
			if input_component:
				_update_input(input_component, _is_input_disabled())
