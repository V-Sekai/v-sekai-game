# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_version.gd
# SPDX-License-Identifier: MIT

@tool
extends Node

const build_constants_const = preload("build_constants.gd")


static func get_build_label() -> String:
	return build_constants_const.BUILD_DATE_STR + "\n" + build_constants_const.BUILD_LABEL
