@tool
extends Control
class_name VSKUIViewDomainSelector

signal url_selected(p_url)

var _other_homeserver_checkbox: CheckBox = null
var _other_homeserver_line_edit: LineEdit = null
var _button_group: ButtonGroup = ButtonGroup.new()
@export var _homeserver_list: Control = null

func _homeserver_info_changed() -> void:
	_update_radio_buttons()

func _on_continue_button_pressed() -> void:
	var button: BaseButton = _button_group.get_pressed_button()
	var url: String = ""
	if button:
		url = button.get_meta("url")
		
	url_selected.emit(url)

func _on_other_homeserver_line_edit_editing_toggled(_toggled_on: bool) -> void:
	if _other_homeserver_checkbox:
		_other_homeserver_checkbox.button_pressed = true
	
func _on_other_homeserver_line_edit_text_changed(p_text: String) -> void:
	if _other_homeserver_checkbox:
		_other_homeserver_checkbox.set_meta("url", p_text)
	
func _update_radio_buttons() -> void:
	if _homeserver_list:
		for child: Node in _homeserver_list.get_children():
			if child.owner == null:
				child.queue_free()
				_homeserver_list.remove_child(child)
		
		var ticked_checkbox: Control = null
		
		if homeserver_info:
			for homeserver: String in homeserver_info.homeserver_list:
				var checkbox: CheckBox = CheckBox.new()
				checkbox.text = homeserver
				checkbox.flat = true
				checkbox.button_group = _button_group
				checkbox.set_meta("url", homeserver)
				
				if not ticked_checkbox:
					ticked_checkbox = checkbox
					ticked_checkbox.button_pressed = true
				
				_homeserver_list.add_child(checkbox)
				
			# Other Homeserver option
			if homeserver_info.allow_custom_homeserver:
				var hbox_container: HBoxContainer = HBoxContainer.new()
				hbox_container.name = "OtherContainer"
				if hbox_container:
					_other_homeserver_checkbox = CheckBox.new()
					_other_homeserver_checkbox.text = ""
					_other_homeserver_checkbox.flat = true
					_other_homeserver_checkbox.button_group = _button_group
					_other_homeserver_checkbox.set_meta("url", "")
					hbox_container.add_child(_other_homeserver_checkbox)
					
					if not ticked_checkbox:
						ticked_checkbox = _other_homeserver_checkbox
						ticked_checkbox.button_pressed = true
					
					_other_homeserver_line_edit = LineEdit.new()
					_other_homeserver_line_edit.size_flags_horizontal = Control.SIZE_FILL
					_other_homeserver_line_edit.flat = true
					_other_homeserver_line_edit.placeholder_text = "Other Homeserver"
					_other_homeserver_line_edit.expand_to_text_length = true
					_other_homeserver_line_edit.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_URL
					assert(_other_homeserver_line_edit.editing_toggled.connect(_on_other_homeserver_line_edit_editing_toggled) == OK)
					assert(_other_homeserver_line_edit.text_changed.connect(_on_other_homeserver_line_edit_text_changed) == OK)
					hbox_container.add_child(_other_homeserver_line_edit)
					
					_homeserver_list.add_child(hbox_container)
		

func _ready() -> void:
	_update_radio_buttons()
	
###

@export var homeserver_info: VSKHomeServerInfo = null:
	set(p_homeserver_info):
		if homeserver_info:
			homeserver_info.changed.disconnect(_homeserver_info_changed)
		
		homeserver_info = p_homeserver_info
		
		if homeserver_info:
			assert(homeserver_info.changed.connect(_homeserver_info_changed) == OK)
		
		_update_radio_buttons()
		
func set_url(p_url: String) -> void:
	if not is_node_ready():
		await ready
	
	if _homeserver_list:
		for child: Node in _homeserver_list.get_children():
			if child.has_meta("url"):
				if child.get_meta("url") == p_url:
					if child is BaseButton:
						child.button_pressed = true
						return
						
		if _other_homeserver_line_edit and _other_homeserver_checkbox:
			if _other_homeserver_line_edit.visible:
				_other_homeserver_line_edit.text = p_url
				_other_homeserver_checkbox.button_pressed = true
