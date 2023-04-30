@tool
class_name EntityRef extends RefCounted

# Warning! Do not access this directly from another entity!
var _entity: Node = null


func _init(p_entity):
	_entity = p_entity


func get_entity_type() -> String:
	return EntityManager.get_entity_type_safe(self)


func get_last_transform():
	return EntityManager.get_entity_last_transform_safe(self)
