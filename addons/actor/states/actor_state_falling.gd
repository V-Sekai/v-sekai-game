# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# actor_state_falling.gd
# SPDX-License-Identifier: MIT

extends "res://addons/actor/states/actor_state.gd"  # actor_state.gd


func enter() -> void:
	pass


func update(p_delta: float) -> void:
	if state_machine.is_noclipping():
		change_state("Noclip")
	else:
		if state_machine.is_grounded():
			change_state("Landed")

		var gravity_delta: float = state_machine.get_actor_controller().get_gravity_speed() * p_delta
		var gravity_direction: Vector3 = state_machine.get_actor_controller().get_gravity_direction()

		state_machine.set_velocity(state_machine.get_velocity() + gravity_direction * gravity_delta)
		state_machine.set_movement_vector(state_machine.get_velocity())


func exit() -> void:
	pass
