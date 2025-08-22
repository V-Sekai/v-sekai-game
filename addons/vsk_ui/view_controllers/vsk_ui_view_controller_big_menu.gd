@tool
extends SarUIViewController
class_name VSKUIViewControllerBigMenu

signal avatar_url_selected(p_url: String)
signal map_url_selected(p_url: String)

var tab_container: TabContainer

func _ready() -> void:
	tab_container = get_node("Content/VBoxContainer/WindowView/Panel/Content/Body/MarginContainer/Content/TabContainer") as TabContainer
	if not Engine.is_editor_hint():
		pass

func _on_avatars_content_selected(p_url: String) -> void:
	avatar_url_selected.emit(p_url)

func _on_maps_content_selected(p_url: String) -> void:
	map_url_selected.emit(p_url)

###

@export var title_label: Label = null

signal message_box_requested(p_title: String, p_body: String)

func show_messagebox(p_title: String, p_body: String) -> void:
	if not SarUtils.assert_true(message_box_requested.has_connections(), "Signal 'message_box_requested' has no connected callbacks"):
		return

	message_box_requested.emit(p_title, p_body)

func show_keyboard() -> void:
	pass
	
func hide_keyboard() -> void:
	pass

func set_current_tab(p_tab_name: String) -> void:
	match p_tab_name:
		"Explore":
			tab_container.current_tab = 0
		"Avatars":
			tab_container.current_tab = 1
