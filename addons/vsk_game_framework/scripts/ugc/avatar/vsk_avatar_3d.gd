# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_avatar_3d.gd
# SPDX-License-Identifier: MIT

@tool
extends SarAvatar3D
class_name VSKAvatar3D

const _DEFAULT_ANIMATION_TREE_DRIVER_PROPERTY_TABLE: AnimationTreeDriverPropertyTable = preload("res://addons/vsk_game_framework/animation_tree_driver/default_animation_tree_driver_property_table.tres")
const _DEFAULT_ANIMATION_TREE: AnimationNode = preload("res://addons/vsk_game_framework/animation_trees/default_player_animation.tres")
const _DEFAULT_ANIMATION_LOCOMOTION_LIBRARY: AnimationLibrary = preload("res://addons/vsk_game_framework/animation_libraries/default_locomotion_animation_library.tres")

# Attempts to construct a default AnimationTreeDriver for this avatar when
# we don't have one already set up.
func _setup_default_animation_driver() -> void:
	var root_node: Node3D = self
	
	# Search for the highest-level node with a unique _general_skeleton.
	if general_skeleton:
		while(root_node):
			if not root_node.get_node_or_null("%GeneralSkeleton"):
				break
			if root_node.get_parent():
				root_node = root_node.get_parent()
			else:
				break
	
	animation_tree_driver = AnimationTreeDriver.new()
	animation_tree_driver.name = "AnimationTreeDriver"
	animation_tree_driver.property_table = _DEFAULT_ANIMATION_TREE_DRIVER_PROPERTY_TABLE
	root_node.add_child(animation_tree_driver)
	
	var main_animation_tree: AnimationTree = AnimationTree.new()
	main_animation_tree.name = "AnimationTree"
	main_animation_tree.tree_root = _DEFAULT_ANIMATION_TREE
	main_animation_tree.add_animation_library("locomotion", _DEFAULT_ANIMATION_LOCOMOTION_LIBRARY)
	
	root_node.add_child(main_animation_tree)
	main_animation_tree.root_node = main_animation_tree.get_path_to(root_node)
	main_animation_tree.advance_expression_base_node = main_animation_tree.get_path_to(animation_tree_driver)
	
	animation_tree_driver.animation_tree = main_animation_tree
	
###

## The default player height.
const DEFAULT_HEIGHT: float = 1.8

# TODO: add a more appropriate DEFAULT_HEIGHT_TO_HEAD_BASE by subtracting
# an estimated head height.
const DEFAULT_HEIGHT_TO_HEAD_BASE: float = DEFAULT_HEIGHT

## Metadata table containing how we want to sync custom data for this avatar.
@export var parameter_table: VSKAvatarParameterTable = null

## Attempt to calculate a height from feet to the base of the head bone.
func calculate_height_to_head_base() -> float:
	if general_skeleton:
		var head_bone_idx: int = general_skeleton.find_bone("Head")
		if head_bone_idx >= 0:
			return general_skeleton.get_bone_global_rest(head_bone_idx).origin.y
			
	return DEFAULT_HEIGHT_TO_HEAD_BASE

## Called when the avatar is instantiated to ensure it is set up with
## reasonable defaults.
func setup_model(p_root_node: Node3D) -> void:
	super.setup_model(p_root_node)
	
	if not general_skeleton:
		general_skeleton = _find_avatar_skeleton(p_root_node)
		
	if not animation_tree_driver:
		_setup_default_animation_driver()
