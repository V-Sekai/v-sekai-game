@tool
extends Control
class_name VSKUIViewContentMenu

signal content_selected(p_url: String)

func _get_uro_service() -> VSKGameServiceUro:
	var manager: VSKGameServiceManager = get_tree().get_first_node_in_group("game_service_managers")
	if manager:
		var uro: VSKGameServiceUro = manager.get_service("Uro")
		return uro
		
	return null

func _fetch_content() -> void:
	pass
	
func _clear_content():
	if content_browser:
		content_browser.clear_content()
		
func _notification(p_what: int) -> void:
	match p_what:
		NOTIFICATION_VISIBILITY_CHANGED:
			if not Engine.is_editor_hint():
				if is_visible_in_tree():
					_fetch_content()
				else:
					_clear_content()
					
func _content_selected(p_content_url: String) -> void:
	print(p_content_url)
	content_selected.emit(p_content_url)
	
###

@export var content_browser: VSKUIViewContentBrowser = null
