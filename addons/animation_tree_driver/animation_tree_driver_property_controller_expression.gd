@tool
extends AnimationTreeDriverPropertyControllerValue
class_name AnimationTreeDriverPropertyControllerExpression

var _cached_expression: Expression = null

@export_multiline var expression: String = "":
	set = _set_expression
	
func _set_expression(p_expression_string: String) -> void:
	if expression != p_expression_string:
		expression = p_expression_string
		
		if not _cached_expression:
			_cached_expression = Expression.new()
			
		var error: Error = _cached_expression.parse(expression, PackedStringArray(["value"]))
		if error != OK:
			push_error(_cached_expression.get_error_text())
			_cached_expression = null
			
		_changed()

func get_value(p_input: Variant) -> Variant:
	if _cached_expression:
		var result: Variant = _cached_expression.execute([p_input], null, true, true)
		if _cached_expression.has_execute_failed():
			push_error(_cached_expression.get_error_text())
		else:
			return result
		
	return p_input
