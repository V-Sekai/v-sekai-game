@tool
extends EditorPlugin

var editor_interface: EditorInterface = null


func _init():
	print("Initialising VSKEntities plugin")


func _notification(p_notification: int):
	match p_notification:
		NOTIFICATION_PREDELETE:
			print("Destroying VSKEntities plugin")


func _get_plugin_name() -> String:
	return "VSKEntities"


func _enter_tree() -> void:
	editor_interface = get_editor_interface()


func _exit_tree() -> void:
	pass
