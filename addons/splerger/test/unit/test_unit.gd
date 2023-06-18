# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# test_unit.gd
# SPDX-License-Identifier: MIT

extends GutTest


func test_assert_eq_test_string_equal():
	assert_eq("Test", "Test", "Should pass")
