# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# network_transform.gd
# SPDX-License-Identifier: MIT

@tool
class_name NetworkTransform extends NetworkLogic

const network_entity_manager_const = preload("res://addons/network_manager/network_entity_manager.gd")
const math_funcs_const = preload("res://addons/math_util/math_funcs.gd")

var target_origin: Vector3 = Vector3()
var target_rotation: Quaternion = Quaternion()

var current_origin: Vector3 = Vector3()
var current_rotation: Quaternion = Quaternion()

signal transform_updated(p_transform)

@export var origin_interpolation_factor: float = 0.0
@export var rotation_interpolation_factor: float = 0.0
@export var snap_threshold: float = 0.0


static func write_transform(p_writer: Object, p_transform: Transform3D) -> void:
	p_writer.put_vector3(p_transform.origin)
	p_writer.put_quat(p_transform.basis.get_rotation_quaternion())


static func read_transform(p_reader: Object) -> Transform3D:
	var origin: Vector3 = math_funcs_const.sanitise_vec3(p_reader.get_vector3())
	var rotation: Quaternion = math_funcs_const.sanitise_quat(p_reader.get_quat())

	return Transform3D(Basis(rotation), origin)


func update_transform(p_transform: Transform3D) -> void:
	transform_updated.emit(p_transform)


func on_serialize(p_writer: Object, p_initial_state: bool) -> Object:
	if p_initial_state:
		pass

	if not entity_node is Node3D:
		return

	# Transform
	var transform: Transform3D = entity_node.simulation_logic_node.get_transform()
	NetworkTransform.write_transform(p_writer, transform)

	return p_writer


func on_deserialize(p_reader: Object, p_initial_state: bool) -> Object:
	received_data = true

	# Transform
	var transform: Transform3D = NetworkTransform.read_transform(p_reader)

	var origin: Vector3 = transform.origin
	var rotation: Quaternion = transform.basis.get_rotation_quaternion()

	target_origin = origin
	target_rotation = rotation
	if p_initial_state:
		var current_transform: Transform3D = Transform3D(Basis(rotation), origin)
		current_origin = current_transform.origin
		current_rotation = current_transform.basis.get_rotation_quaternion()
		update_transform(Transform3D(current_rotation, current_origin))

	return p_reader


func interpolate_transform(p_delta: float) -> void:
	if is_inside_tree() and !is_multiplayer_authority():
		if entity_node:
			var distance: float = current_origin.distance_to(target_origin)
			if snap_threshold > 0.0 and distance < snap_threshold:
				if origin_interpolation_factor > 0.0:
					current_origin = current_origin.lerp(target_origin, origin_interpolation_factor * p_delta)
				else:
					current_origin = target_origin
				if rotation_interpolation_factor > 0.0:
					current_rotation = current_rotation.slerp(target_rotation, rotation_interpolation_factor * p_delta)
				else:
					current_rotation = target_rotation
			else:
				current_origin = target_origin
				current_rotation = target_rotation

			call_deferred("update_transform", Transform3D(Basis(current_rotation), current_origin))


func _entity_physics_process(_delta: float) -> void:
	super._entity_physics_process(_delta)
	if received_data:
		interpolate_transform(_delta)
		received_data = false


func _entity_ready() -> void:
	super._entity_ready()
	if received_data:
		if !is_multiplayer_authority():
			update_transform(Transform3D(Basis(current_rotation), current_origin))
		received_data = false


func _entity_about_to_add() -> void:
	super._entity_about_to_add()
