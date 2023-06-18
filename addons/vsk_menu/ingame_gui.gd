# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# ingame_gui.gd
# SPDX-License-Identifier: MIT

extends Control

@export var audio_icon_path: NodePath = NodePath()
var audio_icon: Node2D = null

@export var audio_icon_state_path: NodePath = NodePath()
var audio_icon_state: Sprite2D = null

@export var audio_icon_loudness_path: NodePath = NodePath()
var audio_icon_loudness: Sprite2D = null

const MARGIN_SCALE = 10
const SPRITE_SCALE = 0.2
const HALF_SCALE = 0.5

const STUTTER_THRESHOLD = 0.001
const MINIMAL_THRESHOLD = 0.002

@export var mic_muted_texture_icon: Texture2D
@export var mic_on_texture_icon: Texture2D
@export var mic_off_texture_icon: Texture2D
@export var loudness_visualisation_curve: Curve = Curve.new()

var should_resize: bool = true
var targeted_loudness = 0.0


func gameflow_state_changed(p_state) -> void:
	if p_state == VSKGameFlowManager.GAMEFLOW_STATE_INGAME:
		show()
	else:
		hide()


func _ready():
	if VSKGameFlowManager.gameflow_state_changed.connect(self.gameflow_state_changed) != OK:
		printerr("Could not connect signal gameflow_state_changed")

	if VSKAudioManager.audio_gate_or_muted_state_changed.connect(self.update_audio_icon) != OK:
		printerr("Could not connect signal audio_gate_or_muted_state_changed")

	audio_icon = get_node_or_null(audio_icon_path)
	audio_icon_state = get_node_or_null(audio_icon_state_path)
	audio_icon_loudness = get_node_or_null(audio_icon_loudness_path)

	set_process(true)

	update_audio_icon()
	_resize()

	gameflow_state_changed(VSKGameFlowManager.gameflow_state)


func update_audio_icon() -> void:
	if audio_icon_state:
		if VSKAudioManager.muted:
			audio_icon_state.texture = mic_muted_texture_icon
		else:
			if VSKAudioManager.gated:
				audio_icon_state.texture = mic_off_texture_icon
			else:
				audio_icon_state.texture = mic_on_texture_icon


func _resize() -> void:
	if audio_icon_state:
		var texture_size: Vector2 = audio_icon_state.texture.get_size() * audio_icon_state.scale

		audio_icon.position = Vector2(get_rect().size.x - texture_size.x, 0.0 + texture_size.y)


func _process(_delta):
	if should_resize:
		if audio_icon:
			var texture_size: Vector2 = audio_icon_state.texture.get_size() * SPRITE_SCALE * HALF_SCALE

			audio_icon.position = Vector2(get_rect().size.x - texture_size.x - MARGIN_SCALE, texture_size.y + MARGIN_SCALE)

			audio_icon.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)

			should_resize = false

	if VSKAudioManager.should_send_audio() and VSKAudioManager.loudness > MINIMAL_THRESHOLD:
		if abs(targeted_loudness - VSKAudioManager.loudness) > STUTTER_THRESHOLD:
			var audio_scale: float = 1.0 + loudness_visualisation_curve.sample(VSKAudioManager.loudness)
			audio_icon_loudness.scale = Vector2(audio_scale, audio_scale)

		targeted_loudness = VSKAudioManager.loudness
	else:
		audio_icon_loudness.scale = Vector2(1.0, 1.0)


func _on_resized():
	should_resize = true
