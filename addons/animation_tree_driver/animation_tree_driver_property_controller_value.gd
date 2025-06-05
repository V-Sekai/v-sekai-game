@tool
extends Resource
class_name AnimationTreeDriverPropertyControllerValue
	
func _changed() -> void:
	emit_changed()
	
func get_value(p_input: Variant) -> Variant:
	return p_input
