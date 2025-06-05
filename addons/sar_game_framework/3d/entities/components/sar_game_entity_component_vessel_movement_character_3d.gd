@tool
extends SarGameEntityComponentVesselMovement3D
class_name SarGameEntityComponentVesselMovementCharacter3D

func _apply_intertia_to_colliders(p_delta: float) -> void:
	for i: int in range (0, character_body_3d.get_slide_collision_count()):
		var kinematic_collision: KinematicCollision3D = \
		character_body_3d.get_slide_collision(i)
		
		for j: int in range(0, kinematic_collision.get_collision_count()):
			var rigid_body: RigidBody3D = kinematic_collision.get_collider(j) as RigidBody3D
			if rigid_body:
				rigid_body.apply_central_impulse(-kinematic_collision.get_normal(j) * INERTIA_MULTIPLIER * p_delta)

func _kinematic_movement(p_delta: float) -> Vector3:
	var collided: bool = character_body_3d.move_and_slide()
	if collided:
		_apply_intertia_to_colliders(p_delta)
		
	return character_body_3d.velocity
	
# Only run on local peer.
func _physics_process(p_delta: float) -> void:
	if character_body_3d.visible:
		if integration_enabled:
			_pre_movement(p_delta, character_body_3d.velocity)
			
			var result_velocity: Vector3
			
			if _custom_integration_method.is_valid():
				result_velocity = _custom_integration_method.call(p_delta)
			else:
				result_velocity = _kinematic_movement(p_delta)
				
			_post_movement(p_delta, result_velocity)
			
			_movement_complete(p_delta)
		
		# Store the previous position
		previous_physics_position = character_body_3d.global_position
	
func _ready() -> void:
	if game_entity and not Engine.is_editor_hint():
		character_body_3d.top_level = true
		character_body_3d.global_transform = Transform3D(Basis(), game_entity.global_transform.origin)
		previous_physics_position = game_entity.global_transform.origin
		
		if is_multiplayer_authority():
			set_physics_process(true)
		else:
			set_physics_process(false)
	else:
		set_physics_process(false)
###

@export var character_body_3d: CharacterBody3D = null

const INERTIA_MULTIPLIER: float = 100.0

var integration_enabled: bool = true

## The vessel's physics position before the last movement.
var previous_physics_position: Vector3 = Vector3()

func get_physics_body() -> PhysicsBody3D:
	return character_body_3d
	
func set_velocity(p_velocity: Vector3) -> void:
	character_body_3d.velocity = p_velocity
	
func get_velocity() -> Vector3:
	return character_body_3d.velocity
	
func is_grounded() -> bool:
	if _custom_is_grounded_method.is_valid():
		return _custom_is_grounded_method.call()
	else:
		return character_body_3d.is_on_floor()
	
func get_up_direction() -> Vector3:
	return character_body_3d.up_direction
	
func get_horizontal_plane() -> Vector3:
	return Vector3.ONE - get_up_direction().abs()
	
func get_vertical_plane() -> Vector3:
	return get_up_direction().abs()
	
func get_physics_position() -> Vector3:
	return character_body_3d.global_position
	
func get_physics_transform() -> Transform3D:
	return character_body_3d.global_transform
	
func set_physics_position(p_position: Vector3) -> void:
	character_body_3d.global_position = p_position
