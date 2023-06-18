# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# network_ik_points.gd
# SPDX-License-Identifier: MIT

@tool
extends NetworkLogic

const math_funcs_const = preload("res://addons/math_util/math_funcs.gd")

const ik_space_const = preload("res://addons/vsk_avatar/ik_space.gd")
var ik_space: Node = null

var bits: int = 0
var transforms: Array = []

@export var ik_space_node_path: NodePath = NodePath()


static func write_point_transform(p_writer: Object, p_transform: Transform3D) -> Object:  # network_writer_const
	p_writer.put_vector3(p_transform.origin)
	p_writer.put_quat(p_transform.basis.get_rotation_quaternion())

	return p_writer


static func write_head_transform(p_writer: Object, p_transform: Transform3D) -> Object:  # network_writer_const
	p_writer.put_float(p_transform.origin.y)
	p_writer.put_quat(p_transform.basis.get_rotation_quaternion())

	return p_writer


static func read_point_transform(p_reader: Object) -> Dictionary:
	var origin: Vector3 = math_funcs_const.sanitise_vec3(p_reader.get_vector3())
	var rotation: Quaternion = math_funcs_const.sanitise_quat(p_reader.get_quat())

	return {"reader": p_reader, "transform": Transform3D(Basis(rotation), origin)}


static func read_head_transform(p_reader: Object) -> Dictionary:
	var origin_y: float = math_funcs_const.sanitise_float(p_reader.get_float())
	var rotation: Quaternion = math_funcs_const.sanitise_quat(p_reader.get_quat())

	return {"reader": p_reader, "transform": Transform3D(Basis(rotation), Vector3(0.0, origin_y, 0.0))}


func on_serialize(p_writer: Object, _p_initial_state: bool) -> Object:  # network_writer_const
	bits = 0

	if ik_space and ik_space.tracker_collection_output:
		if ik_space.tracker_collection_output.head_spatial:
			bits |= ik_space_const.HEAD_BIT

		if ik_space.tracker_collection_output.left_hand_spatial:
			bits |= ik_space_const.LEFT_HAND_BIT

		if ik_space.tracker_collection_output.right_hand_spatial:
			bits |= ik_space_const.RIGHT_HAND_BIT

		if ik_space.tracker_collection_output.left_foot_spatial:
			bits |= ik_space_const.LEFT_FOOT_BIT

		if ik_space.tracker_collection_output.right_foot_spatial:
			bits |= ik_space_const.RIGHT_FOOT_BIT

		if ik_space.tracker_collection_output.hips_spatial:
			bits |= ik_space_const.HIPS_BIT

		if ik_space.tracker_collection_output.chest_spatial:
			bits |= ik_space_const.CHEST_BIT

	p_writer.put_u8(bits)

	if ik_space and ik_space.tracker_collection_output:
		# Update the output trackers
		if ik_space.output_trackers_is_dirty:
			ik_space.update_output_trackers()

		# Write transforms
		if ik_space.tracker_collection_output.head_spatial:
			p_writer = write_point_transform(p_writer, ik_space.tracker_collection_output.head_spatial.transform)

		if ik_space.tracker_collection_output.left_hand_spatial:
			p_writer = write_point_transform(p_writer, ik_space.tracker_collection_output.left_hand_spatial.transform)

		if ik_space.tracker_collection_output.right_hand_spatial:
			p_writer = write_point_transform(p_writer, ik_space.tracker_collection_output.right_hand_spatial.transform)

		if ik_space.tracker_collection_output.left_foot_spatial:
			p_writer = write_point_transform(p_writer, ik_space.tracker_collection_output.left_foot_spatial.transform)

		if ik_space.tracker_collection_output.right_foot_spatial:
			p_writer = write_point_transform(p_writer, ik_space.tracker_collection_output.right_foot_spatial.transform)

		if ik_space.tracker_collection_output.hips_spatial:
			p_writer = write_point_transform(p_writer, ik_space.tracker_collection_output.hips_spatial.transform)

		if ik_space.tracker_collection_output.chest_spatial:
			p_writer = write_point_transform(p_writer, ik_space.tracker_collection_output.chest_spatial.transform)

	return p_writer


func on_deserialize(p_reader: Object, _p_initial_state: bool) -> Object:  # network_reader_const
	received_data = true

	bits = p_reader.get_u8()
	transforms = []

	if bits & ik_space_const.HEAD_BIT:
		var dictionary: Dictionary = read_point_transform(p_reader)
		p_reader = dictionary["reader"]
		transforms.push_back(dictionary.transform)

	if bits & ik_space_const.LEFT_HAND_BIT:
		var dictionary: Dictionary = read_point_transform(p_reader)
		p_reader = dictionary["reader"]
		transforms.push_back(dictionary.transform)

	if bits & ik_space_const.RIGHT_HAND_BIT:
		var dictionary: Dictionary = read_point_transform(p_reader)
		p_reader = dictionary["reader"]
		transforms.push_back(dictionary.transform)

	if bits & ik_space_const.LEFT_FOOT_BIT:
		var dictionary: Dictionary = read_point_transform(p_reader)
		p_reader = dictionary["reader"]
		transforms.push_back(dictionary.transform)

	if bits & ik_space_const.RIGHT_FOOT_BIT:
		var dictionary: Dictionary = read_point_transform(p_reader)
		p_reader = dictionary["reader"]
		transforms.push_back(dictionary.transform)

	if bits & ik_space_const.HIPS_BIT:
		var dictionary: Dictionary = read_point_transform(p_reader)
		p_reader = dictionary["reader"]
		transforms.push_back(dictionary.transform)

	if bits & ik_space_const.CHEST_BIT:
		var dictionary: Dictionary = read_point_transform(p_reader)
		p_reader = dictionary["reader"]
		transforms.push_back(dictionary.transform)

	if ik_space:
		ik_space.update_external_transform(bits, transforms)

	return p_reader


func _entity_ready() -> void:
	super._entity_ready()
	if !Engine.is_editor_hint():
		ik_space = get_node_or_null(ik_space_node_path)
		if received_data:
			ik_space.update_external_transform(bits, transforms)
