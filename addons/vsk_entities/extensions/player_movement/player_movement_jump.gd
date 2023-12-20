extends "player_movement_provider.gd"

@export var jump_velocity: float = 4.0

var _jump_requested: bool = false

func request_jump() -> void:
	_jump_requested = true

func execute(_p_delta: float) -> void:
	if _jump_requested:
		if get_player_controller().is_on_floor():
			get_player_controller().velocity += Vector3.UP * jump_velocity

	_jump_requested = false
