# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# actor_state_stop.gd
# SPDX-License-Identifier: MIT

extends "res://addons/actor/states/actor_state.gd"  # actor_state.gd


func enter() -> void:
	if state_machine.is_noclipping():
		change_state("Noclip")
	else:
		if !state_machine.is_attempting_movement():
			change_state("Idle")
		else:
			change_state("Locomotion")


func update(_delta: float) -> void:
	pass


func exit() -> void:
	pass
