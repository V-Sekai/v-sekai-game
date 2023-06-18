# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vr_component_locomotion.gd
# SPDX-License-Identifier: MIT

extends "res://addons/sar1_vr_manager/components/vr_component.gd"  # vr_component.gd

var movement_controller: XRController3D = null
var turning_controller: XRController3D = null


func _get_movement_controller() -> XRController3D:
	if hand_controllers.size() >= 2 and left_hand_controller:
		return left_hand_controller
	elif hand_controllers.size() == 1:
		return hand_controllers[0]
	else:
		return null


func _get_turning_controller() -> XRController3D:
	if hand_controllers.size() >= 2 and right_hand_controller:
		return right_hand_controller
	elif hand_controllers.size() == 1:
		return hand_controllers[0]
	else:
		return null


func turning_action_pressed(p_action: String) -> void:
	match p_action:
		"/locomotion/snap_left":
			Input.action_press("snap_left")
		"/locomotion/snap_right":
			Input.action_press("snap_right")


func turning_action_released(p_action: String) -> void:
	match p_action:
		"/locomotion/snap_left":
			Input.action_release("snap_left")
		"/locomotion/snap_right":
			Input.action_release("snap_right")


func movement_action_pressed(_action: String) -> void:
	return


func movement_action_released(_action: String) -> void:
	return


func _refresh_controllers() -> void:
	if movement_controller and is_instance_valid(movement_controller):
		if movement_controller.action_pressed.is_connected(self.movement_action_pressed):
			movement_controller.action_pressed.disconnect(self.movement_action_pressed)
		if movement_controller.action_released.is_connected(self.movement_action_released):
			movement_controller.action_released.disconnect(self.movement_action_released)
	if turning_controller and is_instance_valid(turning_controller):
		if turning_controller.action_pressed.is_connected(self.turning_action_pressed):
			turning_controller.action_pressed.disconnect(self.turning_action_pressed)
		if turning_controller.action_released.is_connected(self.turning_action_released):
			turning_controller.action_released.disconnect(self.turning_action_released)

	if Input.is_action_pressed("snap_left"):
		Input.action_release("snap_left")
	if Input.is_action_pressed("snap_right"):
		Input.action_release("snap_right")

	movement_controller = _get_movement_controller()
	turning_controller = _get_turning_controller()

	if movement_controller and is_instance_valid(movement_controller):
		if movement_controller.action_pressed.connect(self.movement_action_pressed) != OK:
			printerr("Could not connect 'action_pressed'!")
		if movement_controller.action_released.connect(self.movement_action_released) != OK:
			printerr("Could not connect 'action_released'!")
	if turning_controller and is_instance_valid(turning_controller):
		if turning_controller.action_pressed.connect(self.turning_action_pressed) != OK:
			printerr("Could not connect 'action_pressed'!")
		if turning_controller.action_released.connect(self.turning_action_released) != OK:
			printerr("Could not connect 'action_released'!")


func get_controller_movement_vector() -> Vector2:
	var movement_vector: Vector2 = Vector2()

	if (
		hand_controllers.size() >= 2
		and left_hand_controller
		and right_hand_controller
		and is_instance_valid(left_hand_controller)
		and is_instance_valid(right_hand_controller)
	):
		movement_controller = left_hand_controller
		movement_vector = movement_controller.get_vector2("primary")
		if !VRManager.vr_user_preferences.strafe_movement:
			movement_vector.x = 0.0
		if VRManager.vr_user_preferences.movement_on_rotation_controller:
			turning_controller = right_hand_controller
			movement_vector.y += turning_controller.get_vector2("primary").y
	elif hand_controllers.size() == 1:
		movement_vector = Vector2(0.0, hand_controllers[0].get_vector2("primary").y)

	# Test the deadzone
	if abs(movement_vector.x) < VRManager.vr_user_preferences.movement_deadzone:
		movement_vector.x = 0.0
	if abs(movement_vector.y) < VRManager.vr_user_preferences.movement_deadzone:
		movement_vector.y = 0.0

	return movement_vector.limit_length(1.0)


