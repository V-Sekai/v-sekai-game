extends Label3D

func _enter_tree():
	text = str(get_tree().get_multiplayer().get_unique_id())
