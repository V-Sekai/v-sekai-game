# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_resource_manager.gd
# SPDX-License-Identifier: MIT

@tool
extends Node

const MAP_RESOURCE_IDENTIFIER = "mpr"
const GAME_MODE_RESOURCE_IDENTIFIER = "gmr"

var get_map_id_for_entity_resource_funcref: Callable = Callable()
var get_entity_resource_for_map_id_funcref: Callable = Callable()

var get_game_mode_id_for_entity_resource_funcref: Callable = Callable()
var get_entity_resource_for_game_mode_id_funcref: Callable = Callable()

##
## Map
##


func assign_get_map_id_for_resource_function(p_node: Node, p_method: String) -> void:
	get_map_id_for_entity_resource_funcref = Callable(p_node, p_method)


func assign_get_resource_for_map_id_function(p_node: Node, p_method: String) -> void:
	get_entity_resource_for_map_id_funcref = Callable(p_node, p_method)


func get_map_id_for_entity_resource(p_resource: Resource) -> int:
	if get_map_id_for_entity_resource_funcref.is_valid():
		return get_map_id_for_entity_resource_funcref.call(p_resource)

	return -1


func get_entity_resource_for_map_id(p_int: int) -> Resource:
	if get_entity_resource_for_map_id_funcref.is_valid():
		return get_entity_resource_for_map_id_funcref.call(p_int)

	return null


##
## Game Mode
##
func assign_get_game_mode_id_for_resource_function(p_node: Node, p_method: String) -> void:
	get_game_mode_id_for_entity_resource_funcref = Callable(p_node, p_method)


func assign_get_resource_for_game_mode_id_function(p_node: Node, p_method: String) -> void:
	get_entity_resource_for_game_mode_id_funcref = Callable(p_node, p_method)


func get_game_mode_id_for_entity_resource(p_resource: Resource) -> int:
	if get_game_mode_id_for_entity_resource_funcref.is_valid():
		return get_game_mode_id_for_entity_resource_funcref.call(p_resource)

	return -1


func get_entity_resource_for_game_mode_id(p_int: int) -> Resource:
	if get_entity_resource_for_game_mode_id_funcref.is_valid():
		return get_entity_resource_for_game_mode_id_funcref.call(p_int)

	return null


##
##


func get_path_for_entity_resource(p_resource: Resource) -> String:
	if !p_resource:
		return ""

	var map_resource_id: int = get_map_id_for_entity_resource(p_resource)
	print("map_resource_id %s" % str(map_resource_id))
	if map_resource_id != -1:
		return "%s://%s" % [MAP_RESOURCE_IDENTIFIER, str(map_resource_id)]

	var game_mode_resource_id: int = get_game_mode_id_for_entity_resource(p_resource)
	print("game_mode_resource_id %s" % str(game_mode_resource_id))
	if game_mode_resource_id != -1:
		return "%s://%s" % [GAME_MODE_RESOURCE_IDENTIFIER, str(game_mode_resource_id)]

	return p_resource.resource_path


func get_entity_resource_for_path(p_path: String) -> Resource:
	var map_resource_string_beginning: String = "%s://" % MAP_RESOURCE_IDENTIFIER
	if p_path.begins_with(map_resource_string_beginning):
		var string_diget: String = p_path.right(map_resource_string_beginning.length())
		if string_diget.is_valid_int():
			var id: int = string_diget.to_int()
			return get_entity_resource_for_map_id(id)

	var game_mode_resource_string_beginning: String = "%s://" % GAME_MODE_RESOURCE_IDENTIFIER
	if p_path.begins_with(game_mode_resource_string_beginning):
		var string_diget: String = p_path.right(game_mode_resource_string_beginning.length())
		if string_diget.is_valid_int():
			var id: int = string_diget.to_int()
			return get_entity_resource_for_game_mode_id(id)

	push_error("Refusing to load unrecognized resource path: " + str(p_path))
	return null


func setup() -> void:
	pass
