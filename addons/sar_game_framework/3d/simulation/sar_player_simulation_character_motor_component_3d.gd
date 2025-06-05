@tool
extends Node
class_name SarSimulationComponentMotor3D

## This class is a basic character motor capable of calculating acceleration,
## physics, and gravity. It will then pass the calculated velocity for a
## game entity's movement component.

const _DEFAULT_MAX_GROUND_VELOCITY: float = 10.0

var _movement_component: SarGameEntityComponentVesselMovementCharacter3D = null
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _current_velocity: Vector3 = Vector3()
	
func _get_forward_direction() -> Basis:
	var game_entity_interface: SarGameEntityInterface3D = simulation.get_game_entity_interface()
	assert(game_entity_interface)
	
	var game_entity: SarGameEntity3D = game_entity_interface.get_game_entity()
	assert(game_entity)
	
	return game_entity.global_transform.basis

static func _apply_acceleration_to_velocity(p_current_velocity: Vector3, p_desired_direction: Vector3, p_max_velocity: float, p_max_acceleration: float, p_delta: float) -> Vector3:
	var current_speed: float = p_current_velocity.dot(p_desired_direction)
	
	var additional_speed: float = clampf(
		p_max_velocity - current_speed,
		0.0,
		p_max_acceleration * p_delta)
	
	return p_current_velocity + (additional_speed * p_desired_direction)

func _ground_movement(p_current_velocity: Vector3, p_desired_direction: Vector3, p_delta: float) -> Vector3:
	var new_velocity: Vector3 = p_current_velocity
	var current_speed: float = new_velocity.length()
		
	if not is_zero_approx(abs(current_speed)):
		var control: float = maxf(stop_speed, current_speed)
		var reduction: float = control * friction * p_delta
		
		new_velocity *= max(current_speed - reduction, 0) / current_speed
	
	return _apply_acceleration_to_velocity(
		new_velocity,
		p_desired_direction,
		max_ground_velocity,
		max_acceleration,
		p_delta
	)

func _process_movement(p_delta: float, p_movement_vector: Vector2) -> void:
	# Calculate movement basis vectors
	var movement_dir = Vector3(-p_movement_vector.x, 0.0, p_movement_vector.y)
	var desired_direction: Vector3 = (_get_forward_direction() * movement_dir).normalized()
	
	var game_entity_interface: SarGameEntityInterface3D = simulation.get_game_entity_interface()
	assert(game_entity_interface)
	
	_current_velocity = _movement_component.get_velocity()
	
	if _movement_component.is_grounded():
		_current_velocity = _ground_movement(_current_velocity, desired_direction, p_delta)
		_current_velocity *= (_movement_component.get_horizontal_plane())
	else:
		_current_velocity -= (_movement_component.get_up_direction() * _gravity) * p_delta
				
	_movement_component.set_velocity(_current_velocity)
		
func _physics_process(p_delta: float) -> void:
	var movement_vector: Vector2 = movement_input
	_process_movement(p_delta, movement_vector)
			
func _ready() -> void:
	if not Engine.is_editor_hint():
		var game_entity_interface: SarGameEntityInterface3D = simulation.get_game_entity_interface()
		assert(game_entity_interface)
		
		_movement_component = game_entity_interface.get_movement_component()
		assert(_movement_component)
		
		_movement_component.character_body_3d.apply_floor_snap()
		
		if is_multiplayer_authority():
			set_physics_process(true)
		else:
			set_physics_process(false)
	else:
		set_physics_process(false)


func _on_transform_post_update(_transform: Transform3D) -> void:
	if simulation and playspace:
		simulation.get_game_entity_interface().get_game_entity().rotation.y = playspace.get_yaw_rotation()

###

## Reference to the root simulation.
@export var simulation: SarSimulationVessel3D = null

## Reference to the simulation's playspace.
@export var playspace: SarPlayerSimulationPlayspaceComponent3D = null

## Vector2 containing the desired relative input direction for this motor.
@export var movement_input: Vector2 = Vector2()

@export var max_ground_velocity: float = _DEFAULT_MAX_GROUND_VELOCITY
@export var max_acceleration: float = _DEFAULT_MAX_GROUND_VELOCITY * 10.0
@export var stop_speed: float = 10.0
@export var friction: float = 4.0

## Returns [true] is the movement component reports that that it is on the
## ground.
func is_grounded() -> bool:
	return _movement_component.is_grounded()

## Returns the current velocity for this motor.
func get_current_velocity() -> Vector3:
	return _current_velocity
