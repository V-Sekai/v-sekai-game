# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# state_machine.gd
# SPDX-License-Identifier: MIT

@tool
##
## Base interface for a generic state machine
## It handles initializing, setting the machine active or not
## delegating _physics_process, _input calls to the State nodes,
## and changing the current/active state.
## See the PlayerV2 scene for an example on how to use it
##
extends Node

signal state_changed(current_state)

const state_const = preload("state.gd")

##
## You must set a starting node from the inspector or on
## the node that inherits from this state machine interface
## If you don't the game will crash (on purpose, so you won't
## forget to initialize the state machine)
##
@export var start_state: NodePath = NodePath()
var states_map: Dictionary = {}

var states_stack: Array = []
var current_state: Object = null
var _active: bool = false:
	set = set_active


func initialize(p_start_state: NodePath) -> void:
	set_active(true)
	states_stack.push_front(get_node(p_start_state))
	current_state = states_stack[0]
	current_state.enter()


func update(p_delta: float) -> void:
	current_state.update(p_delta)


func set_active(p_value: bool) -> void:
	_active = p_value
	if not _active:
		states_stack = []
		current_state = null


func _change_state(p_state_name: String) -> void:
	if not _active:
		return
	current_state.exit()

	if p_state_name == "previous":
		states_stack.pop_front()
	else:
		states_stack[0] = states_map[p_state_name]

	current_state = states_stack[0]
	state_changed.emit(current_state)

	if p_state_name != "previous":
		current_state.enter()


func start() -> void:
	if Engine.is_editor_hint():
		return
	if start_state == NodePath():
		start_state = get_child(0).get_path()
	for child in get_children():
		if not child.has_signal("finished"):
			continue
		child.finished.connect(self._change_state)
		child.state_machine = self
	initialize(start_state)
