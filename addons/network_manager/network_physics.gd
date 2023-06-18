# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# network_physics.gd
# SPDX-License-Identifier: MIT

@tool
class_name NetworkPhysics extends NetworkLogic

const math_funcs_const = preload("res://addons/math_util/math_funcs.gd")
const network_entity_manager_const = preload("res://addons/network_manager/network_entity_manager.gd")


func on_serialize(p_writer: Object, p_initial_state: bool) -> Object:  # network_writer_const:
	var physics_node_root: RigidBody3D = entity_node.simulation_logic_node.get_physics_node()

	if p_initial_state:
		p_writer.put_float(physics_node_root.get_mass())

	var sleeping: bool = physics_node_root.sleeping or physics_node_root.freeze
	p_writer.put_8(sleeping)
	if !sleeping:
		var linear_velocity: Vector3 = physics_node_root.linear_velocity
		var angular_velocity: Vector3 = physics_node_root.angular_velocity
		p_writer.put_vector3(linear_velocity)
		p_writer.put_vector3(angular_velocity)

	return p_writer


func on_deserialize(p_reader: Object, p_initial_state: bool) -> Object:  # network_reader_const:
	received_data = true

	var physics_node_root: RigidBody3D = entity_node.simulation_logic_node.get_physics_node()

	if p_initial_state:
		physics_node_root.set_mass(p_reader.get_float())

	var sleeping: bool = p_reader.get_8()
	physics_node_root.sleeping = sleeping

	var linear_velocity: Vector3 = Vector3()
	var angular_velocity: Vector3 = Vector3()
	if !sleeping:
		linear_velocity = math_funcs_const.sanitise_vec3(p_reader.get_vector3())
		angular_velocity = math_funcs_const.sanitise_vec3(p_reader.get_vector3())

	physics_node_root.linear_velocity = linear_velocity
	physics_node_root.angular_velocity = angular_velocity

	return p_reader


func _entity_ready() -> void:
	super._entity_ready()
	if !Engine.is_editor_hint():
		if received_data:
			pass
