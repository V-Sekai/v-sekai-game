@tool
extends Node
class_name SarSimulationComponentAuxiliaryMotion3D
## SarSimulationComponentAuxiliaryMotion3D is a script designed for applying additional kinematic
## movement alongside the standard movement for the entity's movement component.
##
## This script's primary intended purpose is used to calculate additional kinematic integration for
## VR where we may want to calculate motion based on the player's head movement, but it can also
## be used for additional similar purposes too. The auxiliary motion will be applied before the
## main movement integration is applied.

# Additional offset calculated from the offset of the XR camera.
var _auxiliary_offset: Vector3 = Vector3()

# This function applies additional p_velocity to p_character_body via the
# p_integration_func callable and returns the distance travelled across
# the p_delta_plane.
static func _execute_auxiliary_integration(
	p_delta: float,
	p_integration_func: Callable,
	p_character_body_3d: CharacterBody3D,
	p_velocity: Vector3,
	p_delta_plane: Vector3) -> Vector3:
	if not is_zero_approx(p_velocity.length()):
		var original_velocity: Vector3 = p_character_body_3d.velocity
		var original_wall_min_slide_angle: float = p_character_body_3d.wall_min_slide_angle
		
		# Cache the original velocity and wall slide values.
		p_character_body_3d.velocity = p_velocity
		p_character_body_3d.wall_min_slide_angle = 0.0
		
		# Since we can can customize the actual integration function (for things like
		# step up and step down), use that to perform the actual physics integration step.
		var start_pos: Vector3 = p_character_body_3d.global_position
		p_integration_func.call(p_delta)
		var end_pos: Vector3 = p_character_body_3d.global_position
		
		var distance_travelled: Vector3 = (end_pos - start_pos) * p_delta_plane
		
		# Now restore it.
		p_character_body_3d.velocity = original_velocity
		p_character_body_3d.wall_min_slide_angle = original_wall_min_slide_angle
		
		return distance_travelled
		
	return Vector3()
	
# Callback for the movement component's pre-integration phase.
func _on_pre_movement(p_delta: float, _velocity: Vector3) -> void:
	var game_entity_interface: SarGameEntityInterface3D = simulation.get_game_entity_interface()
	if not SarUtils.assert_true(game_entity_interface, "SarSimulationComponentAuxiliaryMotion3D._on_pre_movement: game_entity_interface is not available"):
		return
	
	var movement_component = game_entity_interface.get_movement_component()
	if not SarUtils.assert_true(movement_component, "SarSimulationComponentAuxiliaryMotion3D._on_pre_movement: movement_component is not available"):
		return
	
	var character_body_3d: CharacterBody3D = movement_component.get_physics_body()
	
	if character_body_3d:
		var integration_func: Callable = character_body_3d.move_and_slide
		if auxiliary_movement_integration_callable.is_valid():
			integration_func = auxiliary_movement_integration_callable
		
		playspace.apply_external_camera_offset(
			_execute_auxiliary_integration(
				p_delta,
				integration_func,
				character_body_3d,
				_auxiliary_offset * Engine.physics_ticks_per_second,
				movement_component.get_horizontal_plane()))
	
	_auxiliary_offset = Vector3()

###

## The root simulation node.
@export var simulation: SarSimulationVessel3D = null
## The simulation's playspace.
@export var playspace: SarPlayerSimulationPlayspaceComponent3D = null

## Assign this callable to customize how the actual kinematic integration step should be performed.
## Can be mainly used for calculate things like step up/down behaviours.
var auxiliary_movement_integration_callable: Callable = Callable()

## This function accumulates offset which will be applied before the main kinematic integration phase.
func add_auxilary_movement_offset(p_offset: Vector3) -> void:
	_auxiliary_offset += p_offset
