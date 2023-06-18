# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_menu_manager.gd
# SPDX-License-Identifier: MIT

@tool
extends Node

#const ingame_gui_const = preload("res://addons/vsk_menu/ingame_menu/ingame_gui.tscn")

#const preloading_screen_const = preload("res://addons/vsk_menu/main_menu/preloading_screen.tscn")
#const outgame_root_vr_const = preload("outgame_root_vr.tscn")
#const menu_canvas_pivot_const = preload("res://addons/vsk_menu/menu_canvas_pivot.tscn")

# FIXME: Not using preload because of
# SCRIPT ERROR: Parse Error: Could not p_preload resource file "res://addons/vsk_menu/ingame_menu/ingame_gui.tscn".
#           at: GDScript::reload (res://addons/vsk_manager/vsk_menu_manager.gd:4)
var ingame_gui_const = load("res://addons/vsk_menu/ingame_menu/ingame_gui.tscn")
var preloading_screen_const = load("res://addons/vsk_menu/main_menu/preloading_screen.tscn")
var outgame_root_vr_const = load("res://addons/vsk_manager/outgame_root_vr.tscn")
var menu_canvas_pivot_const = load("res://addons/vsk_menu/menu_canvas_pivot.tscn")

var title_screen_packed_scene: PackedScene = null
var loading_screen_packed_scene: PackedScene = null
var ingame_menu_screen_packed_scene: PackedScene = null
var ingame_gui_packed_scene: PackedScene = null

var outgame_root_vr_instance: Node = null
var menu_canvas_pivot_instance: Node = null

var console_root: Control = null

var menu_root: Control = null

var ingame_gui_root: Control = null
var flat_fader: ColorRect = null

var project_theme: Theme = null

var menu_active: bool = false
var menu_request_count: int = 0

const RESOURCE_ID_TITLE_SCREEN = 0
const RESOURCE_ID_LOADING_SCREEN = 1
const RESOURCE_ID_INGAME_MENU_SCREEN = 2
const RESOURCE_ID_INGAME_GUI = 3


func new_origin_assigned(_origin: XROrigin3D) -> void:
	setup_viewport()


func clear() -> void:
	get_menu_root().clear_view_controller_stack()

	if ingame_gui_root:
		for child in ingame_gui_root.get_children():
			child.queue_free()
			child.get_parent().remove_child(child)


func _fade_color_changed(p_color: Color) -> void:
	flat_fader.color = p_color


func set_input_blocking(p_blocking: bool) -> void:
	if menu_root:
		menu_root.set_input_blocking(p_blocking)


func menu_gui_input(p_event: InputEvent) -> void:
	if menu_canvas_pivot_instance != null and menu_canvas_pivot_instance.is_inside_tree():
		var plane: Node3D = menu_canvas_pivot_instance.get_canvas_plane()
		if p_event is InputEventMouse:
			p_event.position *= (Vector2(plane.canvas_width, plane.canvas_height) / Vector2(get_viewport().size))
			plane.viewport.push_input(p_event)


func get_menu_root() -> Control:
	if menu_root == null:
		push_error("how did menu_root become null?!")
		menu_root = NavigationController.new()
		menu_root.set_name("MenuRoot")
		menu_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	return menu_root


func get_ingame_gui_root() -> Control:
	return ingame_gui_root


func toggle_menu() -> void:
	if menu_root.is_visible():
		hide_menu()
	else:
		show_menu()


func menu_button_pressed() -> void:
	toggle_menu()


func update_vr_flat_menu_visibility():
	if outgame_root_vr_instance.is_inside_tree() and (VRManager.vr_user_preferences.vr_hmd_mirroring == VRManager.vr_user_preferences.vr_hmd_mirroring_enum.HMD_MIRROR_FLAT_UI):
		FlatViewport.texture_rect_menu.show()
	else:
		FlatViewport.texture_rect_menu.hide()


##
## Used as a callback for the VRManager's teleport component to determine whether
## Teleporting is possible. Returns true if the gameflow state is set ingame.
##
func _can_teleport() -> bool:
	return VSKGameFlowManager.gameflow_state == VSKGameFlowManager.GAMEFLOW_STATE_INGAME


