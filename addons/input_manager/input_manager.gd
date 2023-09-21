# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# input_manager.gd
# SPDX-License-Identifier: MIT

@tool
extends Node

const input_manager_const = preload("res://addons/input_manager/input_manager.gd")
const USER_PREFERENCES_SECTION_NAME = "input"

var set_settings_value_callback: Callable = Callable()
var get_settings_value_callback: Callable = Callable()
var save_settings_callback: Callable = Callable()

const DS4_Name: String = "Sony DualShock 4"
const DS4_GUID: String = "4c05cc09000000000000504944564944"

enum { TYPE_XINPUT, TYPE_DS4, TYPE_UNKNOWN }
var connected_joypads: Dictionary = {}

var input_meta_callback: Array = []
var input_meta_actions: Dictionary = {}

var look_x_direction: float = 1.0
var look_y_direction: float = 1.0

const mouse_sensitivity_multiple: float = 1.0


func set_invert_look_x(p_invert_look_x: bool) -> void:
	invert_look_x = p_invert_look_x
	if p_invert_look_x:
		look_x_direction = -1.0
		return
	look_x_direction = 1.0


func set_invert_look_y(p_invert_look_y: bool) -> void:
	invert_look_y = p_invert_look_y
	if p_invert_look_y:
		look_y_direction = 1.0
		return
	look_y_direction = -1.0


var invert_look_x: bool = false:
	set = set_invert_look_x

var invert_look_y: bool = false:
	set = set_invert_look_y

var mouse_sensitivity: float = 5.0

# The number of external requests for the blocking ingame action,
# allows multiple systems to do so without conflict
var ingame_input_blocks: int = 0

# May want to make this configurable!
const INPUT_UPDATE_RATE = 1.0 / 60
var input_update_delta: float = 0.0


static func get_joy_type_from_guid(p_guid: String):
	if p_guid == DS4_GUID:
		return TYPE_DS4
	return TYPE_XINPUT


class JoyPadInfo:
	const TYPE_UNKNOWN = 2
	var type: int = TYPE_UNKNOWN

	func _init(p_type: int):
		type = p_type


var axes_values: Dictionary = {}
var axes: Array = []


class InputAxis:
	enum { TYPE_ACTION, TYPE_MOUSE_MOTION }

	var name: String = ""
	var positive_action: String = ""
	var negative_action: String = ""
	var gravity: float = 0.0
	var dead_zone: float = 0.0
	var sensitivity: float = 1.0
	var inverted: bool = false
	var type: int = TYPE_ACTION
	var axis: int = 0

	func _init(p_name: String, p_positive_action: String = "", p_negative_action: String = "", p_gravity: float = 0.0, p_dead_zone: float = 0.0, p_sensitivity: float = 1.0, p_inverted: bool = false, p_type: int = TYPE_ACTION, p_axis: int = 0):
		name = p_name
		positive_action = p_positive_action
		negative_action = p_negative_action
		gravity = p_gravity
		dead_zone = p_dead_zone
		sensitivity = p_sensitivity
		inverted = p_inverted
		type = p_type
		axis = p_axis


func update_all_axes() -> void:
	for current_axis in axes:
		if current_axis.type == InputAxis.TYPE_ACTION:
			var out_axis: float = 0.0

			if InputMap.has_action(current_axis.positive_action):
				out_axis += Input.get_action_strength(current_axis.positive_action)
			if InputMap.has_action(current_axis.negative_action):
				out_axis -= Input.get_action_strength(current_axis.negative_action)

			out_axis = clamp(out_axis, -1.0, 1.0)
			axes_values[current_axis.name] = out_axis


func clear_all_axes() -> void:
	for current_axis in axes:
		if current_axis.type == InputAxis.TYPE_MOUSE_MOTION:
			axes_values[current_axis.name] = 0.0


