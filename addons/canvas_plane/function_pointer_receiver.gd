extends Area3D

signal pointer_pressed(p_at)
signal pointer_moved(p_at, p_from)
signal pointer_release(p_at)

func untransform_position(p_vector: Vector3) -> Vector3:
	var result = global_transform.basis * p_vector
	return result


func untransform_normal(p_normal: Vector3) -> Vector3:
	var current_basis: Basis = global_transform.basis.orthonormalized()
	var result = current_basis.inverse() * p_normal
	return result


func validate_pointer(p_normal: Vector3) -> bool:
	var transform_normal: Vector3 = untransform_normal(p_normal)
	if transform_normal.z > 0.0:
		return true
	else:
		return false


func on_pointer_pressed(p_position: Vector3, p_doubleclick: bool) -> void:
	pointer_pressed.emit(untransform_position(p_position), p_doubleclick)
	print("Signal 'pointer_pressed' emitted.")


func on_pointer_moved(p_position: Vector3, p_normal: Vector3) -> void:
	if validate_pointer(p_normal):
		pointer_moved.emit(untransform_position(p_position), p_normal)


func on_pointer_release(p_position: Vector3) -> void:
	pointer_release.emit(untransform_position(p_position))
