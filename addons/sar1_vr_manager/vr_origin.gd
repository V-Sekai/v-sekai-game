# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vr_origin.gd
# SPDX-License-Identifier: MIT

extends XROrigin3D

const vr_manager_const = preload("res://addons/sar1_vr_manager/vr_manager.gd")
const vr_controller_tracker_const = preload("res://addons/sar1_vr_manager/vr_controller_tracker.gd")

var active_controllers: Dictionary = {}
var unknown_controller_count: int = 0

var hand_controllers: Array = []
var left_hand_controller: XRController3D = null
var right_hand_controller: XRController3D = null

const vr_component_locomotion_const = preload("components/vr_component_locomotion.gd")
const vr_component_render_tree_const = preload("components/vr_component_render_tree.gd")
const vr_component_advanced_movement_const = preload("components/vr_component_advanced_movement.gd")
const vr_component_lasso_const = preload("components/vr_component_lasso.gd")
const vr_component_hand_pose_const = preload("components/vr_component_hand_pose.gd")
const vr_component_teleport_const = preload("components/vr_component_teleport.gd")

var vr_camera: Camera3D = null
var desktop_camera: Camera3D = null
var desktop_viewport: Viewport = null

var components: Array = []

signal tracker_added(p_positional_tracker: XRPositionalTracker)
signal tracker_removed(p_positional_tracker: XRPositionalTracker)


func clear_controllers() -> void:
	for tracker_name in active_controllers.keys():
		remove_tracker(tracker_name)

	if not active_controllers.is_empty():
		printerr("Active controllers are not empty after clearing!")
		return

	if unknown_controller_count != 0:
		printerr("Unknown controller count is not zero after clearing!")
		return

	if not hand_controllers.is_empty():
		printerr("Hand controllers are not empty after clearing!")
		return

	if left_hand_controller != null or right_hand_controller != null:
		printerr("Left or right hand controller is not null after clearing!")
		return


func add_tracker(p_tracker_name: StringName) -> void:
	print("IN add_tracker " + str(p_tracker_name))
	var tracker: XRPositionalTracker = XRServer.get_tracker(p_tracker_name)
	if tracker != null && tracker.type == XRServer.TRACKER_CONTROLLER:
		var tracker_hand: int = tracker.get_tracker_hand()
		var controller: XRController3D = vr_controller_tracker_const.new()

		match tracker_hand:
			XRPositionalTracker.TRACKER_HAND_LEFT:
				controller.set_name("LeftController")
				controller.tracker = tracker.name

				# Attempt to add left controller
				if left_hand_controller == null:
					left_hand_controller = controller
					hand_controllers.push_back(controller)
			XRPositionalTracker.TRACKER_HAND_RIGHT:
				controller.set_name("RightController")
				controller.tracker = tracker.name

				# Attempt to add right controller
				if right_hand_controller == null:
					right_hand_controller = controller
					hand_controllers.push_back(controller)
			XRPositionalTracker.TRACKER_HAND_UNKNOWN:
				controller.set_name("UnknownHandController")
				controller.tracker = tracker.name
				unknown_controller_count += 1
			_:
				pass

		VRManager.platform_add_controller(controller, self)

		for component in components:
			component.tracker_added(controller)

		if !active_controllers.has(p_tracker_name):
			print("Adding tracker " + str(p_tracker_name) + " at " + str(self.get_path()) + " name " + str(controller.tracker) + " and " + str(controller.name))
			active_controllers[p_tracker_name] = controller
			add_child(controller, true)
			tracker_added.emit(controller)
		else:
			controller.free()
			printerr("Attempted to add duplicate active tracker!")


