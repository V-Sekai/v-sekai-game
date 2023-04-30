extends Control


func export_data() -> Dictionary:
	return {}


func _ready():
	var vsk_editor: Node = get_node_or_null("/root/VSKEditor")
	if vsk_editor:
		vsk_editor.setup_editor(self, null, null)
	else:
		printerr("Could not load VSKEditor!")
