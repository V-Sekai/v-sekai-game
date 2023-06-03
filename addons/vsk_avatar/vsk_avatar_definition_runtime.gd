# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_avatar_definition_runtime.gd
# SPDX-License-Identifier: MIT

@tool
extends Node3D

const avatar_physics_const = preload("avatar_physics.gd")

var driver_node: Node = null

@export var skeleton_path: NodePath = NodePath():
	set = set_skeleton_path

var _skeleton_node: Skeleton3D = null

@export var avatar_physics_path: NodePath = NodePath():
	set = set_avatar_physics_path

var _avatar_physics_node: Node = get_node_or_null(avatar_physics_path)

@export var eye_transform_node_path: NodePath = NodePath()

@export var mouth_transform_node_path: NodePath = NodePath()
# @onready var _mouth_transform_node: Node3D = get_node_or_null(mouth_transform_node_path)

@export var database_id: String


func set_eye_transform_path(p_node_path: NodePath) -> void:
	eye_transform_node_path = p_node_path


func set_mouth_transform_path(p_node_path: NodePath) -> void:
	mouth_transform_node_path = p_node_path


func set_skeleton_path(p_skeleton_path: NodePath) -> void:
	skeleton_path = p_skeleton_path
	_skeleton_node = null

	var skeleton_node: Skeleton3D = get_node_or_null(skeleton_path)
	if skeleton_node is Skeleton3D:
		_skeleton_node = skeleton_node
	else:
		_skeleton_node = null


func set_avatar_physics_path(p_avatar_physics_path: NodePath) -> void:
	avatar_physics_path = p_avatar_physics_path
	_avatar_physics_node = null

	var avatar_physics_node: Node = get_node_or_null(avatar_physics_path)
	if avatar_physics_node:
		if avatar_physics_node.get_script() == avatar_physics_const:
			_avatar_physics_node = avatar_physics_node
		else:
			_avatar_physics_node = null


func _ready() -> void:
	set_skeleton_path(skeleton_path)
	set_avatar_physics_path(avatar_physics_path)
