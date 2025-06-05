@tool
extends AnimationTreeDriverPropertyControllerValue
class_name AnimationTreeDriverPropertyControllerSum

func _changed() -> void:
	super._changed()

@export var a: AnimationTreeDriverPropertyControllerValue = null:
	set(p_value):
		if a != p_value:
			if a:
				a.changed.disconnect(_changed)
			
			a = p_value
			
			if a:
				assert(a.changed.connect(_changed) == OK)
				_changed()

@export var b: AnimationTreeDriverPropertyControllerValue = null:
	set(p_value):
		if b != p_value:
			if b:
				b.changed.disconnect(_changed)
			
			b = p_value
			
			if b:
				assert(b.changed.connect(_changed) == OK)
				_changed()

func get_value(p_input: Variant) -> Variant:
	if a and b:
		return b.get_value(a.get_value(p_input))
		
	return p_input
