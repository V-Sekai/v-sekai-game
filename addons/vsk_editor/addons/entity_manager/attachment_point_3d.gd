extends Node3D

var entity: Node = null:
	set = set_entity,
	get = get_entity


func set_entity(p_entity) -> void:
	entity = p_entity


func get_entity() -> Node:
	return entity
