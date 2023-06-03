# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# player_hand_controller.gd
# SPDX-License-Identifier: MIT

extends Node

var logic_node: Node = null

var _avatar_display: Node = null
@export var avatar_display_path: NodePath = NodePath()

var left_hand_gesture_id: int = 0
var right_hand_gesture_id: int = 0

var avatar_manager: Node


func _input(event):
	if event is InputEventAction:
		if event.pressed:
			match event.action:
				"left_hand_pose_open":
					left_hand_gesture_id = VSKAvatarManager.HAND_POSE_OPEN
					print("Left Hand Pose Open")
				"left_hand_pose_neutral":
					left_hand_gesture_id = VSKAvatarManager.HAND_POSE_NEUTRAL
					print("Left Hand Pose Neutral")
				"left_hand_pose_point":
					left_hand_gesture_id = VSKAvatarManager.HAND_POSE_POINT
					print("Left Hand Pose Point")
				"left_hand_pose_gun":
					left_hand_gesture_id = VSKAvatarManager.HAND_POSE_GUN
					print("Left Hand Pose Gun")
				"left_hand_pose_thumbs_up":
					left_hand_gesture_id = VSKAvatarManager.HAND_POSE_THUMBS_UP
					print("Left Hand Pose Thumbs Up")
				"left_hand_pose_fist":
					left_hand_gesture_id = VSKAvatarManager.HAND_POSE_FIST
					print("Left Hand Pose Fist")
				"left_hand_pose_victory":
					left_hand_gesture_id = VSKAvatarManager.HAND_POSE_VICTORY
					print("Left Hand Pose Victory")
				"left_hand_pose_ok_sign":
					left_hand_gesture_id = VSKAvatarManager.HAND_POSE_OK_SIGN
					print("Left Hand Pose OK Sign")
				"right_hand_pose_open":
					right_hand_gesture_id = VSKAvatarManager.HAND_POSE_OPEN
					print("Right Hand Pose Open")
				"right_hand_pose_neutral":
					right_hand_gesture_id = VSKAvatarManager.HAND_POSE_NEUTRAL
					print("Right Hand Pose Neutral")
				"right_hand_pose_point":
					right_hand_gesture_id = VSKAvatarManager.HAND_POSE_POINT
					print("Right Hand Pose Point")
				"right_hand_pose_gun":
					right_hand_gesture_id = VSKAvatarManager.HAND_POSE_GUN
					print("Right Hand Pose Gun")
				"right_hand_pose_thumbs_up":
					right_hand_gesture_id = VSKAvatarManager.HAND_POSE_THUMBS_UP
					print("Right Hand Pose Thumbs Up")
				"right_hand_pose_fist":
					right_hand_gesture_id = VSKAvatarManager.HAND_POSE_FIST
					print("Right Hand Pose Fist")
				"right_hand_pose_victory":
					right_hand_gesture_id = VSKAvatarManager.HAND_POSE_VICTORY
					print("Right Hand Pose Victory")
				"right_hand_pose_ok_sign":
					right_hand_gesture_id = VSKAvatarManager.HAND_POSE_OK_SIGN
					print("Right Hand Pose OK Sign")

	update_driver()


func update_driver() -> void:
	if _avatar_display and _avatar_display.avatar_node and _avatar_display.avatar_node.driver_node:
		_avatar_display.avatar_node.driver_node.left_hand_gesture_id = left_hand_gesture_id
		_avatar_display.avatar_node.driver_node.right_hand_gesture_id = right_hand_gesture_id


func _puppet_setup() -> void:
	set_process_input(false)


func _master_setup() -> void:
	avatar_manager = $"/root/VSKAvatarManager"
	left_hand_gesture_id = avatar_manager.HAND_POSE_NEUTRAL
	right_hand_gesture_id = avatar_manager.HAND_POSE_NEUTRAL

	if Input.is_action_pressed("left_hand_pose_open"):
		left_hand_gesture_id = avatar_manager.HAND_POSE_OPEN
	elif Input.is_action_just_pressed("left_hand_pose_neutral"):
		left_hand_gesture_id = avatar_manager.HAND_POSE_NEUTRAL
	elif Input.is_action_pressed("left_hand_pose_point"):
		left_hand_gesture_id = avatar_manager.HAND_POSE_POINT
	elif Input.is_action_pressed("left_hand_pose_gun"):
		left_hand_gesture_id = avatar_manager.HAND_POSE_GUN
	elif Input.is_action_pressed("left_hand_pose_thumbs_up"):
		left_hand_gesture_id = avatar_manager.HAND_POSE_THUMBS_UP
	elif Input.is_action_pressed("left_hand_pose_fist"):
		left_hand_gesture_id = avatar_manager.HAND_POSE_FIST
	elif Input.is_action_pressed("left_hand_pose_victory"):
		left_hand_gesture_id = avatar_manager.HAND_POSE_VICTORY
	elif Input.is_action_pressed("left_hand_pose_ok_sign"):
		left_hand_gesture_id = avatar_manager.HAND_POSE_OK_SIGN

	if Input.is_action_pressed("right_hand_pose_open"):
		right_hand_gesture_id = avatar_manager.HAND_POSE_OPEN
	elif Input.is_action_just_pressed("right_hand_pose_neutral"):
		right_hand_gesture_id = avatar_manager.HAND_POSE_NEUTRAL
	elif Input.is_action_pressed("right_hand_pose_point"):
		right_hand_gesture_id = avatar_manager.HAND_POSE_POINT
	elif Input.is_action_pressed("right_hand_pose_gun"):
		right_hand_gesture_id = avatar_manager.HAND_POSE_GUN
	elif Input.is_action_pressed("right_hand_pose_thumbs_up"):
		right_hand_gesture_id = avatar_manager.HAND_POSE_THUMBS_UP
	elif Input.is_action_pressed("right_hand_pose_fist"):
		right_hand_gesture_id = avatar_manager.HAND_POSE_FIST
	elif Input.is_action_pressed("right_hand_pose_victory"):
		right_hand_gesture_id = avatar_manager.HAND_POSE_VICTORY
	elif Input.is_action_pressed("right_hand_pose_ok_sign"):
		right_hand_gesture_id = avatar_manager.HAND_POSE_OK_SIGN

	update_driver()

	set_process_input(true)


func setup(p_logic_node: Node) -> void:
	avatar_manager = $"/root/VSKAvatarManager"
	logic_node = p_logic_node

	_avatar_display = get_node_or_null(avatar_display_path)

	# State machine
	if !logic_node.is_entity_master():
		_puppet_setup()
	else:
		_master_setup()
