@tool
extends EditorPlugin

var editor_interface: EditorInterface = null


func _init():
	print("Initialising ModelFormat plugin")


func _notification(p_notification: int):
	match p_notification:
		NOTIFICATION_PREDELETE:
			print("Destroying ModelFormat plugin")


func _get_plugin_name() -> String:
	return "ModelFormat"


func _enter_tree() -> void:
	editor_interface = get_editor_interface()

	add_autoload_singleton("ModelFormat", "res://addons/model_format/model_format.gd")


func _exit_tree() -> void:
	remove_autoload_singleton("ModelFormat")
