@tool
extends SarUIViewController
class_name VSKUIViewControllerBigMenu

signal avatar_url_selected(p_url: String)

func _ready() -> void:
	if not Engine.is_editor_hint():
		pass

func _on_avatars_content_selected(p_url: String) -> void:
	avatar_url_selected.emit(p_url)

###

@export var title_label: Label = null

signal message_box_requested(p_title: String, p_body: String)

func show_messagebox(p_title: String, p_body: String) -> void:
	assert(message_box_requested.has_connections())
	
	message_box_requested.emit(p_title, p_body)

func show_keyboard() -> void:
	pass
	
func hide_keyboard() -> void:
	pass
