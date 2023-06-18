# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# network_model.gd
# SPDX-License-Identifier: MIT

@tool
extends NetworkLogic


func on_serialize(p_writer: Object, p_initial_state: bool) -> Object:  # network_writer_const
	if p_initial_state:
		var path: String = entity_node.simulation_logic_node.get_model_path()
		p_writer.put_8bit_pascal_string(path, true)

	return p_writer


func on_deserialize(p_reader: Object, p_initial_state: bool) -> Object:  # network_reader_const
	received_data = true

	if p_initial_state:
		var path: String = p_reader.get_8bit_pascal_string(true)
		entity_node.simulation_logic_node.set_model_from_path(path)

	return p_reader


func _entity_ready() -> void:
	super._entity_ready()
	if !Engine.is_editor_hint():
		if received_data:
			pass
