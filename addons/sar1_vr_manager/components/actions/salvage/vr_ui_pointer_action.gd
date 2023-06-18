# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vr_ui_pointer_action.gd
# SPDX-License-Identifier: MIT

extends "res://addons/sar1_vr_manager/components/actions/vr_action.gd"  # vr_action.gd

const LASER_THICKNESS = 0.001
const LASER_HIT_SIZE = 0.01

const UI_COLLISION_LAYER = 0x02

const line_renderer_const = preload("res://addons/line_renderer/line_renderer.gd")
var is_active_selector: bool = false
var valid_ray_result: Dictionary = {}

@export var maxiumum_ray_length: float = 10.0

var laser_node: Node3D = null
var laser_hit_node: MeshInstance3D = null

# Simulate doubleclicks so we can use file browsers in VR
const DOUBLECLICK_TIME = 1000  # 1 second
var last_click_time: int = -DOUBLECLICK_TIME
var is_doubleclick: bool = false

signal requested_as_ui_selector(p_hand)


func _on_action_pressed(p_action: String) -> void:
	super._on_action_pressed(p_action)
	match p_action:
		"/menu/menu_interaction", "trigger_click":
			var current_msec: int = Time.get_ticks_msec()
			if !is_doubleclick:
				if current_msec < last_click_time + DOUBLECLICK_TIME:
					is_doubleclick = true
			else:
				is_doubleclick = false

			requested_as_ui_selector.emit(tracker.get_tracker_hand())
			if not valid_ray_result.is_empty() and is_active_selector:
				if valid_ray_result["collider"].has_method("on_pointer_pressed"):
					valid_ray_result["collider"].on_pointer_pressed(valid_ray_result["position"], is_doubleclick)

			last_click_time = Time.get_ticks_msec()


func _on_action_released(p_action: String) -> void:
	super._on_action_released(p_action)
	match p_action:
		"/menu/menu_interaction", "trigger_click":
			if not valid_ray_result.is_empty() and is_active_selector:
				if valid_ray_result["collider"].has_method("on_pointer_release"):
					valid_ray_result["collider"].on_pointer_release(valid_ray_result["position"])


func activate_ui_selector() -> void:
	is_active_selector = true


func deactivate_ui_selector() -> void:
	is_active_selector = false


func create_nodes() -> void:
	laser_node = line_renderer_const.new()
	laser_node.name = "Laser"
	laser_node.material = VRManager.get_laser_material()
	laser_node.thickness = LASER_THICKNESS
	laser_node.start = Vector3(0.0, 0.0, 0.0)
	laser_node.end = Vector3(0.0, 0.0, -1.0) * maxiumum_ray_length

	var laser_hit_mesh: SphereMesh = SphereMesh.new()
	laser_hit_mesh.radius *= LASER_HIT_SIZE
	laser_hit_mesh.height *= LASER_HIT_SIZE
	var tmpmaterial: Variant = VRManager.get_laser_material()
	laser_hit_mesh.material = tmpmaterial  # workaround gd bug

	laser_hit_node = MeshInstance3D.new()
	laser_hit_node.name = "LaserHit"
	laser_hit_node.mesh = laser_hit_mesh


func _ready() -> void:
	super._ready()
	create_nodes()
	if not tracker:
		return

	if not tracker.laser_origin:
		return
	tracker.laser_origin.add_child(laser_node, true)
	tracker.laser_origin.add_child(laser_hit_node, true)

	laser_node.hide()
	laser_hit_node.hide()


func _exit_tree() -> void:
	#take the laser with it
	if laser_node:
		laser_node.queue_free()
	if laser_hit_node:
		laser_hit_node.queue_free()


func cast_validation_ray(p_length: float) -> Dictionary:
	if not is_inside_tree():
		return {}

	var dss: PhysicsDirectSpaceState3D = PhysicsServer3D.space_get_direct_state(get_world_3d().get_space())
	if !dss:
		return {}

	if not laser_node.is_inside_tree():
		return {}

	var start: Vector3 = laser_node.global_transform.origin
	var end: Vector3 = (
		laser_node.global_transform.origin + laser_node.global_transform.basis * (Vector3(0.0, 0.0, -p_length))
	)
	var parameters: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.new()
	parameters.from = start
	parameters.to = end
	parameters.collision_mask = UI_COLLISION_LAYER
	parameters.collide_with_bodies = false
	parameters.collide_with_areas = true
	var ray_result: Dictionary = dss.intersect_ray(parameters)

	laser_hit_node.global_transform = Transform3D(global_transform.basis, end)

	if ray_result:
		if ray_result["collider"].has_method("validate_pointer"):
			if ray_result["collider"].validate_pointer(ray_result["normal"]):
				laser_node.start = start
				laser_node.end = ray_result["position"]

				laser_hit_node.global_transform = Transform3D(global_transform.basis, ray_result["position"])

				return ray_result

	return {}


func update_ray() -> void:
	if is_active_selector and VRManager.xr_active:
		valid_ray_result = cast_validation_ray(maxiumum_ray_length)
		if !valid_ray_result.is_empty() and is_active_selector:
			if valid_ray_result["collider"].has_method("on_pointer_moved"):
				valid_ray_result["collider"].on_pointer_moved(valid_ray_result["position"], valid_ray_result["normal"])
			laser_node.show()
			laser_hit_node.show()
			return

	laser_node.hide()
	laser_hit_node.hide()


func _physics_process(_delta: float) -> void:
	update_ray()
