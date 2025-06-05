@tool
class_name VSKKeyboardLayout
extends Resource

@export var rows: Array[VSKKeyboardRow] = []:
	set(p_rows):
		for row: VSKKeyboardRow in rows:
			if row:
				if row.changed.is_connected(emit_changed):
					row.changed.disconnect(emit_changed)
		
		rows = p_rows
		
		for row: VSKKeyboardRow in rows:
			if row:
				assert(row.changed.connect(emit_changed) == OK)
				
		emit_changed()
