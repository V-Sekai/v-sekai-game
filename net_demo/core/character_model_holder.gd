extends Node3D

var color_material: Material = null

func assign_multiplayer_material(p_material: Material) -> void:
	color_material = p_material
	
	$ThirdPersonModel/Base.material_override = color_material
	$ThirdPersonModel/Pointer.material_override = color_material
