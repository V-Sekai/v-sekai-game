@tool
class_name SarAvatarInterfaceRelativeTransform
extends SarAvatarInterface

signal translate_requested(p_vector: Vector3)
signal rotate_requested(p_euler: Vector3)

func translate(p_translation: Vector3) -> void:
	translate_requested.emit(p_translation)
	
func rotate_degrees(p_euler_degrees: Vector3) -> void:
	rotate_requested.emit(Vector3(deg_to_rad(p_euler_degrees.x), deg_to_rad(p_euler_degrees.y), deg_to_rad(p_euler_degrees.z)))
