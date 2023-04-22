@tool
class_name StrongExclusiveEntityDependencyHandle extends RefCounted

var _entity_ref: EntityRef = null
var _dependency: EntityRef = null


func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		if _entity_ref._entity and _dependency._entity:
			_entity_ref._entity._remove_strong_exclusive_dependency(_dependency)


func _init(p_entity_ref: EntityRef, p_dependency: EntityRef):
	_entity_ref = p_entity_ref
	_dependency = p_dependency

	_entity_ref._entity._create_strong_exclusive_dependency(_dependency)
