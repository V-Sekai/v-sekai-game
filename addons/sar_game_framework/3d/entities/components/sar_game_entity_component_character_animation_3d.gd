@tool
extends SarGameEntityComponent
class_name SarGameEntityComponentCharacterAnimation3D

@export var model_component: SarGameEntityComponentModel3D = null
@export var vessel_movement_component: SarGameEntityComponentVesselMovement3D = null

func _on_movement_complete(velocity: Vector3) -> void:
	var _velocity_length: float = (velocity * (Vector3.ONE - vessel_movement_component.get_up_direction())).length()
	
