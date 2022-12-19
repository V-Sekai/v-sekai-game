extends Node3D

var step_timer: float = 0.0
@export var bobbing_speed: float = 10.0
@export var bobbing_v_amount: float = 0.0
@export var bobbing_h_amount: float = 0.0

func _physics_process(p_delta: float) -> void:
	var waveslice: float = sin(step_timer)
	step_timer += bobbing_speed * p_delta
	
	transform.origin = Vector3(
		waveslice * bobbing_h_amount,
		waveslice * bobbing_v_amount,
		0.0)

func _ready() -> void:
	transform.origin = Vector3(
		0.0,
		0.0,
		0.0)
