extends Speech

var audio_stats_timer: Timer = Timer.new()


func print_audio_stats():
	var performance_monitor: Node = get_node("/root/PerformanceMonitor")
	if not performance_monitor:
		return
	var performance_monitor_gui: Node = performance_monitor.get("performance_monitor_gui")
	var audio_stats_path: NodePath = performance_monitor_gui.get("audio_stats_path")
	var audio_stats_label: Label = performance_monitor_gui.get_node(audio_stats_path)
	var audio_stats_string: String = var_to_str(get_stats())
	audio_stats_string = audio_stats_string.replacen("{", "")
	audio_stats_string = audio_stats_string.replacen("}", "")
	audio_stats_string = audio_stats_string.replacen(",", "")
	audio_stats_string = audio_stats_string.replacen('"', "")
	audio_stats_label.set_text(audio_stats_string)


func _ready() -> void:
	add_child(audio_stats_timer)
	audio_stats_timer.owner = owner
	audio_stats_timer.wait_time = 0.5
	audio_stats_timer.timeout.connect(Callable(self, "print_audio_stats"))
	audio_stats_timer.start()
	if !Engine.is_editor_hint():
		set_name("GodotSpeech")
		assert(NetworkManager.peer_unregistered.connect(remove_player_audio) == OK)
