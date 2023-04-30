@tool
extends EditorPlugin

var editor_interface: EditorInterface = null


func _init():
	print("Initialising FlatViewport plugin")


func _notification(p_notification: int):
	match p_notification:
		NOTIFICATION_PREDELETE:
			print("Destroying FlatViewport plugin")


func _get_plugin_name() -> String:
	return "FlatViewport"


func _enter_tree() -> void:
	editor_interface = get_editor_interface()

	add_autoload_singleton("FlatViewport", "res://addons/flat_viewport/flat_viewport.gd")


func _exit_tree() -> void:
	remove_autoload_singleton("FlatViewport")