##
##
##
func _update_menu_canvas() -> void:
	if menu_request_count > 0:
		menu_canvas_pivot_instance.show()
	else:
		menu_canvas_pivot_instance.hide()


##
##
##
func _console_active(p_is_active: bool) -> void:
	if p_is_active:
		menu_request_increment()
	else:
		menu_request_decrement()


func menu_request_increment() -> void:
	menu_request_count += 1
	InputManager.increment_ingame_input_block()

	_update_menu_canvas()


func menu_request_decrement() -> void:
	if menu_request_count <= 0:
		printerr("Menu request count is not greater than 0.")
		return

	menu_request_count -= 1
	InputManager.decrement_ingame_input_block()

	_update_menu_canvas()


## Called to request the main menu to disappear.
##
func hide_menu() -> void:
	menu_root.hide()

	if menu_active:
		menu_request_decrement()
		menu_active = false
		if VRManager.is_xr_active():
			Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


##
## Called to request the main menu to appear, creates it
## if it does not exist
##
func show_menu() -> void:
	menu_root.show()

	if !menu_active:
		menu_request_increment()
		menu_active = true
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _reset_viewport() -> void:
	if console_root:
		if console_root.is_inside_tree():
			console_root.get_parent().remove_child(console_root)
	if menu_root:
		if menu_root.is_inside_tree():
			menu_root.get_parent().remove_child(menu_root)
	if ingame_gui_root:
		if ingame_gui_root.is_inside_tree():
			ingame_gui_root.get_parent().remove_child(ingame_gui_root)
	if menu_canvas_pivot_instance:
		if menu_canvas_pivot_instance.is_inside_tree():
			menu_canvas_pivot_instance.get_parent().remove_child(menu_canvas_pivot_instance)
	if flat_fader:
		if flat_fader.is_inside_tree():
			flat_fader.get_parent().remove_child(flat_fader)

	FlatViewport.texture_rect_menu.texture = null

	if FlatViewport.menu_gui_input.is_connected(self.menu_gui_input):
		FlatViewport.menu_gui_input.disconnect(self.menu_gui_input)


func setup_vr_viewport() -> void:
	_reset_viewport()

	if VRManager.xr_origin:
		menu_canvas_pivot_instance = menu_canvas_pivot_const.instantiate()
		VRManager.xr_origin.add_child(menu_canvas_pivot_instance, true)

		var control_root: Control = menu_canvas_pivot_instance.get_control_root() as Control
		if control_root:
			if console_root:
				control_root.add_child(console_root, true)
			if menu_root:
				control_root.add_child(menu_root, true)

			FlatViewport.texture_rect_menu.texture = menu_canvas_pivot_instance.get_menu_viewport().get_texture()
			if FlatViewport.menu_gui_input.connect(self.menu_gui_input) != OK:
				printerr("Could could connect gui_input signal!")


func setup_flat_viewport() -> void:
	_reset_viewport()

	if console_root:
		add_child(console_root, true)

	if menu_root:
		add_child(menu_root, true)

	if ingame_gui_root:
		add_child(ingame_gui_root, true)

	if flat_fader:
		add_child(flat_fader, true)


func setup_viewport() -> void:
	if VRManager.is_xr_active():
		setup_vr_viewport()
	else:
		setup_flat_viewport()


func setup_ingame() -> void:
	if outgame_root_vr_instance:
		outgame_root_vr_instance.queue_free()
		outgame_root_vr_instance.get_parent().remove_child(outgame_root_vr_instance)
		outgame_root_vr_instance = null

	if ingame_gui_root:
		ingame_gui_root.add_child(ingame_gui_packed_scene.instantiate(), true)

	if menu_root:
		menu_root.push_view_controller(ingame_menu_screen_packed_scene.instantiate(), false)


func setup_outgame() -> void:
	if outgame_root_vr_instance == null:
		outgame_root_vr_instance = outgame_root_vr_const.instantiate()
		VSKGameFlowManager.gameroot.add_child(outgame_root_vr_instance, true)


func setup_preloading_screen() -> void:
	if menu_root:
		menu_root.push_view_controller(preloading_screen_const.instantiate() as ViewController, false)


func setup_title_screen() -> void:
	if menu_root:
		menu_root.push_view_controller(title_screen_packed_scene.instantiate() as ViewController, false)


