@tool
class_name VSKKeyboardButtonInput
extends VSKKeyboardButton

@export var display_name_lowercase: String = "":
	set(p_name):
		display_name_lowercase = p_name
		emit_changed()
		
@export var display_name_uppercase: String = "":
	set(p_name):
		display_name_uppercase = p_name
		emit_changed()
		
@export var keycode_lowercase: int = 0:
	set(p_keycode):
		keycode_lowercase = p_keycode
		emit_changed()
		
@export var keycode_uppercase: int = 0:
	set(p_keycode):
		keycode_uppercase = p_keycode
		emit_changed()
