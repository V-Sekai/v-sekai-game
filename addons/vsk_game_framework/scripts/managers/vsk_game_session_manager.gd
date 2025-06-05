# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_game_session_manager.gd
# SPDX-License-Identifier: MIT

@tool
extends SarGameSessionManager
class_name VSKGameSessionManager

func _create_authentication_node() -> SarGameSessionAuthentication:
	return VSKGameSessionAuthentication.new()

func is_avatar_path_allowed_for_avatar_sync(_sync: VSKGameEntityComponentAvatarSync, _path: String):
	return true
