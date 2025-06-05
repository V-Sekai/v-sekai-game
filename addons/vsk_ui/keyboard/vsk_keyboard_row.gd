@tool
class_name VSKKeyboardRow
extends Resource

@export var buttons: Array[VSKKeyboardButton] = []:
	set(p_buttons):
		for button: VSKKeyboardButton in buttons:
			if button:
				if button.changed.is_connected(emit_changed):
					button.changed.disconnect(emit_changed)
		
		buttons = p_buttons
		
		for button: VSKKeyboardButton in buttons:
			if button:
				assert(button.changed.connect(emit_changed) == OK)
		
		emit_changed()
