# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_audio_manager.gd
# SPDX-License-Identifier: MIT

@tool
extends Node

var connection_util_const = preload("res://addons/gd_util/connection_util.gd")

var audio_input_stream: AudioStream = null
var audio_input_stream_player: AudioStreamPlayer = null

const PACKET_TICK_TIMESLICE = 10
const MIC_BUS_NAME = "Mic"
const AEC_BUS_NAME = "Master"

var voice_buffer_overrun_count: int = 0
var voice_id: int = 0
var voice_timeslice: int = 0
var voice_recording_started: bool = false


# TESTING
func get_required_packet_count(p_playback: AudioStreamPlayback, p_frame_size: int) -> int:
	var to_fill: int = p_playback.get_frames_available()
	#print("to_fill " + str(to_fill))
	var required_packets: int = 0
	while to_fill >= p_frame_size:
		to_fill -= p_frame_size
		required_packets += 1

	return required_packets


func test_voice_locally() -> void:
	## Testing
	if !speech_decoder:
		speech_decoder = godot_speech.get_speech_decoder()
	var playback: AudioStreamPlayback = local_mic_test.get_stream_playback()
	var required_packets: int = get_required_packet_count(playback, PACKET_FRAME_COUNT)

	var current_voice_id: int = get_current_voice_id()
	var copied_voice_buffer: Array = get_voice_buffers()

	for i in range(0, required_packets):
		var copied_voice_buffer_size: int = copied_voice_buffer.size()
		if copied_voice_buffer_size > 0:
			print("voice_id: %s" % str(current_voice_id))
			print("voice_timeslice: %s" % str(voice_timeslice + i))

			var voice_buffer = copied_voice_buffer.front()
			uncompressed_audio = godot_speech.decompress_buffer(speech_decoder, voice_buffer["byte_array"], voice_buffer["buffer_size"], uncompressed_audio)

			playback.push_buffer(uncompressed_audio)
			copied_voice_buffer.pop_front()
			current_voice_id += 1
		#else:
		#print("EMPTY")
		#for j in range(0, 16):
		#	playback.push_buffer(empty_buffer)

	print("skips: " + str(playback.get_skips()))


const PACKET_FRAME_COUNT = 480
var empty_buffer: PackedVector2Array = PackedVector2Array()
var uncompressed_audio: PackedVector2Array = PackedVector2Array()
var local_mic_test: AudioStreamPlayer = null
var speech_decoder: SpeechDecoder = null

#~

var spatial_node: Node3D = null

const USER_PREFERENCES_SECTION_NAME = "audio"

const VOICE_OUTPUT_BUS_NAME = "VoiceOutput"
const MUSIC_OUTPUT_BUS_NAME = "MusicOutput"
const GAME_SFX_OUTPUT_BUS_NAME = "GameSFXOutput"
const MENU_OUTPUT_BUS_NAME = "MenuOutput"
const MIC_INPUT_BUS_NAME = "MicInput"

var godot_speech: Speech = null

var audio_start_tick: int = 0

# Buses
var voice_output_bus_index: int = -1
var music_output_bus_index: int = -1
var game_sfx_output_bus_index: int = -1
var menu_output_bus_index: int = -1
var mic_input_bus_index: int = -1

# Volumes
var voice_output_volume: float = 1.0
var music_output_volume: float = 1.0
var game_sfx_output_volume: float = 1.0
var menu_output_volume: float = 1.0
var mic_input_volume: float = 1.0

var ignore_network_voice_packets: bool = false

var signal_table: Array = [{"singleton": "VSKGameFlowManager", "signal": "ingame_started", "method": "_ingame_started"}, {"singleton": "VSKGameFlowManager", "signal": "ingame_ended", "method": "_ingame_ended"}, {"singleton": "VSKGameFlowManager", "signal": "is_quitting", "method": "set_settings_values"}]

const MAX_VOICE_BUFFERS = 16
var voice_buffers: Array = []

var dynamic_stream_players: Array = []
var dynamic_3d_stream_players: Array = []

var flat_output_device: String = "Default"
var flat_input_device: String = "Default"
var xr_output_device: String = "Default"
var xr_input_device: String = "Default"

# Path to a file which can be played automatically by GodotSpeech instead
# of mic input
var test_audio: String = ""

