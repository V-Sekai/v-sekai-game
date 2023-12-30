extends "player_movement_provider.gd"

@export var mouse_sensitivity = 1.0

var input: float = 0.0

func execute(p_movement_controller: Node, p_delta: float) -> void:
	super.execute(p_movement_controller, p_delta)
	
	input += (Input.get_action_strength("turn_left") - Input.get_action_strength("turn_right"))
	
	var rot_offset: float = input * p_delta
	
	var camera_position_2d: Vector3 = get_xr_camera(p_movement_controller).transform.origin
	camera_position_2d.y = 0.0
	
	var camera_position_transform: Transform3D = Transform3D(Basis(), camera_position_2d)
	get_xr_origin(p_movement_controller).transform = get_xr_origin(p_movement_controller).transform * camera_position_transform * Transform3D(Basis().rotated(Vector3.UP, rot_offset), Vector3()) * camera_position_transform.inverse()

	p_movement_controller.rotation_interpolation.rotation_offset = -rot_offset
	
	# Reset the input
	input = 0.0
	
func _input(p_event: InputEvent) -> void:
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if p_event is InputEventMouseMotion:
			input -= p_event.relative.x * mouse_sensitivity
