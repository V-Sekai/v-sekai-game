extends XRController3D

const vr_constants_const = preload("res://addons/sar1_vr_manager/vr_constants.gd")
const vr_render_tree_const = preload("vr_render_tree.gd")
var component_action: Array = []
var laser_origin: Node3D
var model_origin: Node3D
var world_scale: float = 1.0
var get_is_action_pressed_funcref: Callable = Callable()
var get_analog_funcref: Callable = Callable()

signal action_pressed(p_action)
signal action_released(p_action)


func get_hand_id_for_tracker() -> int:
	match get_tracker_hand():
		XRPositionalTracker.TrackerHand.TRACKER_HAND_LEFT:
			return vr_constants_const.LEFT_HAND
		XRPositionalTracker.TrackerHand.TRACKER_HAND_RIGHT:
			return vr_constants_const.RIGHT_HAND
		_:
			return vr_constants_const.UNKNOWN_HAND


func _on_action_pressed(p_action: String) -> void:
	print("Action was pressed! " + str(p_action))
	match p_action:
		"/menu/menu_toggle", "by_button":
			var a: InputEventAction = InputEventAction.new()
			a.action = "ui_menu"
			a.pressed = true
			Input.parse_input_event(a)
	action_pressed.emit(p_action)


func _on_action_released(p_action: String) -> void:
	match p_action:
		"/menu/menu_toggle", "by_button":
			var a: InputEventAction = InputEventAction.new()
			a.action = "ui_menu"
			a.pressed = false
			Input.parse_input_event(a)

	action_released.emit(p_action)


func add_component_action(p_component_action: Node) -> void:
	if not p_component_action:
		return

	if component_action.has(p_component_action):
		printerr("Attempted to add a duplicate module tracker!")
		return

	component_action.push_back(p_component_action)
	add_child(p_component_action, true)


func remove_component_action(p_component_action: Node) -> void:
	if not p_component_action:
		return

	var index: int = component_action.find(p_component_action)
	if index != -1:
		component_action.remove_at(index)
	else:
		printerr("Attempted to remove an invalid module tracker!")

	p_component_action.queue_free()
	remove_child(p_component_action)


func _process(_delta: float) -> void:
	if !get_is_active():
		visible = false
