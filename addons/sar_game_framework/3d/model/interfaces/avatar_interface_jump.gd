@tool
class_name SarAvatarInterfaceJump
extends SarAvatarInterface

signal jump_velocity_requested(p_velocity: Vector3)

func set_jump_velocity(p_velocity: Vector3) -> void:
	jump_velocity_requested.emit(p_velocity)
