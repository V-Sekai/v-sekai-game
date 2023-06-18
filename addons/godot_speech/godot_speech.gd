# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# godot_speech.gd
# SPDX-License-Identifier: MIT

extends Speech


func _ready() -> void:
	if !Engine.is_editor_hint():
		set_name("GodotSpeech")
		var result = NetworkManager.peer_unregistered.connect(remove_player_audio)
		if result != OK:
			printerr("Failed to connect signal 'peer_unregistered' to 'remove_player_audio'.")
			return
