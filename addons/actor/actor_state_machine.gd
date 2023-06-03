# res://addons/actor/actor_state_machine.gd
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

@tool
extends "res://addons/state_machine/state_machine.gd"

@export var actor_controller_path: NodePath = NodePath()
var actor_controller: Node = null  # of type actor_controller.gd

var noclip: bool = false

@onready var state_chart: StateChart = %StateChartWorkInProgress

func _change_state(state_name: String) -> void:
	##
	## 	The base state_machine interface this node extends does most of the work
	##
	if not _active:
		return
	super._change_state(state_name)


# Input actions
var input_direction: Vector3 = Vector3():
	set = set_input_direction


var input_magnitude: float = 0.0:
	set = set_input_magnitude


func is_noclipping() -> bool:
	return noclip


func is_attempting_movement() -> bool:
	return input_direction.length() > 0.0 and input_magnitude > 0.0


func is_attempting_jumping() -> bool:
	return InputManager.is_ingame_action_just_pressed("jump")


func is_grounded() -> bool:
	return get_actor_controller().is_grounded()


func get_vertical_input() -> float:
	var vertical_input: float = 0.0
	if InputManager.is_ingame_action_pressed("fly_up"):
		vertical_input += 1.0
	if InputManager.is_ingame_action_pressed("fly_down"):
		vertical_input -= 1.0

	return vertical_input


func set_input_direction(p_input_direction: Vector3) -> void:
	input_direction = p_input_direction


func set_input_magnitude(p_input_magnitude: float) -> void:
	input_magnitude = p_input_magnitude


func get_input_direction() -> Vector3:
	return input_direction


func get_input_magnitude() -> float:
	return input_magnitude


func get_actor_controller() -> Node:
	return actor_controller


func get_velocity() -> Vector3:
	return get_actor_controller().get_velocity()


func set_velocity(p_velocity: Vector3) -> void:
	get_actor_controller().set_velocity(p_velocity)


func get_euler() -> Vector3:
	return get_actor_controller().get_euler()


func set_euler(p_euler: Vector3) -> void:
	actor_controller.set_euler(p_euler)


func set_movement_vector(p_movement: Vector3) -> void:
	actor_controller.set_movement_vector(p_movement)


func get_motion_vector() -> Vector3:
	return actor_controller.motion_vector


func print_event_received(event):
	print("Event received %s" % event)


func update(p_delta: float) -> void:
	super.update(p_delta)
	state_chart.set_expression_property("noclipping", is_noclipping())
	state_chart.set_expression_property("attempting_movement", is_attempting_movement())
	state_chart.set_expression_property("attempting_jumping", is_attempting_movement())
	state_chart.set_expression_property("grounded", is_grounded())


func start() -> void:
	super.start()
	if !Engine.is_editor_hint():
		states_map = {
			"Spawned": get_node_or_null("Spawned"),
			"Idle": get_node_or_null("Idle"),
			"Locomotion": get_node_or_null("Locomotion"),
			"Falling": get_node_or_null("Falling"),
			"Stop": get_node_or_null("Stop"),
			"Landed": get_node_or_null("Landed"),
			"Pre-Jump": get_node_or_null("Pre-Jump"),
			"Networked": get_node_or_null("Networked"),
			"Noclip": get_node_or_null("Noclip")
		}

		actor_controller = get_node_or_null(actor_controller_path)
