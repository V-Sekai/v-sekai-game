# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# emote_theme_generator.gd
# SPDX-License-Identifier: MIT

@tool
extends EditorScript

# Run this script in the editor.

const emote_theme_const = preload("emote_theme.gd")


func _run():
	var theme = emote_theme_const.generate_emote_theme(Theme, 1.0)
	ResourceSaver.save(theme, "res://addons/emote_theme/emote_theme.tres")
