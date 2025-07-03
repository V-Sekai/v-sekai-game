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
				if not SarUtils.assert_ok(a.changed.connect(_changed),
					"Could not connect signal 'a.changed' to '_changed'"):
					return
				_changed()

@export var b: AnimationTreeDriverPropertyControllerValue = null:
	set(p_value):
		if b != p_value:
			if b:
				b.changed.disconnect(_changed)
			
			b = p_value
			
			if b:
				if not SarUtils.assert_ok(b.changed.connect(_changed),
					"Could not connect signal 'b.changed' to '_changed'"):
					return
				_changed()

func get_value(p_input: Variant) -> Variant:
	if a and b:
		return b.get_value(a.get_value(p_input))
		
	return p_input