var gate_threshold: float = 0.003
# How long the loudness has to beneath
# the threshold before it gates itself.
var gate_timeout: float = 0.5

# The state of mic input
var gate_timer: float = 0.0  # How long have we been below the gate threshold
var loudness: float = 0.0  # How loud are we this frame
var muted: bool = true:
	set = set_muted,
	get = is_muted
# Are we muted?
var gated: bool = true:
	set = set_gated,
	get = is_gated
# Are we voice gated?

signal audio_gate_or_muted_state_changed


static func get_audio_output_devices() -> PackedStringArray:
	return AudioServer.get_output_device_list()


static func get_audio_input_devices() -> PackedStringArray:
	return AudioServer.get_input_device_list()


func set_muted(p_muted) -> void:
	if muted != p_muted:
		muted = p_muted
		audio_gate_or_muted_state_changed.emit()


func is_muted() -> bool:
	return muted


func set_gated(p_gated) -> void:
	if gated != p_gated:
		gated = p_gated
		audio_gate_or_muted_state_changed.emit()


func is_gated() -> bool:
	return gated


func should_send_audio() -> bool:
	if !is_muted() and !is_gated():
		return true
	else:
		return false


func voice_packet_compressed(p_peer_id: int, p_sequence_id: int, p_buffer: PackedByteArray) -> void:
	if godot_speech and !ignore_network_voice_packets:
		godot_speech.on_received_audio_packet(p_peer_id, p_sequence_id, p_buffer)


func update_audio_devices() -> void:
	if !Engine.is_editor_hint():
		if VRManager.is_xr_active():
			AudioServer.set_input_device(xr_output_device)
			AudioServer.set_output_device(xr_input_device)
		else:
			AudioServer.set_input_device(flat_output_device)
			AudioServer.set_output_device(flat_input_device)


func get_voice_timeslice() -> int:
	return voice_timeslice


func reset_voice_timeslice() -> void:
	audio_start_tick = Time.get_ticks_msec()
	voice_timeslice = 0


func get_current_voice_id() -> int:
	return voice_id


func reset_voice_id() -> void:
	voice_id = 0


func get_ticks_since_recording_started() -> int:
	return Time.get_ticks_msec() - audio_start_tick


func _ingame_started():
	if godot_speech and !VSKNetworkManager.is_dedicated_server():
		godot_speech.start_recording()

		voice_recording_started = true

		reset_voice_id()
		reset_voice_timeslice()


func _ingame_ended():
	if godot_speech:
		godot_speech.end_recording()
		voice_recording_started = false


##
## Global Audio
##


func _audio_stream_player_finished(p_audio_stream_player: AudioStreamPlayer) -> void:
	stop_audio_stream(p_audio_stream_player)


func play_oneshot_audio_stream(p_stream: AudioStream, p_bus_name: String, p_volume_db: float = linear_to_db(1.0)) -> void:
	var audio_stream_player: AudioStreamPlayer = AudioStreamPlayer.new()
	audio_stream_player.name = "OneshotAudioStream"
	audio_stream_player.stream = p_stream
	audio_stream_player.autoplay = true
	audio_stream_player.bus = p_bus_name
	audio_stream_player.volume_db = p_volume_db

	assert(audio_stream_player.finished.connect(self._audio_stream_player_finished.bind(audio_stream_player)) == OK)

	add_child(audio_stream_player, true)


func stop_audio_stream(p_stream_player: AudioStreamPlayer) -> void:
	var index: int = dynamic_stream_players.find(p_stream_player)
	if index != -1:
		dynamic_stream_players.remove_at(index)

	p_stream_player.stop()
	p_stream_player.queue_free()
	p_stream_player.get_parent().remove_child(p_stream_player)


func clear_dynamic_audio_stream_players():
	for stream_player in dynamic_stream_players:
		stop_audio_stream(stream_player)

	dynamic_stream_players = []


##
## 3D Audio
##


func _audio_stream_3d_player_finished(p_audio_stream_player_3d: AudioStreamPlayer3D) -> void:
	stop_audio_stream_3d(p_audio_stream_player_3d)


