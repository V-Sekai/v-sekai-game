# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# run_split.gd
# SPDX-License-Identifier: MIT

@tool
extends EditorScript

const sperlger_const = preload("res://addons/splerger/split_splerger.gd")


func _run():
	var root: Node = get_editor_interface().get_edited_scene_root()
	sperlger_const.traverse_root_and_split(root)
