extends Speech

func _ready() -> void:
	if !Engine.is_editor_hint():
		set_name("GodotSpeech")
		var result = NetworkManager.peer_unregistered.connect(remove_player_audio)
		if result != OK:
			printerr("Failed to connect signal 'peer_unregistered' to 'remove_player_audio'.")
			return