func get_controller_turning_vector() -> Vector2:
	var turning_vector: Vector2 = Vector2()

	if (
		hand_controllers.size() >= 2
		and is_instance_valid(left_hand_controller)
		and is_instance_valid(right_hand_controller)
	):
		turning_controller = right_hand_controller

		turning_vector = Vector2(turning_controller.get_vector2("primary").x, 0.0)
	elif hand_controllers.size() == 1:
		turning_vector = Vector2(hand_controllers[0].get_vector2("primary").x, 0.0)

	# Test the deadzone
	if abs(turning_vector.x) < VRManager.vr_user_preferences.rotation_deadzone:
		turning_vector.x = 0.0
	if abs(turning_vector.y) < VRManager.vr_user_preferences.rotation_deadzone:
		turning_vector.y = 0.0

	return turning_vector * VRManager.vr_user_preferences.rotation_sensitivity


func get_controller_direction() -> Basis:
	if hand_controllers.size() == 2:
		if (
			(
				VRManager.vr_user_preferences.preferred_hand_oriented_movement_hand
				== VRManager.vr_user_preferences.hand_enum.LEFT_HAND
			)
			and left_hand_controller
		):
			return left_hand_controller.transform.basis
		if (
			(
				VRManager.vr_user_preferences.preferred_hand_oriented_movement_hand
				== VRManager.vr_user_preferences.hand_enum.RIGHT_HAND
			)
			and right_hand_controller
		):
			return right_hand_controller.transform.basis
	elif hand_controllers.size() == 1:
		return hand_controllers[0].transform.basis

	return Basis()


func _process(_delta):
	if VRManager != null && VRManager.xr_active:
		var movement_vector: Vector2 = get_controller_movement_vector()
		var turning_vector: Vector2 = get_controller_turning_vector()

		# Movement
		if movement_vector.y > 0.0:
			Input.action_press("move_forwards", abs(movement_vector.y))
			Input.action_press("move_backwards", 0.0)
		elif movement_vector.y < 0.0:
			Input.action_press("move_backwards", abs(movement_vector.y))
			Input.action_press("move_forwards", 0.0)
		else:
			Input.action_press("move_forwards", 0.0)
			Input.action_press("move_backwards", 0.0)

		if movement_vector.x > 0.0:
			Input.action_press("move_right", abs(movement_vector.x))
			Input.action_press("move_left", 0.0)
		elif movement_vector.x < 0.0:
			Input.action_press("move_left", abs(movement_vector.x))
			Input.action_press("move_right", 0.0)
		else:
			Input.action_press("move_right", 0.0)
			Input.action_press("move_left", 0.0)

		# Looking
		if turning_vector.y > 0.0:
			Input.action_press("look_up", abs(turning_vector.y))
			Input.action_press("look_down", 0.0)
		elif turning_vector.y < 0.0:
			Input.action_press("look_down", abs(turning_vector.y))
			Input.action_press("look_up", 0.0)
		else:
			Input.action_press("look_up", 0.0)
			Input.action_press("look_down", 0.0)

		if turning_vector.x > 0.0:
			Input.action_press("look_right", abs(turning_vector.x))
			Input.action_press("look_left", 0.0)
		elif turning_vector.x < 0.0:
			Input.action_press("look_left", abs(turning_vector.x))
			Input.action_press("look_right", 0.0)
		else:
			Input.action_press("look_right", 0.0)
			Input.action_press("look_left", 0.0)


func post_add_setup() -> void:
	super.post_add_setup()


func _enter_tree():
	set_name("LocomotionComponent")


func _ready():
	if trackers_changed.connect(self._refresh_controllers) != OK:
		printerr("Could not connect 'trackers_changed'!")

	_refresh_controllers()