func _input(p_event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if p_event is InputEventJoypadMotion:
		p_event.set_device(-1)
	if p_event is InputEventMouseMotion:
		for current_axis in axes:
			if current_axis.type == InputAxis.TYPE_MOUSE_MOTION and (current_axis.axis == 0 or current_axis.axis == 1):
				if current_axis.axis == 0:
					axes_values[current_axis.name] = (p_event.relative.x * current_axis.sensitivity * mouse_sensitivity * mouse_sensitivity_multiple)
				if current_axis.axis == 1:
					axes_values[current_axis.name] = (p_event.relative.y * current_axis.sensitivity * mouse_sensitivity * mouse_sensitivity_multiple)


func _process(p_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	input_update_delta += p_delta
	if input_update_delta <= INPUT_UPDATE_RATE:
		return
	update_all_axes()
	call_deferred("clear_all_axes")

	while input_update_delta > INPUT_UPDATE_RATE:
		input_update_delta -= INPUT_UPDATE_RATE


func _joy_connection_changed(p_index: int, p_connected: bool) -> void:
	if Engine.is_editor_hint():
		return
	var connection_status: String = ""
	if p_connected:
		call_deferred("add_actions_for_input_device", p_index)

		connected_joypads[p_index] = JoyPadInfo.new(input_manager_const.get_joy_type_from_guid(Input.get_joy_guid(p_index)))
		connection_status = "connected"
	else:
		call_deferred("remove_actions_for_input_device", p_index)
		if connected_joypads.has(p_index):
			if !connected_joypads.erase(p_index):
				printerr("Could not erased: {index}".format({"index": str(p_index)}))
			connection_status = "disconnected"
		else:
			printerr("Could not erase joypad index: {index}".format({"index": str(p_index)}))
			connection_status = "invalid disconnect"

	print("Connection changed: {index} - {connection_status}".format({"index": str(p_index), "connection_status": connection_status}))


func _enter_tree() -> void:
	if Engine.is_editor_hint():
		return
	var connect_result: int = Input.joy_connection_changed.connect(self._joy_connection_changed, CONNECT_DEFERRED)
	if connect_result != OK:
		printerr("joy_connection_changed: could not connect!")


func _exit_tree() -> void:
	if Engine.is_editor_hint():
		return
	if Input.joy_connection_changed.is_connected(self._joy_connection_changed):
		Input.joy_connection_changed.disconnect(self._joy_connection_changed)


func add_new_axes(p_name: String, p_positive_action: String = "", p_negative_action: String = "", p_gravity: float = 0.0, p_dead_zone: float = 0.0, p_sensitivity: float = 1.0, p_inverted: bool = false, p_type: int = InputAxis.TYPE_ACTION, p_axis: int = 0):
	axes.append(InputAxis.new(p_name, p_positive_action, p_negative_action, p_gravity, p_dead_zone, p_sensitivity, p_inverted, p_type, p_axis))
	axes_values[p_name] = 0.0


func set_active(p_active: bool) -> void:
	if Engine.is_editor_hint():
		return
	set_process(p_active)
	set_process_input(p_active)


func decrement_ingame_input_block() -> void:
	if ingame_input_blocks <= 0:
		return

	ingame_input_blocks -= 1
	if ingame_input_blocks == 0:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func increment_ingame_input_block() -> void:
	if ingame_input_blocks == 0:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	ingame_input_blocks += 1


func ingame_input_enabled() -> bool:
	if ingame_input_blocks > 0:
		return false
	return true


func is_ingame_action_pressed(p_action: String) -> bool:
	if ingame_input_enabled():
		return Input.is_action_pressed(p_action)
	return false


func is_ingame_action_just_pressed(p_action: String) -> bool:
	if ingame_input_enabled():
		return Input.is_action_just_pressed(p_action)
	return false


func is_ingame_action_just_released(p_action: String) -> bool:
	if ingame_input_enabled():
		return Input.is_action_just_released(p_action)
	return false


func add_actions_for_input_device(p_device_id: int) -> void:
	for callback in input_meta_callback:
		var result = callback.call(p_device_id)
		if typeof(result) == TYPE_BOOL:
			if !result:
				return

	for action in input_meta_actions.keys():
		for input_meta_event in input_meta_actions[action]:
			var current_event: InputEvent = null

			if input_meta_event is InputEventJoypadButton or input_meta_event is InputEventJoypadMotion:
				current_event = input_meta_event.duplicate()

			if current_event:
				current_event.device = p_device_id
				InputMap.action_add_event(action, current_event)


func remove_actions_for_input_device(p_device_id: int) -> void:
	for callback in input_meta_callback:
		var result = callback.call(p_device_id)
		if typeof(result) == TYPE_BOOL:
			if !result:
				return

	for action in InputMap.get_actions():
		if input_meta_actions.has(action):
			var event_list: Array = InputMap.action_get_events(action)
			for input_event in event_list:
				var should_erase: bool = false
				if input_event is InputEventJoypadButton:
					if input_event.device == p_device_id:
						for input_meta_event in input_meta_actions[action]:
							if input_event.button_index == input_meta_event.button_index:
								should_erase = true
				elif input_event is InputEventJoypadMotion:
					if input_event.device == p_device_id:
						for input_meta_event in input_meta_actions[action]:
							if input_event.axis == input_meta_event.axis:
								should_erase = true

				if should_erase:
					InputMap.action_erase_event(action, input_event)


func assign_input_map_validation_callback(p_node, p_function_name):
	var func_ref: Callable = Callable(p_node, p_function_name)
	if not func_ref.is_valid():
		return
	input_meta_callback.push_back(func_ref)


func setup_meta_action_input_map() -> void:
	for action in InputMap.get_actions():
		var event_list: Array = InputMap.action_get_events(action)
		input_meta_actions[action] = []
		for input_event in event_list:
			if input_event is InputEventJoypadButton or input_event is InputEventJoypadMotion:
				# TODO: currently only supports actions inputs defined as ALL
				if input_event.device == -1:
					input_meta_actions[action].push_back(input_event)
				InputMap.action_erase_event(action, input_event)


func set_settings_value(p_key: String, p_value) -> void:
	if set_settings_value_callback.is_valid():
		set_settings_value_callback.call(USER_PREFERENCES_SECTION_NAME, p_key, p_value)


func set_settings_values():
	set_settings_value("invert_look_x", invert_look_x)
	set_settings_value("invert_look_y", invert_look_y)
	set_settings_value("mouse_sensitivity", mouse_sensitivity)


func get_settings_value(p_key: String, p_type: int, p_default):
	if get_settings_value_callback.is_valid():
		return get_settings_value_callback.call(USER_PREFERENCES_SECTION_NAME, p_key, p_type, p_default)
	return p_default


func get_settings_values() -> void:
	invert_look_x = get_settings_value("invert_look_x", TYPE_BOOL, invert_look_x)
	invert_look_y = get_settings_value("invert_look_y", TYPE_BOOL, invert_look_y)
	mouse_sensitivity = get_settings_value("mouse_sensitivity", TYPE_FLOAT, mouse_sensitivity)


func is_quitting() -> void:
	set_settings_values()


func assign_set_settings_value_funcref(p_instance: Object, p_function: String) -> void:
	set_settings_value_callback = Callable(p_instance, p_function)


func assign_get_settings_value_funcref(p_instance: Object, p_function: String) -> void:
	get_settings_value_callback = Callable(p_instance, p_function)


func assign_save_settings_funcref(p_instance: Object, p_function: String) -> void:
	save_settings_callback = Callable(p_instance, p_function)


func _ready() -> void:
	if Engine.is_editor_hint():
		set_process(false)
		set_physics_process(false)
		return
	setup_meta_action_input_map()

	set_active(true)

	set_invert_look_x(invert_look_x)
	set_invert_look_y(invert_look_y)

	if Input.get_connected_joypads().size() == 0:
		pass  # No joypads connected
	else:
		for joypad in Input.get_connected_joypads():
			var guid: String = Input.get_joy_guid(joypad)
			connected_joypads[joypad] = JoyPadInfo.new(input_manager_const.get_joy_type_from_guid(guid))
			add_actions_for_input_device(joypad)
