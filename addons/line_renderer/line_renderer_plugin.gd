@tool
extends EditorPlugin


func _init():
	print("Initialising LineRenderer plugin")


func _notification(p_notification: int):
	match p_notification:
		NOTIFICATION_PREDELETE:
			print("Destroying LineRenderer plugin")


func _get_plugin_name() -> String:
	return "LineRenderer"
