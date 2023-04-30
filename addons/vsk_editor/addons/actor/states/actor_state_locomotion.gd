# res://addons/actor/states/actor_state_locomotion.gd
# This file is part of the V-Sekai Game.
# https://github.com/V-Sekai/actor
#
# Copyright (c) 2018-2022 SaracenOne
# Copyright (c) 2019-2022 K. S. Ernest (iFire) Lee (fire)
# Copyright (c) 2020-2022 Lyuma
# Copyright (c) 2020-2022 MMMaellon
# Copyright (c) 2022 V-Sekai Contributors
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

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

	state_machine.set_velocity(
		input_direction * state_machine.actor_controller.walk_speed * state_machine.get_input_magnitude()
	)

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
