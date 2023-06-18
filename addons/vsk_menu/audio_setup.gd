# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# audio_setup.gd
# SPDX-License-Identifier: MIT

extends "res://addons/vsk_menu/setup_menu.gd"  # setup_menu.gd

@export var flat_audio_output_nodepath: NodePath = NodePath()
var flat_audio_output_button: MenuButton = null

@export var flat_audio_input_nodepath: NodePath = NodePath()
var flat_audio_input_button: MenuButton = null

@export var xr_audio_output_nodepath: NodePath = NodePath()
var xr_audio_output_button: MenuButton = null

@export var xr_audio_input_nodepath: NodePath = NodePath()
var xr_audio_input_button: MenuButton = null

@export var voice_output_volume_nodepath: NodePath = NodePath()
var voice_output_volume_spinbox: SpinBox = null

@export var music_output_volume_nodepath: NodePath = NodePath()
var music_output_volume_spinbox: SpinBox = null

@export var game_sfx_output_volume_nodepath: NodePath = NodePath()
var game_sfx_output_volume_spinbox: SpinBox = null

@export var menu_output_volume_nodepath: NodePath = NodePath()
var menu_output_volume_spinbox: SpinBox = null

@export var mic_input_volume_nodepath: NodePath = NodePath()
var mic_input_volume_spinbox: SpinBox = null

const MAX_MUSIC_OUTPUT_RANGE = 100
const MAX_VOICE_OUTPUT_RANGE = 100
const MAX_GAME_SFX_OUTPUT_RANGE = 100
const MAX_MENU_OUTPUT_RANGE = 100
const MAX_MIC_INPUT_RANGE = 100


func _ready() -> void:
	var audio_output_devices: Array = VSKAudioManager.get_audio_output_devices()
	var audio_input_devices: Array = VSKAudioManager.get_audio_input_devices()

	var flat_output_device_index = audio_output_devices.find(VSKAudioManager.flat_output_device)
	var flat_input_device_index = audio_input_devices.find(VSKAudioManager.flat_input_device)
	var xr_output_device_index = audio_output_devices.find(VSKAudioManager.xr_output_device)
	var xr_input_device_index = audio_input_devices.find(VSKAudioManager.xr_input_device)

	flat_audio_output_button = get_node(flat_audio_output_nodepath)
	setup_menu_button(flat_audio_output_button, flat_output_device_index, audio_output_devices)
	if flat_audio_output_button.get_popup().connect("id_pressed", self._flat_audio_output_changed) != OK:
		printerr("Could not connect 'id_pressed'!")

	flat_audio_input_button = get_node(flat_audio_input_nodepath)
	setup_menu_button(flat_audio_input_button, flat_input_device_index, audio_input_devices)
	if flat_audio_input_button.get_popup().id_pressed.connect(self._flat_audio_input_changed) != OK:
		printerr("Could not connect 'id_pressed'!")

	xr_audio_output_button = get_node(xr_audio_output_nodepath)
	setup_menu_button(xr_audio_output_button, xr_output_device_index, audio_output_devices)
	if xr_audio_output_button.get_popup().id_pressed.connect(self._xr_audio_output_changed) != OK:
		printerr("Could not connect 'id_pressed'!")

	xr_audio_input_button = get_node(xr_audio_input_nodepath)
	setup_menu_button(xr_audio_input_button, xr_input_device_index, audio_input_devices)
	if xr_audio_input_button.get_popup().id_pressed.connect(self._xr_audio_input_changed) != OK:
		printerr("Could not connect 'id_pressed'!")

	var voice_output_volume: float = VSKAudioManager.get_voice_output_volume()
	var music_output_volume: float = VSKAudioManager.get_music_output_volume()
	var game_sfx_output_volume: float = VSKAudioManager.get_game_sfx_output_volume()
	var menu_output_volume: float = VSKAudioManager.get_menu_output_volume()
	var mic_input_volume: float = VSKAudioManager.get_mic_input_volume()

	voice_output_volume_spinbox = get_node(voice_output_volume_nodepath)
	voice_output_volume_spinbox.max_value = MAX_VOICE_OUTPUT_RANGE
	if voice_output_volume_spinbox.value_changed.connect(self.voice_output_volume_changed) != OK:
		printerr("Could not connect 'value_changed' for voice_output_volume_spinbox!")
		return
	voice_output_volume_spinbox.value = round(voice_output_volume * MAX_VOICE_OUTPUT_RANGE)

	music_output_volume_spinbox = get_node(music_output_volume_nodepath)
	music_output_volume_spinbox.max_value = MAX_MUSIC_OUTPUT_RANGE
	if music_output_volume_spinbox.value_changed.connect(self.music_output_volume_changed) != OK:
		printerr("Could not connect 'value_changed' for music_output_volume_spinbox!")
		return
	music_output_volume_spinbox.value = round(music_output_volume * MAX_MUSIC_OUTPUT_RANGE)

	game_sfx_output_volume_spinbox = get_node(game_sfx_output_volume_nodepath)
	game_sfx_output_volume_spinbox.max_value = MAX_GAME_SFX_OUTPUT_RANGE
	if game_sfx_output_volume_spinbox.value_changed.connect(self.game_sfx_output_volume_changed) != OK:
		printerr("Could not connect 'value_changed' for game_sfx_output_volume_spinbox!")
		return
	game_sfx_output_volume_spinbox.value = round(game_sfx_output_volume * MAX_GAME_SFX_OUTPUT_RANGE)

	menu_output_volume_spinbox = get_node(menu_output_volume_nodepath)
	menu_output_volume_spinbox.max_value = MAX_MENU_OUTPUT_RANGE
	if menu_output_volume_spinbox.value_changed.connect(self.menu_output_volume_changed) != OK:
		printerr("Could not connect 'value_changed' for menu_output_volume_spinbox!")
		return
	menu_output_volume_spinbox.value = round(menu_output_volume * MAX_MENU_OUTPUT_RANGE)

	mic_input_volume_spinbox = get_node(mic_input_volume_nodepath)
	mic_input_volume_spinbox.max_value = MAX_MIC_INPUT_RANGE
	if mic_input_volume_spinbox.value_changed.connect(self.mic_input_volume_changed) != OK:
		printerr("Could not connect 'value_changed' for mic_input_volume_spinbox!")
		return
	mic_input_volume_spinbox.value = round(mic_input_volume * MAX_MIC_INPUT_RANGE)


