extends Speech


func _ready() -> void:
	if !Engine.is_editor_hint():
		set_name("GodotSpeech")
		assert(NetworkManager.peer_unregistered.connect(remove_player_audio) == OK)
