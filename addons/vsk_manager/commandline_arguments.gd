# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# commandline_arguments.gd
# SPDX-License-Identifier: MIT

const VALID_LAUNCH_ARGUMENTS: Dictionary = {
	"docs": 0,
	"map": 1,
	"server_name": 1,
	"port": 1,
	"ip": 1,
	"dedicated": 0,
	"public": 0,
	"max_players": 1,
	"max_retries": 1,
	"use_flat": 0,
	"use_vr": 0,
	"test_audio": 1,
	"autoquit": 0,
	"simulate_network_conditions": 0,
	"min_latency": 1,
	"max_latency": 1,
	"drop_rate": 1,
	"dup_rate": 1,
}

const ARGUMENT_PREFIX = "--"


static func parse_commandline_arguments(p_cmdline_args: PackedStringArray) -> Dictionary:
	var launch_arguments: Dictionary = {}
	var current_subargument_count: int = 0
	var current_subargument_index: int = 0
	var stripped_argument: String = ""

	for cmd in p_cmdline_args:
		if current_subargument_count > 0 and current_subargument_index < current_subargument_count:
			launch_arguments[stripped_argument][current_subargument_index] = cmd
			current_subargument_index += 1
			continue

		if not cmd.begins_with(ARGUMENT_PREFIX):
			continue

		stripped_argument = cmd.lstrip(ARGUMENT_PREFIX)
		if not VALID_LAUNCH_ARGUMENTS.has(stripped_argument):
			continue

		current_subargument_count = VALID_LAUNCH_ARGUMENTS[stripped_argument]
		current_subargument_index = 0
		launch_arguments[stripped_argument] = []
		for _i in range(0, current_subargument_count):
			launch_arguments[stripped_argument].push_back("")

	return launch_arguments
