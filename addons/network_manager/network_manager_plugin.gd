@tool
extends EditorPlugin

var editor_interface: EditorInterface = null


func _init():
	print("Initialising NetworkManager plugin")


func _notification(p_notification: int):
	match p_notification:
		NOTIFICATION_PREDELETE:
			print("Destroying NetworkManager plugin")


func _get_plugin_name() -> String:
	return "NetworkManager"


func _enter_tree() -> void:
	editor_interface = get_editor_interface()

	add_autoload_singleton("NetworkManager", "res://addons/network_manager/network_manager.gd")
	add_autoload_singleton("NetworkLogger", "res://addons/network_manager/network_logger.gd")


func _exit_tree() -> void:
	remove_autoload_singleton("NetworkManager")
	remove_autoload_singleton("NetworkLogger")
