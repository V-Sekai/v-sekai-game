@tool
class_name VSKKeyboard
extends VBoxContainer

var container: VBoxContainer = null

@export var keyboard_layout: VSKKeyboardLayout = null:
	set(p_keyboard_layout):
		if keyboard_layout:
			if keyboard_layout.changed.is_connected(_keyboard_layout_updated):
				keyboard_layout.changed.disconnect(_keyboard_layout_updated)
		
		keyboard_layout = p_keyboard_layout
		
		if keyboard_layout:
			assert(keyboard_layout.changed.connect(_keyboard_layout_updated) == OK)
		
		_keyboard_layout_updated()

func key_input_pressed(p_scan_code_text: String) -> void:
	# In practical terms, we should try and develop and optional plugin which
	# would allow the simulating keypresses at the OS-level. This would
	# allow hooking into more region-specific support such as IMEs.
	
	var scan_code: Key = OS.find_keycode_from_string(p_scan_code_text)
	
	var input := InputEventKey.new()
	input.physical_keycode = scan_code
	input.unicode = scan_code
	input.pressed = true
	input.keycode = scan_code
	input.shift_pressed = false

	Input.parse_input_event(input)

func _keyboard_layout_updated() -> void:
	if is_node_ready():
		if container:
			container.queue_free()
			
		container = VBoxContainer.new()
		add_child(container)
		container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_KEEP_SIZE)
		#container.owner = self
		
		if keyboard_layout:
			for keyboard_row: VSKKeyboardRow in keyboard_layout.rows:
				if keyboard_row:
					var h_container: HBoxContainer = HBoxContainer.new()
					container.add_child(h_container)
					#h_container.owner = self
					for keyboard_button: VSKKeyboardButton in keyboard_row.buttons:
						if keyboard_button:
							if keyboard_button is VSKKeyboardButtonInput:
								var button: Button = Button.new()
								h_container.add_child(button)
								button.text = (keyboard_button as VSKKeyboardButtonInput).display_name_lowercase
								button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
								#button.owner = self
								button.focus_mode = Control.FOCUS_NONE
								button.pressed.connect(key_input_pressed.bind(keyboard_button.display_name_lowercase))
							elif keyboard_button is VSKKeyboardButtonBackspace:
								var button: Button = Button.new()
								h_container.add_child(button)
								button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
								button.focus_mode = Control.FOCUS_NONE
							elif keyboard_button is VSKKeyboardButtonReturn:
								var button: Button = Button.new()
								h_container.add_child(button)
								button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
								button.focus_mode = Control.FOCUS_NONE
							elif keyboard_button is VSKKeyboardButtonShift:
								var button: Button = Button.new()
								h_container.add_child(button)
								button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
								button.focus_mode = Control.FOCUS_NONE
							else:
								var empty: Control = Control.new()
								h_container.add_child(empty)
								empty.size_flags_horizontal = Control.SIZE_EXPAND_FILL
						else:
							var empty: Control = Control.new()
							h_container.add_child(empty)
							empty.size_flags_horizontal = Control.SIZE_EXPAND_FILL


func _ready() -> void:
	_keyboard_layout_updated()
