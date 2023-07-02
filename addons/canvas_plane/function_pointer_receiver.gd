extends Area3D

const math_funcs_const = preload("res://addons/math_util/math_funcs.gd")

signal pointer_pressed(p_at)
signal pointer_moved(p_at, p_from)
signal pointer_release(p_at)

func _ready():
	print("Initialising function_pointer_receiver.")

func _exit_tree():
	print("Exiting function_pointer_receiver.")

func untransform_position(p_vector: Vector3) -> Vector3:
	print("Untransforming position: ", p_vector)
	var result = p_vector * global_transform.basis
	print("Result: ", result)
	return result


func untransform_normal(p_normal: Vector3) -> Vector3:
	print("Untransforming normal: ", p_normal)
	var current_basis: Basis = global_transform.basis.orthonormalized()
	var result = p_normal * current_basis.inverse()
	print("Result: ", result)
	return result


func validate_pointer(p_normal: Vector3) -> bool:
	print("Validating pointer: ", p_normal)
	var transform_normal: Vector3 = untransform_normal(p_normal)
	if transform_normal.z <= 0.0:
		print("Pointer is valid.")
		return true
	else:
		print("Pointer is invalid.")
		return false


func on_pointer_pressed(p_position: Vector3, p_doubleclick: bool) -> void:
	print("Pointer pressed at position: ", p_position, " Double click: ", p_doubleclick)
	pointer_pressed.emit(untransform_position(p_position), p_doubleclick)
	print("Signal 'pointer_pressed' emitted.")


func on_pointer_moved(p_position: Vector3, p_normal: Vector3) -> void:
	print("Pointer moved to position: ", p_position, " Normal: ", p_normal)
	if validate_pointer(p_normal):
		pointer_moved.emit(untransform_position(p_position), p_normal)
		print("Signal 'pointer_moved' emitted.")


func on_pointer_release(p_position: Vector3) -> void:
	print("Pointer released at position: ", p_position)
	pointer_release.emit(untransform_position(p_position))
	print("Signal 'pointer_release' emitted.")