func play_oneshot_audio_stream_3d(p_stream: AudioStream, p_bus_name: String, p_transform: Transform3D) -> void:
	if spatial_node:
		var audio_stream_player_3d: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
		audio_stream_player_3d.name = "Oneshot3DAudioStream"
		audio_stream_player_3d.stream = p_stream
		audio_stream_player_3d.autoplay = true
		audio_stream_player_3d.bus = p_bus_name
		audio_stream_player_3d.max_polyphony = 128

		assert(audio_stream_player_3d.finished.connect(self._audio_stream_3d_player_finished.bind(audio_stream_player_3d)) == OK)

		spatial_node.add_child(audio_stream_player_3d, true)
		audio_stream_player_3d.global_transform = p_transform


func stop_audio_stream_3d(p_stream_player: AudioStreamPlayer3D) -> void:
	var index: int = dynamic_3d_stream_players.find(p_stream_player)
	if index != -1:
		dynamic_3d_stream_players.remove_at(index)

	p_stream_player.stop()
	p_stream_player.queue_free()
	p_stream_player.get_parent().remove_child(p_stream_player)


func clear_dynamic_audio_stream_players_3d():
	for stream_player in dynamic_3d_stream_players:
		stop_audio_stream_3d(stream_player)

	dynamic_3d_stream_players = []


func toggle_mute() -> void:
	if is_muted():
		set_muted(false)
	else:
		set_muted(true)


func get_voice_output_volume() -> float:
	return voice_output_volume


func get_music_output_volume() -> float:
	return music_output_volume


func get_game_sfx_output_volume() -> float:
	return game_sfx_output_volume


func get_menu_output_volume() -> float:
	return menu_output_volume


func get_mic_input_volume() -> float:
	return mic_input_volume


func set_voice_output_volume(p_value: float) -> void:
	voice_output_volume = p_value
	if voice_output_bus_index != -1:
		AudioServer.set_bus_volume_db(voice_output_bus_index, linear_to_db(voice_output_volume))


func set_music_output_volume(p_value: float) -> void:
	music_output_volume = p_value
	if music_output_bus_index != -1:
		AudioServer.set_bus_volume_db(music_output_bus_index, linear_to_db(music_output_volume))


func set_game_sfx_output_volume(p_value: float) -> void:
	game_sfx_output_volume = p_value
	if game_sfx_output_bus_index != -1:
		AudioServer.set_bus_volume_db(game_sfx_output_bus_index, linear_to_db(game_sfx_output_volume))


func set_menu_output_volume(p_value: float) -> void:
	menu_output_volume = p_value
	if menu_output_bus_index != -1:
		AudioServer.set_bus_volume_db(menu_output_bus_index, linear_to_db(menu_output_volume))


func set_mic_input_volume(p_value: float) -> void:
	mic_input_volume = p_value
	if mic_input_bus_index != -1:
		AudioServer.set_bus_volume_db(mic_input_bus_index, linear_to_db(mic_input_volume))


func set_settings_values():
	VSKUserPreferencesManager.set_value(USER_PREFERENCES_SECTION_NAME, "flat_output_device", flat_output_device)
	VSKUserPreferencesManager.set_value(USER_PREFERENCES_SECTION_NAME, "flat_input_device", flat_input_device)
	VSKUserPreferencesManager.set_value(USER_PREFERENCES_SECTION_NAME, "xr_output_device", xr_output_device)
	VSKUserPreferencesManager.set_value(USER_PREFERENCES_SECTION_NAME, "xr_input_device", xr_input_device)
	VSKUserPreferencesManager.set_value(USER_PREFERENCES_SECTION_NAME, "muted", muted)

	VSKUserPreferencesManager.set_value(USER_PREFERENCES_SECTION_NAME, "voice_output_volume", voice_output_volume)
	VSKUserPreferencesManager.set_value(USER_PREFERENCES_SECTION_NAME, "music_output_volume", music_output_volume)
	VSKUserPreferencesManager.set_value(USER_PREFERENCES_SECTION_NAME, "game_sfx_output_volume", game_sfx_output_volume)
	VSKUserPreferencesManager.set_value(USER_PREFERENCES_SECTION_NAME, "menu_output_volume", menu_output_volume)
	VSKUserPreferencesManager.set_value(USER_PREFERENCES_SECTION_NAME, "mic_input_volume", mic_input_volume)

	VSKUserPreferencesManager.set_value(USER_PREFERENCES_SECTION_NAME, "ignore_network_voice_packets", ignore_network_voice_packets)
	VSKUserPreferencesManager.set_value(USER_PREFERENCES_SECTION_NAME, "gate_threshold", gate_threshold)
	VSKUserPreferencesManager.set_value(USER_PREFERENCES_SECTION_NAME, "gate_timeout", gate_timeout)