func _gameflow_state_changed(_p_state) -> void:
	pass


func will_appear() -> void:
	if VSKGameFlowManager.gameflow_state_changed.connect(self._gameflow_state_changed) != OK:
		printerr("Could not connect gameflow_state_changed!")


func will_disappear() -> void:
	if VSKGameFlowManager.gameflow_state_changed.is_connected(self._gameflow_state_changed):
		VSKGameFlowManager.gameflow_state_changed.disconnect(self._gameflow_state_changed)


func _flat_audio_output_changed(p_id: int) -> void:
	var audio_output_devices: Array = VSKAudioManager.get_audio_output_devices()
	VSKAudioManager.flat_output_device = audio_output_devices[p_id]
	update_menu_button_text(flat_audio_output_button, p_id, audio_output_devices)


func _flat_audio_input_changed(p_id: int) -> void:
	var audio_input_devices: Array = VSKAudioManager.get_audio_input_devices()
	VSKAudioManager.flat_input_device = audio_input_devices[p_id]
	update_menu_button_text(flat_audio_input_button, p_id, audio_input_devices)


func _xr_audio_output_changed(p_id: int) -> void:
	var audio_output_devices: Array = VSKAudioManager.get_audio_output_devices()
	VSKAudioManager.xr_output_device = audio_output_devices[p_id]
	update_menu_button_text(xr_audio_output_button, p_id, audio_output_devices)


func _xr_audio_input_changed(p_id: int) -> void:
	var audio_input_devices: Array = VSKAudioManager.get_audio_input_devices()
	VSKAudioManager.xr_input_device = audio_input_devices[p_id]
	update_menu_button_text(xr_audio_input_button, p_id, audio_input_devices)


func voice_output_volume_changed(p_value: float) -> void:
	VSKAudioManager.set_voice_output_volume(p_value / MAX_VOICE_OUTPUT_RANGE)


func music_output_volume_changed(p_value: float) -> void:
	VSKAudioManager.set_music_output_volume(p_value / MAX_MUSIC_OUTPUT_RANGE)


func game_sfx_output_volume_changed(p_value: float) -> void:
	VSKAudioManager.set_game_sfx_output_volume(p_value / MAX_GAME_SFX_OUTPUT_RANGE)


func menu_output_volume_changed(p_value: float) -> void:
	VSKAudioManager.set_menu_output_volume(p_value / MAX_MENU_OUTPUT_RANGE)


func mic_input_volume_changed(p_value: float) -> void:
	VSKAudioManager.set_mic_input_volume(p_value / MAX_MIC_INPUT_RANGE)


func save_changes() -> void:
	super.save_changes()

	VSKAudioManager.update_audio_devices()
	VSKAudioManager.set_settings_values_and_save()
