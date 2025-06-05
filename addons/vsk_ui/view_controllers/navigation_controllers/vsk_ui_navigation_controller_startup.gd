@tool
extends SarUINavigationController
class_name VSKUINavigationControllerStartup

func _back_button_pressed() -> void:
	pop_view_controller(true)
	
func _clear_content(p_delete: bool) -> void:
	if content:
		for child in content.get_children():
			for sub_child in child.get_children():
				if sub_child is SarUIViewController:
					if p_delete:
						sub_child.queue_free()
					sub_child.get_parent().remove_child(sub_child)
			
			child.queue_free()

func _add_view_controller_to_content(p_view_controller: SarUIViewController) -> void:
	var vbox: VBoxContainer = VBoxContainer.new()
	#var navbar: HBoxContainer = HBoxContainer.new()
	#var button: Button = Button.new()
	#button.text = "Back"
	#assert(button.pressed.connect(_back_button_pressed) == OK)
	
	#navbar.add_child(button)
	if get_view_controllers().size() > 1:
		back_button.show()
		#vbox.add_child(navbar)
	else:
		back_button.hide()
	
	vbox.add_child(p_view_controller)
	p_view_controller.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	if content:
		content.add_child(vbox, true)
		vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		
	title_label.text = p_view_controller.get_title()

func _ready() -> void:
	if not Engine.is_editor_hint():
		back_button.hide()
		assert(back_button.pressed.connect(_back_button_pressed) == OK)

###

@export var title_label: Label = null
@export var back_button: Button = null

signal message_box_requested(p_title: String, p_body: String)

func show_messagebox(p_title: String, p_body: String) -> void:
	assert(message_box_requested.has_connections())
	
	block_input()
	message_box_requested.emit(p_title, p_body)

func show_keyboard() -> void:
	pass
	
func hide_keyboard() -> void:
	pass
