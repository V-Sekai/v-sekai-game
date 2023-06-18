# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# actor_state_locomotion.gd
# SPDX-License-Identifier: MIT

extends "res://addons/actor/states/actor_state.gd"  # actor_state.gd


func locomotion() -> void:
	if !state_machine.is_attempting_movement():
		change_state("Stop")
		return
	else:
		pass

	if !state_machine.is_grounded():
		change_state("Falling")
		return

	var input_direction: Vector3 = state_machine.get_input_direction()

	state_machine.set_velocity(input_direction * state_machine.actor_controller.walk_speed * state_machine.get_input_magnitude())

	if state_machine.is_attempting_jumping():
		change_state("Pre-Jump")

	state_machine.set_movement_vector(state_machine.get_velocity())


func enter() -> void:
	if state_machine.is_noclipping():
		change_state("Noclip")
	else:
		locomotion()


func update(_delta: float) -> void:
	if state_machine.is_noclipping():
		change_state("Noclip")
	else:
		locomotion()


func exit() -> void:
	pass
