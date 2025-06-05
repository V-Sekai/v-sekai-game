@tool
extends AnimationTreeDriverPropertyControllerValue
class_name AnimationTreeDriverPropertyControllerCurve

@export var curve: Curve = null:
	set(p_curve):
		if p_curve != curve:
			if curve:
				curve.changed.disconnect(_changed)
			
			curve = p_curve
			if curve:
				curve.bake()
				assert(curve.changed.connect(_changed) == OK)
			
			_changed()

func get_value(p_input: Variant) -> Variant:
	if curve and p_input is float:
		return curve.sample_baked(p_input)
		
	return p_input
