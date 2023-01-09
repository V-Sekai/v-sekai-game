extends Node

var godot_speech: Speech = Speech.new()


func get_skipped_audio_packets() -> int:
	if godot_speech:
		return godot_speech.get_skipped_audio_packets()
	else:
		return -1


func clear_skipped_audio_packets() -> void:
	if godot_speech:
		godot_speech.clear_skipped_audio_packets()


func start_recording() -> bool:
	if godot_speech:
		return godot_speech.start_recording()

	return false


func end_recording() -> bool:
	var result: bool = false
	if godot_speech:
		# FIXME: fire 2022-07-05 Remove hack to convert null to false
		result = godot_speech.end_recording() if true else false

	return result


func decompress_buffer(p_decoder: RefCounted, p_byte_array: PackedByteArray, p_buffer_size: int, p_uncompressed_audio: PackedVector2Array):
	return godot_speech.decompress_buffer(p_decoder, p_byte_array, p_buffer_size, p_uncompressed_audio)


func copy_and_clear_buffers() -> Array:
	if godot_speech:
		var buffer: Array = godot_speech.copy_and_clear_buffers()
		return buffer
	else:
		return []


func on_received_external_audio_packet(p_peer_id: int, p_sequence_id: int, p_buffer: PackedByteArray) -> void:
	godot_speech.on_received_audio_packet(p_peer_id, p_sequence_id, p_buffer)


func set_streaming_bus(p_name: String) -> void:
	if godot_speech:
		godot_speech.set_streaming_bus(p_name)
	else:
		printerr("Could not set streaming bus")


func set_error_cancellation_bus(p_name: String) -> void:
	if godot_speech:
		godot_speech.set_error_cancellation_bus(p_name)
	else:
		printerr("Could not set error cancellation bus")


func set_audio_input_stream_player(p_audio_stream_player: AudioStreamPlayer) -> void:
	if godot_speech:
		godot_speech.set_audio_input_stream_player(p_audio_stream_player)
	else:
		printerr("Could not set audio input stream player")


func get_speech_decoder() -> RefCounted:
	if godot_speech:
		return godot_speech.get_speech_decoder()
	else:
		return null


func _ready() -> void:
	if !Engine.is_editor_hint():
		godot_speech.set_name("GodotSpeech")
		add_child(godot_speech, true)
		assert(NetworkManager.peer_unregistered.connect(godot_speech.remove_player_audio) == OK)
