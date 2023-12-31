extends "player_movement_provider.gd"

@export var jump_velocity: float = 4.0

var _jump_requested: bool = false

func request_jump() -> void:
	_jump_requested = true

func execute(p_movement_controller: Node, p_delta: float) -> bool:
	if !super.execute(p_movement_controller, p_delta):
		return false
	
	if Input.is_action_pressed("jump") or _jump_requested:
		if p_movement_controller.character_body.is_on_floor():
			get_character_body(p_movement_controller).velocity += Vector3.UP * jump_velocity

	_jump_requested = false

	return true