func get_settings_values() -> void:
	flat_output_device = VSKUserPreferencesManager.get_value(USER_PREFERENCES_SECTION_NAME, "flat_output_device", TYPE_STRING, flat_output_device)
	flat_input_device = VSKUserPreferencesManager.get_value(USER_PREFERENCES_SECTION_NAME, "flat_input_device", TYPE_STRING, flat_input_device)
	xr_output_device = VSKUserPreferencesManager.get_value(USER_PREFERENCES_SECTION_NAME, "xr_output_device", TYPE_STRING, xr_output_device)
	xr_input_device = VSKUserPreferencesManager.get_value(USER_PREFERENCES_SECTION_NAME, "xr_input_device", TYPE_STRING, xr_input_device)
	muted = VSKUserPreferencesManager.get_value(USER_PREFERENCES_SECTION_NAME, "muted", TYPE_BOOL, muted)

	voice_output_volume = VSKUserPreferencesManager.get_value(USER_PREFERENCES_SECTION_NAME, "voice_output_volume", TYPE_FLOAT, voice_output_volume)
	music_output_volume = VSKUserPreferencesManager.get_value(USER_PREFERENCES_SECTION_NAME, "music_output_volume", TYPE_FLOAT, music_output_volume)
	game_sfx_output_volume = VSKUserPreferencesManager.get_value(USER_PREFERENCES_SECTION_NAME, "game_sfx_output_volume", TYPE_FLOAT, game_sfx_output_volume)
	menu_output_volume = VSKUserPreferencesManager.get_value(USER_PREFERENCES_SECTION_NAME, "menu_output_volume", TYPE_FLOAT, menu_output_volume)
	mic_input_volume = VSKUserPreferencesManager.get_value(USER_PREFERENCES_SECTION_NAME, "mic_input_volume", TYPE_FLOAT, mic_input_volume)

	ignore_network_voice_packets = VSKUserPreferencesManager.get_value(USER_PREFERENCES_SECTION_NAME, "ignore_network_voice_packets", TYPE_BOOL, ignore_network_voice_packets)
	gate_threshold = VSKUserPreferencesManager.get_value(USER_PREFERENCES_SECTION_NAME, "gate_threshold", TYPE_FLOAT, gate_threshold)
	gate_timeout = VSKUserPreferencesManager.get_value(USER_PREFERENCES_SECTION_NAME, "gate_timeout", TYPE_FLOAT, gate_timeout)


func set_settings_values_and_save() -> void:
	set_settings_values()
	VSKUserPreferencesManager.save_settings()


func process_input_audio(p_delta: float):
	if godot_speech:
		var copied_voice_buffers: Array = godot_speech.copy_and_clear_buffers()

		var current_skipped: int = godot_speech.get_skipped_audio_packets()
		#print("current_skipped: %s" % str(current_skipped))
		godot_speech.clear_skipped_audio_packets()

		voice_id += current_skipped

		voice_timeslice = ((get_ticks_since_recording_started() / PACKET_TICK_TIMESLICE) - (copied_voice_buffers.size() + current_skipped))

		if copied_voice_buffers.size() > 0:
			loudness = 0.0
			for voice_buffer in copied_voice_buffers:
				voice_buffers.push_back(voice_buffer)
				if voice_buffer.loudness > loudness:
					loudness = voice_buffer.loudness

				if voice_buffers.size() > MAX_VOICE_BUFFERS:
					printerr("Voice buffer overrun!")
					voice_buffers.pop_front()
					voice_buffer_overrun_count += 1

	if !gated:
		# If the voice loudness is below the gate threshold,
		# increase the gate_timer until it has timeout and gate
		# the audio again
		if loudness < gate_threshold:
			gate_timer += p_delta
			if gate_timer > gate_timeout:
				set_gated(true)
		else:
			# If the loudness exceeds it
			# reset the timer
			gate_timer = 0.0
	else:
		# If the loudness hits the gate threshold, ungate.
		if loudness >= gate_threshold:
			set_gated(false)
			gate_timer = 0.0


