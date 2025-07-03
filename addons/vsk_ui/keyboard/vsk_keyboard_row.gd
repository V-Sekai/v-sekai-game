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
				if not SarUtils.assert_ok(button.changed.connect(emit_changed),
					"Could not connect signal 'button.changed' to 'emit_changed'"):
					return
		
		emit_changed()
