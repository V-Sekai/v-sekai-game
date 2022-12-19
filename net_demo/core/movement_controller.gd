extends CharacterBody3D

var y_rotation: float = 0.0
var gravity: float = 9.8

func apply_intertia(p_delta: float) -> void:
	for i in range (0, get_slide_collision_count()):
		var kinematic_collision: KinematicCollision3D = \
		get_slide_collision(i)
		
		for j in range(0, kinematic_collision.get_collision_count()):
			if kinematic_collision.get_collider(j) is RigidBody3D:
				kinematic_collision.get_collider(j).apply_central_impulse(
					-kinematic_collision.get_normal(j) * p_delta)

func get_platform_velocity() -> Vector3:
	return Vector3()

func kinematic_movement(p_delta: float) -> void:
	if move_and_slide():
		apply_intertia(p_delta)
	
func _ready():
	y_rotation = transform.basis.get_euler().y
	transform.basis = Basis()
	
	gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