# This function increments the internal voice_id
# Make sure to get it before calling it.
func get_voice_buffers() -> Array:
	# Increment the internal voice id
	voice_id += voice_buffers.size()

	var copied_voice_buffers: Array = voice_buffers
	voice_buffers = []
	return copied_voice_buffers


########
# Node #
########


func _input(event):
	if event.is_action_type():
		if event.is_action_pressed("mute"):
			if VSKGameFlowManager.gameflow_state == VSKGameFlowManager.GAMEFLOW_STATE_INGAME:
				toggle_mute()


func _process(p_delta):
	if voice_recording_started:
		process_input_audio(p_delta)

		#test_voice_locally()


func setup() -> void:
	if !Engine.is_editor_hint():
		test_audio = VSKStartupManager.test_audio

		empty_buffer.resize(PACKET_FRAME_COUNT)
		uncompressed_audio.resize(PACKET_FRAME_COUNT)

		godot_speech = GodotSpeech

		if not test_audio.is_empty():
			print("Using test audio at path %s..." % test_audio)
			audio_input_stream = AudioStreamWAV.new()
			var err: int = audio_input_stream.load(test_audio)
			if err != OK:
				printerr("Test audio could not be loaded!")
				audio_input_stream = null
			else:
				print("Loaded successfully!")
				audio_input_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD

		if !audio_input_stream:
			audio_input_stream = AudioStreamMicrophone.new()

		audio_input_stream_player = AudioStreamPlayer.new()
		audio_input_stream_player.stream = audio_input_stream

		var index: int = AudioServer.get_bus_index(MIC_BUS_NAME)
		if index != -1:
			audio_input_stream_player.set_bus(MIC_BUS_NAME)

		add_child(audio_input_stream_player, true)

		godot_speech.set_audio_input_stream_player(audio_input_stream_player)
		godot_speech.set_streaming_bus(MIC_BUS_NAME)
		godot_speech.set_error_cancellation_bus(AEC_BUS_NAME)

		spatial_node = Node3D.new()
		spatial_node.set_name("SpatialNode")
		add_child(spatial_node, true)

#		# Testing
#
#		local_mic_test = AudioStreamPlayer.new()
#		local_mic_test.set_name("LocalMicTest")
#		add_child(local_mic_test)
#
#		var new_generator: AudioStreamGenerator = AudioStreamGenerator.new()
#		new_generator.set_mix_rate(48000)
#		new_generator.set_buffer_length(0.1)
#
#		local_mic_test.set_stream(new_generator)
#		var playback = local_mic_test.get_stream_playback()
#		playback.push_buffer(empty_buffer)
#
#		#~

		voice_output_bus_index = AudioServer.get_bus_index(VOICE_OUTPUT_BUS_NAME)
		music_output_bus_index = AudioServer.get_bus_index(MUSIC_OUTPUT_BUS_NAME)
		game_sfx_output_bus_index = AudioServer.get_bus_index(GAME_SFX_OUTPUT_BUS_NAME)
		menu_output_bus_index = AudioServer.get_bus_index(MENU_OUTPUT_BUS_NAME)

		mic_input_bus_index = AudioServer.get_bus_index(MIC_INPUT_BUS_NAME)

		connection_util_const.connect_signal_table(signal_table, self)

		if !Engine.is_editor_hint():
			assert(NetworkManager.voice_packet_compressed.connect(self.voice_packet_compressed) == OK)

		get_settings_values()

		set_voice_output_volume(get_voice_output_volume())
		set_music_output_volume(get_music_output_volume())
		set_game_sfx_output_volume(get_game_sfx_output_volume())
		set_menu_output_volume(get_menu_output_volume())
		set_mic_input_volume(get_mic_input_volume())

	if !Engine.is_editor_hint():
		assert(VRManager.xr_mode_changed.connect(self.update_audio_devices) == OK)

	update_audio_devices()


func _ready():
	if !Engine.is_editor_hint():
		set_process(true)
		set_process_input(true)
	else:
		set_process(false)
		set_process_input(false)
