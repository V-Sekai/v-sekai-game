# res://addons/canvas_plane/canvas_utils.gd
# This file is part of the V-Sekai Game.
# https://github.com/V-Sekai/canvas_plane
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

const UI_PIXELS_TO_METER = 1.0 / 1024


static func find_child_control(p_root: Node) -> Control:
	assert(p_root)
	var control_node: Control = null
	for child in p_root.get_children():
		if child is Control:
			control_node = child
			break

	return control_node


static func get_physcially_scaled_size_from_control(p_control: Control) -> Vector2:
	return p_control.get_size() * UI_PIXELS_TO_METER
