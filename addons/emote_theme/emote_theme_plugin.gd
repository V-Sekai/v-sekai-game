@tool
extends EditorPlugin


func _init():
	print("Initialising EmoteTheme plugin")


func _notification(p_notification: int):
	match p_notification:
		NOTIFICATION_PREDELETE:
			print("Destroying EmoteTheme plugin")


func _get_plugin_name():
	return "EmoteTheme"
