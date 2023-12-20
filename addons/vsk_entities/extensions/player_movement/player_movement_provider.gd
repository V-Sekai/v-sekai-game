extends Node

func execute(_movement_controller: Node, _delta: float) -> void:
	pass

func get_xr_origin(p_movement_controller: Node) -> XROrigin3D:
	return p_movement_controller.xr_origin
	
func get_xr_camera(p_movement_controller: Node) -> XRCamera3D:
	return p_movement_controller.xr_camera
	
func get_character_body(p_movement_controller: Node) -> CharacterBody3D:
	return p_movement_controller.character_body
