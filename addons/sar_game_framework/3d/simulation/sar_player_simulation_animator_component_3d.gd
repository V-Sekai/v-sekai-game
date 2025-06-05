@tool
extends Node
class_name SarSimulationComponentAnimator3D

## This class is designed for driving the basic animation inputs for
## an avatar based on velocity and ground state.

var _model_component: SarGameEntityComponentModel3D = null
var _target_velocity: Vector3 = Vector3()
var _animation_velocity: Vector3 = Vector3()

func _is_xr_enabled() -> bool:
	return XRServer.primary_interface != null
	
func _get_motion_scale() -> float:
	return 1.0

func _update_velocity_property(p_delta: float) -> void:
	var avatar: SarAvatar3D = _model_component.get_model_node() as SarAvatar3D
	if avatar:
		# We need to have an animation tree driver or we won't be able to
		# do anything.
		if avatar.animation_tree_driver:
			var relative_velcity: Vector3 = _target_velocity
			var mulitplied_velocity: Vector3 = relative_velcity * velocity_animation_multiplier
			
			# Smooth the animation velocity towards the actual velocity.
			_animation_velocity.x = move_toward(_animation_velocity.x, mulitplied_velocity.x, (p_delta * velocity_transition_speed))
			_animation_velocity.y = move_toward(_animation_velocity.y, mulitplied_velocity.y, (p_delta * velocity_transition_speed))
			_animation_velocity.z = move_toward(_animation_velocity.z, mulitplied_velocity.z, (p_delta * velocity_transition_speed))
			
			# Now update it.
			avatar.animation_tree_driver.set("velocity", _animation_velocity / _get_motion_scale()) 

func _process(p_delta: float) -> void:
	if not Engine.is_editor_hint():
		_update_velocity_property(p_delta)
		
func _physics_process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		var avatar: SarAvatar3D = _model_component.get_model_node() as SarAvatar3D
		if avatar:
			if avatar.animation_tree_driver:
				avatar.animation_tree_driver.set("grounded", motor.is_grounded())

func _ready() -> void:
	if not Engine.is_editor_hint():
		assert(simulation)
		
		_model_component = simulation.game_entity_interface.get_model_component()
		assert(_model_component)

func _on_post_movement(_delta: float, p_velocity: Vector3) -> void:
	_target_velocity = p_velocity * simulation.get_game_entity_interface().get_game_entity().transform.basis

###

## Reference to the root simulation.
@export var simulation: SarSimulationVessel3D = null

## Reference to the simulation's motor component.
@export var motor: SarSimulationComponentMotor3D = null

## How much to multiply animation velocity speed based on the actual velocity.
@export var velocity_animation_multiplier: float = 0.1

## The rate to transition velocity speed.
@export var velocity_transition_speed: float = 5.0
