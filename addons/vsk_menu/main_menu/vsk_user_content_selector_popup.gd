extends Window

signal path_selected(p_path)


func _on_uro_id_selected(p_id):
	path_selected.emit("uro://" + p_id)
	hide()


func _on_file_selected(p_path):
	path_selected.emit(ProjectSettings.localize_path(p_path))
	hide()
