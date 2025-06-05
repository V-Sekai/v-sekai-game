@tool
extends Resource
class_name AnimationTreeDriverPropertyController

func _changed() -> void:
	emit_changed()

@export var animation_tree_property_path: String = "":
	set(p_animation_tree_property_path):
		if animation_tree_property_path != p_animation_tree_property_path:
			animation_tree_property_path = p_animation_tree_property_path
			_changed()
			
@export var value: AnimationTreeDriverPropertyControllerValue = null:
	set(p_value):
		if p_value != value:
			if value:
				value.changed.disconnect(_changed)
			
			value = p_value
			if value:
				assert(value.changed.connect(_changed) == OK)
			
			_changed()