func remove_tracker(p_tracker_name: StringName) -> void:
	if active_controllers.has(p_tracker_name):
		var controller: XRController3D = active_controllers[p_tracker_name]  # vr_controller_tracker_const
		if active_controllers.erase(p_tracker_name):
			# Attempt to clear it from any hands it is assigned to
			if left_hand_controller == controller or right_hand_controller == controller:
				if left_hand_controller == controller:
					left_hand_controller = null
				if right_hand_controller == controller:
					right_hand_controller = null
				hand_controllers.remove_at(hand_controllers.find(controller))

			if XRServer.get_tracker(p_tracker_name):
				var tracker: XRPositionalTracker = XRServer.get_tracker(p_tracker_name)
				if tracker.hand == XRPositionalTracker.TRACKER_HAND_UNKNOWN:
					unknown_controller_count -= 1

				VRManager.platform_remove_controller(controller, self)

				for component in components:
					component.tracker_removed(controller)

				tracker_removed.emit(tracker)

			if controller.is_inside_tree():
				controller.queue_free()
		else:
			printerr("Attempted to erase an invalid tracker!")
	else:
		printerr("Attempted to erase an invalid active tracker!")


func _on_tracker_added(p_tracker_name: StringName, p_type: int) -> void:
	print(
		(
			"Adding controller for tracker {tracker_name} type {tracker_type_name} id {id} to VR Player"
			. format(
				{
					"tracker_name": p_tracker_name,
					"tracker_type_name": vr_manager_const.get_tracker_type_name(p_type),
				}
			)
		)
	)
	add_tracker(p_tracker_name)


func _on_tracker_removed(p_tracker_name: StringName, p_type: int) -> void:
	print("Removing hand for tracker %s type %s to VR Player" % [p_tracker_name, vr_manager_const.get_tracker_type_name(p_type)])
	remove_tracker(p_tracker_name)


func create_and_add_component(p_component_script: Script) -> void:
	var vr_component: Node3D = p_component_script.new()
	components.push_back(vr_component)
	add_child(vr_component, true)


func create_components() -> void:
	create_and_add_component(vr_component_locomotion_const)
	create_and_add_component(vr_component_render_tree_const)
	create_and_add_component(vr_component_advanced_movement_const)
	create_and_add_component(vr_component_lasso_const)
	create_and_add_component(vr_component_hand_pose_const)
	create_and_add_component(vr_component_teleport_const)


func destroy_components() -> void:
	for component in components:
		component.queue_free()

	components = []


func get_component_by_name(p_name: String) -> Node:
	for component in components:
		if p_name == component.name:
			return component

	return null


func setup_components() -> void:
	for component in components:
		component.post_add_setup()


func _ready() -> void:
	set_process_internal(false)
	clear_controllers()
	for key in VRManager.xr_trackers:
		add_tracker(key)
	if VRManager.tracker_added.connect(self._on_tracker_added) != OK:
		printerr("tracker_added could not be connected")
	if VRManager.tracker_removed.connect(self._on_tracker_removed) != OK:
		printerr("tracker_removed could not be connected")

	vr_camera = get_node("ARVRCamera")
	
	desktop_viewport = SubViewport.new()
	desktop_viewport.name = "DesktopViewport"
	add_child(desktop_viewport)
	desktop_viewport.owner = vr_camera
	VSKGameFlowManager.set_viewport(desktop_viewport)
	desktop_viewport.size = DisplayServer.window_get_size(0)
	
	desktop_camera = Camera3D.new()
	desktop_camera.name = "DesktopCamera"
	desktop_viewport.add_child(desktop_camera)
	desktop_camera.owner = vr_camera
	desktop_camera.attributes = CameraAttributesPractical.new()
	desktop_camera.environment = load("res://vsk_default/environments/default_env.tres")
	desktop_camera.global_transform = vr_camera.global_transform

func _exit_tree() -> void:
	if VRManager.xr_origin == self:
		VRManager.xr_origin = null

	destroy_components()
	clear_controllers()

	if VRManager.tracker_added.is_connected(self._on_tracker_added):
		VRManager.tracker_added.disconnect(self._on_tracker_added)
	else:
		printerr("tracker_added could not be disconnected")
	if VRManager.tracker_removed.is_connected(self._on_tracker_removed):
		VRManager.tracker_removed.disconnect(self._on_tracker_removed)
	else:
		printerr("tracker_removed could not be disconnected")


func _enter_tree() -> void:
	# Self-assign
	VRManager.assign_xr_origin(self)

	create_components()
	setup_components()

func _process(delta):
	desktop_camera.global_transform = vr_camera.global_transform
