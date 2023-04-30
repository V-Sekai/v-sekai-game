@tool
extends EditorPlugin


func _init():
	print("Initialising MathUtil plugin")
	name = &"MathUtil"


func _notification(p_notification: int) -> void:
	match p_notification:
		NOTIFICATION_PREDELETE:
			print("Destroying MathUtil plugin")


func _enter_tree() -> void:
	add_autoload_singleton("GodotMathExtension", "res://addons/math_util/math_funcs.gd")


func _exit_tree() -> void:
	remove_autoload_singleton("GodotMathExtension")
