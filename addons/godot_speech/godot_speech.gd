extends Speech

var audio_stats_timer: Timer = Timer.new()


func _ready() -> void:
	add_child(audio_stats_timer)
	audio_stats_timer.owner = owner
	audio_stats_timer.wait_time = 0.5
	audio_stats_timer.timeout.connect(Callable(self, "print_audio_stats"))
	audio_stats_timer.start()
	if !Engine.is_editor_hint():
		set_name("GodotSpeech")
		assert(NetworkManager.peer_unregistered.connect(remove_player_audio) == OK)
