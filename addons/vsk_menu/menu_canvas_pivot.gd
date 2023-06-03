# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# menu_canvas_pivot.gd
# SPDX-License-Identifier: MIT

extends Node3D

@export var canvas_plane_nodepath: NodePath = NodePath()


func get_control_root() -> Control:
	var canvas_plane: Node3D = get_node_or_null(canvas_plane_nodepath)
	if canvas_plane and canvas_plane.has_method("get_control_root"):
		return canvas_plane.get_control_root()
	else:
		return null


func get_menu_viewport() -> SubViewport:
	var canvas_plane: Node3D = get_node_or_null(canvas_plane_nodepath)
	if canvas_plane:
		return canvas_plane.get_control_viewport()
	else:
		return null


func get_canvas_plane() -> Node3D:
	var canvas_plane: Node3D = get_node_or_null(canvas_plane_nodepath)
	if canvas_plane:
		return canvas_plane
	else:
		return null


const MIN_DOT: float = 0.92
const MAX_DOT: float = 0.99
const MAX_DISTANCE: float = 0.5
const MIN_DISTANCE: float = 0.1
const SPEED_MULTIPLIER: float = 2.0

var first_transform_has_occured: bool = false
var is_transforming: bool = true

var current_origin: Vector3 = Vector3()
var target_origin: Vector3 = Vector3()
var current_rotation: Quaternion = Quaternion()
var target_rotation: Quaternion = Quaternion()


func calculate_pivot(p_delta) -> void:
	var origin: XROrigin3D = get_parent()
	if origin:
		var camera: XRCamera3D = origin.get_node_or_null("ARVRCamera")
		if camera:
			var pivot_target_rotation: float = camera.transform.basis.get_euler().y
			target_rotation = Quaternion(Basis(Vector3.UP, pivot_target_rotation))
			target_origin = Vector3(camera.transform.origin.x, 0.0, camera.transform.origin.z)

			if !first_transform_has_occured:
				if current_rotation.dot(target_rotation) < 1.0 or current_origin.distance_to(target_origin) > 0.0:
					current_rotation = target_rotation
					current_origin = target_origin
					first_transform_has_occured = true
			else:
				if is_transforming:
					current_rotation = current_rotation.slerp(target_rotation, p_delta * SPEED_MULTIPLIER)
					current_origin = current_origin.lerp(target_origin, p_delta * SPEED_MULTIPLIER)
					var dot: float = current_rotation.dot(target_rotation)
					var distance: float = current_origin.distance_to(target_origin)

					if abs(dot) > MAX_DOT and distance < MIN_DISTANCE:
						is_transforming = false
				else:
					var dot: float = current_rotation.dot(target_rotation)
					var distance: float = current_origin.distance_to(target_origin)

					if abs(dot) < MIN_DOT or distance > MAX_DISTANCE:
						is_transforming = true

			transform.origin = current_origin
			transform.basis = Basis(current_rotation)
		else:
			first_transform_has_occured = false
	else:
		first_transform_has_occured = false


func _process(p_delta):
	calculate_pivot(p_delta)


func _enter_tree():
	first_transform_has_occured = false
