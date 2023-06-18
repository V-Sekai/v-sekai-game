# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# data_storage_units.gd
# SPDX-License-Identifier: MIT

@tool
extends RefCounted

const DATA_UNIT_SIZE_EXPONENTIAL = 1000
const DATA_UNIT_DECIMAL_MAX_SIZE = 100

enum unit_types {
	BYTES = 0,
	KILOBYTES = 1,
	MEGABYTES = 2,
	GIGABYTES = 3,
	TERABYTES = 4,
}

const unit_type_string_table: Dictionary = {
	unit_types.BYTES: "B",
	unit_types.KILOBYTES: "KB",
	unit_types.MEGABYTES: "MB",
	unit_types.GIGABYTES: "GB",
	unit_types.TERABYTES: "TB",
}

const unit_exponential_table: Array = [
	int(pow(DATA_UNIT_SIZE_EXPONENTIAL, unit_types.BYTES)),
	int(pow(DATA_UNIT_SIZE_EXPONENTIAL, unit_types.KILOBYTES)),
	int(pow(DATA_UNIT_SIZE_EXPONENTIAL, unit_types.MEGABYTES)),
	int(pow(DATA_UNIT_SIZE_EXPONENTIAL, unit_types.GIGABYTES)),
	int(pow(DATA_UNIT_SIZE_EXPONENTIAL, unit_types.TERABYTES)),
]

enum rates {
	KBS,
	MBS,
	KBPS,
	MBPS,
	GBPS,
}


static func create_unit_data_block() -> Dictionary:
	return {
		unit_types.BYTES: 0,
		unit_types.KILOBYTES: 0,
		unit_types.MEGABYTES: 0,
		unit_types.GIGABYTES: 0,
		unit_types.TERABYTES: 0,
	}


static func convert_bytes_to_data_unit_block(p_bytes: int) -> Dictionary:
	var data_unit_block: Dictionary = create_unit_data_block()

	if p_bytes >= 0:
		var remaining_bytes: int = p_bytes

		for i in range(int(unit_types.TERABYTES), int(unit_types.BYTES), -1):
			var amount: int = unit_exponential_table[i]
			while remaining_bytes >= amount:
				remaining_bytes -= amount
				data_unit_block[i] += 1

	return data_unit_block


static func get_largest_unit_type(p_data_unit_block: Dictionary) -> int:
	for i in range(int(unit_types.TERABYTES), int(unit_types.KILOBYTES), -1):
		if p_data_unit_block[i] > 0:
			return i

	return unit_types.BYTES


static func get_string_for_unit_data_block(p_data_unit_block: Dictionary, p_largest_unit: int) -> String:
	if p_largest_unit != int(unit_types.BYTES):
		return "%s.%s" % [str(p_data_unit_block[p_largest_unit]), str(p_data_unit_block[p_largest_unit - 1] / (DATA_UNIT_SIZE_EXPONENTIAL / DATA_UNIT_DECIMAL_MAX_SIZE))]

	return str(p_data_unit_block[unit_types.BYTES])


static func get_string_for_unit_type(p_unit_type: int) -> String:
	if unit_type_string_table.has(p_unit_type):
		return unit_type_string_table[p_unit_type]
	return "?"
