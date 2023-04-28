# res://addons/canvas_plane/function_pointer_receiver.gd
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

extends Area3D

const math_funcs_const = preload("res://addons/math_util/math_funcs.gd")

signal pointer_pressed(p_at)
signal pointer_moved(p_at, p_from)
signal pointer_release(p_at)


func untransform_position(p_vector: Vector3) -> Vector3:
	return (p_vector) * (global_transform)


func untransform_normal(p_normal: Vector3) -> Vector3:
	var current_basis: Basis = global_transform.basis.orthonormalized()
	return math_funcs_const.transform_directon_vector(p_normal, current_basis.inverse())


func validate_pointer(p_normal: Vector3) -> bool:
	var transform_normal: Vector3 = untransform_normal(p_normal)
	if transform_normal.z > 0.0:
		return true
	else:
		return false


func on_pointer_pressed(p_position: Vector3, p_doubleclick: bool) -> void:
	pointer_pressed.emit(untransform_position(p_position), p_doubleclick)


func on_pointer_moved(p_position: Vector3, p_normal: Vector3) -> void:
	if validate_pointer(p_normal):
		pointer_moved.emit(p_position)


func on_pointer_release(p_position: Vector3) -> void:
	pointer_release.emit(untransform_position(p_position))
