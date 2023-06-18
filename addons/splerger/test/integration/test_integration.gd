# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# test_integration.gd
# SPDX-License-Identifier: MIT

extends GutTest


func test_assert_eq_integration_string_equal():
	assert_eq("Integration", "Integration", "Should pass")
