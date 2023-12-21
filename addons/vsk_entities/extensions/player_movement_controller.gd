extends Node

@onready var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@export var character_body: CharacterBody3D = null
@export var xr_origin: XROrigin3D = null
@export var xr_camera: XRCamera3D = null

@export var position_interpolation: Node3D = null
@export var rotation_interpolation: Node3D = null

func _physics_process(p_delta: float) -> void:
	if is_multiplayer_authority():
		for child in get_children():
			child.execute(self, p_delta)
			
		# Apply gravity
		if !character_body.is_on_floor():
			character_body.velocity += Vector3.DOWN * _gravity * p_delta
			
		character_body.move_and_slide()
		position_interpolation.origin_offset = -character_body.get_position_delta()
