# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vr_interaction_action.gd
# SPDX-License-Identifier: MIT

extends "res://addons/sar1_vr_manager/components/actions/vr_action.gd"  # vr_action.gd

const vr_interaction_action_const = preload(
	"res://addons/sar1_vr_manager/components/actions/salvage/vr_interaction_action.gd"
)
const math_funcs_const = preload("res://addons/math_util/math_funcs.gd")

var objects_within_range: Array = []

var assign_pickup_callable: Callable = Callable()
var can_pickup_callable: Callable = Callable()

var last_position: Vector3 = Vector3(0.0, 0.0, 0.0)
var velocity: Vector3 = Vector3(0.0, 0.0, 0.0)

var _VSKNetworkManager: Node


static func get_hand_object_id_for_tracker_controller(p_player_pickup_controller: Node, p_tracker_controller: XRController3D):
	if p_player_pickup_controller:
		match p_tracker_controller.get_tracker_hand():
			XRPositionalTracker.TRACKER_HAND_LEFT:
				return p_player_pickup_controller.LEFT_HAND_ID
			XRPositionalTracker.TRACKER_HAND_RIGHT:
				return p_player_pickup_controller.RIGHT_HAND_ID
			_:
				return -1


func get_pickup_controller() -> Node:
	if _VSKNetworkManager and _VSKNetworkManager.local_player_instance:
		return _VSKNetworkManager.local_player_instance.simulation_logic_node.get_player_pickup_controller()
	else:
		return null


func get_hand_object() -> Node3D:
	var pickup_controller: Node = get_pickup_controller()
	if pickup_controller:
		var id: int = vr_interaction_action_const.get_hand_object_id_for_tracker_controller(pickup_controller, tracker)
		return pickup_controller.get_hand_entity_reference(id)
	return null


func _on_interaction_body_entered(p_body: Node):
	if p_body.has_method("pick_up"):
		var index: int = objects_within_range.find(p_body)
		if index == -1:
			objects_within_range.push_back(p_body)
		else:
			printerr("Duplicate object {body_name}".format({"body_name": p_body.name}))


func _on_interaction_body_exited(p_body: Node):
	var index: int = objects_within_range.find(p_body)
	if index != -1:
		objects_within_range.remove_at(index)


func get_nearest_valid_object() -> Node3D:
	return null


func try_to_pick_up_object() -> void:
	pass


func try_to_drop_object() -> void:
	pass


func _on_action_pressed(p_action: String) -> void:
	super._on_action_pressed(p_action)
	print("interaction %s" % p_action)
	match p_action:
		"/hands/grip", "grip_click", "/hands/trigger", "trigger_click":
			try_to_pick_up_object()


func _on_action_released(p_action: String) -> void:
	super._on_action_released(p_action)
	print("interaction %s" % p_action)
	match p_action:
		"/hands/grip", "grip_click", "/hands/trigger", "trigger_click":
			try_to_pick_up_object()


func calculate_velocity(p_delta: float) -> void:
	velocity = (tracker.transform.origin - last_position) / p_delta
	last_position = tracker.transform.origin


func _process(p_delta: float) -> void:
	calculate_velocity(p_delta)


func _ready() -> void:
	super._ready()
	_VSKNetworkManager = $"/root/VSKNetworkManager"
