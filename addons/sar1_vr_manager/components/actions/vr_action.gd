extends Node3D

var vr_module: Node = null

const vr_tracker_script = preload("res://addons/sar1_vr_manager/vr_controller_tracker.gd")
var tracker: XRController3D = null


func is_button_pressed(p_action: String) -> bool:
	return tracker.is_button_pressed(p_action)


func get_vector2(p_action: String) -> Vector2:
	return tracker.get_vector2(p_action)


func _on_action_pressed(_action: String) -> void:
	pass


func _on_action_released(_action: String) -> void:
	pass


func find_parent_controller() -> Node:
	var node = self
	while node.get_script() != vr_tracker_script:
		if node == null:
			break
		node = node.get_parent()
	return node


func _ready() -> void:
	tracker = find_parent_controller()
	if not tracker:
		print("vr_action TRACKER IS NULL")
		return
	print("vr_action TRACKER " + str(tracker.get_path()))
	if tracker.button_pressed.connect(self._on_action_pressed) != OK:
		printerr("action_pressed not connected!")
	if tracker.button_released.connect(self._on_action_released) != OK:
		printerr("action_released not connected!")
