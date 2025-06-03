extends RigidBody3D

const vr_constants_const = preload("res://addons/sar1_vr_manager/vr_constants.gd")

var owner_entity: Node3D = null

signal touched_by_body_with_network_id(p_network_id)
signal touched_by_body(p_body)


func send_touched_by_body_with_network_id(p_network_id: int) -> void:
	touched_by_body_with_network_id.emit(p_network_id)


func send_touched_by_body(p_body) -> void:
	touched_by_body.emit(p_body)


func get_entity_ref() -> RefCounted:
	return owner_entity.get_entity_ref()


func is_pickup_valid(_pickup_controller: Node, _hand_id: int) -> bool:
	return false


func is_drop_valid(_pickup_controller: Node, _hand_id: int) -> bool:
	return false


func pick_up(_pickup_controller: Node, _hand_id: int) -> void:
	return


func drop(_pickup_controller: Node, _hand_id: int) -> void:
	return
