# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# actor_state_pre_jump.gd
# SPDX-License-Identifier: MIT

extends "res://addons/actor/states/actor_state.gd"  # actor_state.gd

const DEFAULT_JUMP_VELOCITY = 7.5


func enter() -> void:
	if state_machine.is_noclipping():
		change_state("Noclip")
	else:
		var jump_velocity: float = DEFAULT_JUMP_VELOCITY
		var jump_direction: Vector3 = Vector3.UP * jump_velocity

		state_machine.set_velocity(state_machine.get_velocity() + jump_direction)
		state_machine.set_movement_vector(state_machine.get_velocity())

		change_state("Falling")


func update(_delta: float) -> void:
	pass


func exit() -> void:
	pass
