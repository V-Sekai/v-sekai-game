extends "player_movement_provider.gd"

@export var speed: float = 0.03

var input: Vector2 = Vector2()

func execute(p_movement_controller: Node, p_delta: float) -> void:
	super.execute(p_movement_controller, p_delta)
	
	var overall_rotation: float = get_xr_origin(p_movement_controller).transform.basis.get_euler().y + get_xr_camera(p_movement_controller).transform.basis.get_euler().y
	
	input.y = input.y - Input.get_action_strength("move_forwards") + Input.get_action_strength("move_backwards")
	input.x = input.x - Input.get_action_strength("move_left") + Input.get_action_strength("move_right")
	
	input = input.normalized()
	
	var rotated_velocity = Vector2(
	input.y * sin(overall_rotation) + input.x * cos(overall_rotation),
	input.y * cos(overall_rotation) + input.x * -sin(overall_rotation))
	
	get_character_body(p_movement_controller).velocity = Vector3(
		0.0, get_character_body(p_movement_controller).velocity.y, 0.0) + (
			Vector3(rotated_velocity.x, 0.0, rotated_velocity.y) * speed) * Engine.physics_ticks_per_second

	# Reset the input
	input = Vector2()
