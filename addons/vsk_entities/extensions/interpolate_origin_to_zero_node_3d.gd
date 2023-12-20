extends Node3D

var origin_offset: Vector3 = Vector3()

func _process(_delta: float) -> void:
	var fraction: float = Engine.get_physics_interpolation_fraction()
	
	transform.origin = lerp(origin_offset, Vector3(), fraction)
