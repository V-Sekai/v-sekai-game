# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# actor_state_noclip.gd
# SPDX-License-Identifier: MIT

extends "res://addons/actor/states/actor_state.gd"  # actor_state.gd


func locomotion() -> void:
	var input_direction: Vector3 = state_machine.get_input_direction()

	var velocity: Vector3 = input_direction * state_machine.get_input_magnitude()
	velocity += Vector3.UP * state_machine.get_vertical_input()
	velocity = velocity.normalized()

	velocity *= state_machine.actor_controller.fly_speed

	state_machine.set_velocity(velocity)

	state_machine.set_movement_vector(state_machine.get_velocity())


func enter() -> void:
	if !state_machine.is_noclipping():
		change_state("Falling")


func update(_delta: float) -> void:
	if !state_machine.is_noclipping():
		change_state("Falling")
	else:
		locomotion()


func exit() -> void:
	pass