func setup_loading_screen() -> void:
	if menu_root:
		menu_root.push_view_controller(loading_screen_packed_scene.instantiate() as ViewController, false)


func play_menu_sfx(p_stream: AudioStream) -> void:
	VSKAudioManager.play_oneshot_audio_stream(p_stream, VSKAudioManager.MENU_OUTPUT_BUS_NAME, linear_to_db(0.1))


func assign_resource(p_resource: Resource, p_resource_id: int) -> void:
	match p_resource_id:
		RESOURCE_ID_TITLE_SCREEN:
			title_screen_packed_scene = p_resource
		RESOURCE_ID_LOADING_SCREEN:
			loading_screen_packed_scene = p_resource
		RESOURCE_ID_INGAME_MENU_SCREEN:
			ingame_menu_screen_packed_scene = p_resource
		RESOURCE_ID_INGAME_GUI:
			ingame_gui_packed_scene = p_resource


func get_preload_tasks() -> Dictionary:
	var preloading_tasks: Dictionary = {}
	preloading_tasks["res://addons/vsk_menu/main_menu/title_screen.tscn"] = {"target": self, "method": "assign_resource", "args": [RESOURCE_ID_TITLE_SCREEN]}
	preloading_tasks["res://addons/vsk_menu/main_menu/loading_screen.tscn"] = {"target": self, "method": "assign_resource", "args": [RESOURCE_ID_LOADING_SCREEN]}
	preloading_tasks["res://addons/vsk_menu/main_menu/ingame_menu_screen.tscn"] = {"target": self, "method": "assign_resource", "args": [RESOURCE_ID_INGAME_MENU_SCREEN]}
	preloading_tasks["res://addons/vsk_menu/ingame_menu/ingame_gui.tscn"] = {"target": self, "method": "assign_resource", "args": [RESOURCE_ID_INGAME_GUI]}

	return preloading_tasks


func _update_console() -> void:
	pass


func setup() -> void:
	if Engine.is_editor_hint():
		return

	console_root = Control.new()
	console_root.set_name("ConsoleRoot")
	console_root.set_anchors_preset(Control.PRESET_FULL_RECT)

	menu_root = NavigationController.new()
	menu_root.set_name("MenuRoot")
	menu_root.set_anchors_preset(Control.PRESET_FULL_RECT)

	# Add console
	call_deferred("_update_console")

	ingame_gui_root = Control.new()
	ingame_gui_root.set_name("IngameGUIRoot")
	ingame_gui_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	ingame_gui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE

	menu_canvas_pivot_instance = menu_canvas_pivot_const.instantiate()

	var project_theme_path: String = ProjectSettings.get_setting("gui/theme/custom")
	if !ResourceLoader.has_cached(project_theme_path):
		project_theme = ResourceLoader.load(project_theme_path)
		menu_root.theme = project_theme

	if VRManager.xr_mode_changed.connect(self.setup_viewport) != OK:
		printerr("Failed to connect VRManager.xr_mode_changed signal.")

	# Setup the fader for the flat view
	flat_fader = ColorRect.new()
	flat_fader.set_color(Color(0.0, 0.0, 0.0, 0.0))
	flat_fader.set_name("Fader")
	flat_fader.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 0)
	flat_fader.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if FadeManager.color_changed.connect(self._fade_color_changed) != OK:
		printerr("Failed to connect FadeManager.color_changed signal.")


func _input(p_event: InputEvent):
	if !Engine.is_editor_hint():
		if p_event.is_action_pressed("ui_menu"):
			if VSKGameFlowManager.gameflow_state == VSKGameFlowManager.GAMEFLOW_STATE_INGAME:
				menu_button_pressed()

		# Propogate keyboard inputs to the menu viewport
		if VRManager.is_xr_active():
			if p_event is InputEventKey:
				if menu_root.is_inside_tree():
					menu_root.get_viewport().push_input(p_event)


func _ready():
	if Engine.is_editor_hint():
		set_process_input(false)
		return
	else:
		set_process_input(true)

	if VRManager.new_origin_assigned.connect(self.new_origin_assigned) != OK:
		printerr("Failed to connect VRManager.new_origin_assigned signal.")
