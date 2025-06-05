@tool
extends Node
class_name SarGameEntityComponentVesselInput

## This component provides an interface to parse input actions from the
## currently possessing soul node into a table of input data which the entity
## can poll in order to perform actions.

class InputState:
	var strength: float = 0.0
	var pressed_process_frame: int = 0
	var pressed_physics_frame: int = 0
	var released_process_frame: int = 0
	var released_physics_frame: int = 0

var _input_table: Dictionary[StringName, InputState] = {}

func _ensure_input_state_exists(p_action_name: StringName) -> void:
	if not _input_table.has(p_action_name):
		_input_table[p_action_name] = InputState.new()

##

## Stores p_value as strength for the named p_action_name which can later be retrived
## by other nodes. It will keep track of the input strength from previous frames
## so that is_action_just_pressed/released checks will work.
func set_input_value_for_action(p_action_name: StringName, p_value: float) -> void:
	_ensure_input_state_exists(p_action_name)
	
	var prev_strength: float = _input_table[p_action_name].strength
	
	if is_zero_approx(p_value):
		_input_table[p_action_name].strength = 0.0
		
		if not is_zero_approx(prev_strength):
			_input_table[p_action_name].released_process_frame = Engine.get_process_frames()
			_input_table[p_action_name].released_physics_frame = Engine.get_physics_frames() + 1
	else:
		_input_table[p_action_name].strength = p_value
		
		if is_zero_approx(prev_strength):
			_input_table[p_action_name].pressed_process_frame = Engine.get_process_frames()
			_input_table[p_action_name].pressed_physics_frame = Engine.get_physics_frames() + 1

## Returns strength value for a named action.
func get_input_value_for_action(p_action_name: StringName) -> float:
	_ensure_input_state_exists(p_action_name)
	
	return _input_table[p_action_name].strength
		
## Returns true if the action was classified as pressed, but wasn't the
## previous frame.
func is_action_just_pressed(p_action_name: StringName) -> bool:
	_ensure_input_state_exists(p_action_name)
	
	if not is_zero_approx(_input_table[p_action_name].strength):
		if (Engine.is_in_physics_frame()):
			return _input_table[p_action_name].pressed_physics_frame == Engine.get_physics_frames()
		else:
			return _input_table[p_action_name].pressed_process_frame == Engine.get_process_frames()
			
	return false

## Returns true if the action was classified as released, but wasn't the
## previous frame.
func is_action_just_released(p_action_name: StringName) -> bool:
	_ensure_input_state_exists(p_action_name)
	
	if is_zero_approx(_input_table[p_action_name].strength):
		if (Engine.is_in_physics_frame()):
			return _input_table[p_action_name].pressed_physics_frame == Engine.get_physics_frames()
		else:
			return _input_table[p_action_name].pressed_process_frame == Engine.get_process_frames()
			
	return false
		
## Returns true if the action was classified as pressed.
func is_action_pressed(p_action_name: StringName) -> bool:
	_ensure_input_state_exists(p_action_name)
	
	if not is_zero_approx(_input_table[p_action_name].strength):
		return true
	
	return false

## Returns true if the action was classified as released.
func is_action_released(p_action_name: StringName) -> bool:
	_ensure_input_state_exists(p_action_name)
	
	if is_zero_approx(_input_table[p_action_name].strength):
		return true
	
	return false
