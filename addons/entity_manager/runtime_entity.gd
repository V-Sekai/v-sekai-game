# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# runtime_entity.gd
# SPDX-License-Identifier: MIT

@tool
class_name RuntimeEntity extends Node

##
## Dependency Graph
##

var representation_process_ticks_usec: int = 0
var physics_process_ticks_usec: int = 0

const node_3d_simulation_logic_const = preload("node_3d_simulation_logic.gd")
const node_2d_simulation_logic_const = preload("node_2d_simulation_logic.gd")

const mutex_lock_const = preload("res://addons/gd_util/mutex_lock.gd")

var current_job: RefCounted = null
var dependency_mutex: Mutex = Mutex.new()

var strong_exclusive_dependencies: Dictionary = {}
var strong_exclusive_dependents: Array = []


class DependencyCommand:
	const ADD_STRONG_EXCLUSIVE_DEPENDENCY = 0
	const REMOVE_STRONG_EXCLUSIVE_DEPENDENCY = 1


var pending_dependency_commands: Array = []

var entity_ref: EntityRef = EntityRef.new(self)

var nodes_cached: bool = false
var _EntityManager: Node

##
## Parenting
##

signal entity_message(p_message, p_args)
signal entity_deletion

##
## Entity Manager
##

##
## Transform3D Notification
##
@export var transform_notification_node_path: NodePath = NodePath()
var transform_notification_node: Node = null

##
## Hierarchy Component Node
##
@export var hierarchy_component_node_path: NodePath = NodePath()
var hierarchy_component_node: Node = null

##
## Simulation Logic Node
##
@export var simulation_logic_node_path: NodePath = NodePath()
var simulation_logic_node: Node = null

##
## Network Identity Node
##
@export var network_identity_node_path: NodePath = NodePath()
var network_identity_node: Node = null

##
## Network Logic Node
##
@export var network_logic_node_path: NodePath = NodePath()
var network_logic_node: Node = null

##
## RPC table Node
##
@export var rpc_table_node_path: NodePath = NodePath()
var rpc_table_node: Node = null

##
##

# Missing from Godot docuementation
# Object::Connection::operator Variant() const {
#        Dictionary d;
#        d["signal"] = signal;
#        d["callable"] = callable;
#        d["flags"] = flags;
#        d["binds"] = binds;
#        return d;
#}


static func get_custom_logic_node_properties(p_node: Node) -> Array:
	var properties: Array = []
	var node_property_list: Array = p_node.get_property_list()
	for property in node_property_list:
		if property["usage"] & PROPERTY_USAGE_EDITOR and property["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE:
			if property["name"].substr(0, 1) != "_":
				properties.push_back(property)

	return properties


func clear_entity_signal_connections() -> void:
	var entity_message_connections: Array = get_signal_connection_list("entity_message")
	for connection in entity_message_connections:
		connection["signal"].disconnect(connection["callable"])

	var entity_deletion_connections: Array = get_signal_connection_list("entity_deletion")
	for connection in entity_deletion_connections:
		connection["signal"].disconnect(connection["callable"])


func _create_strong_exclusive_dependency(p_entity_ref: RefCounted) -> void:
	var _mutex_lock: RefCounted = mutex_lock_const.new(dependency_mutex)
	pending_dependency_commands.push_back({"command": DependencyCommand.ADD_STRONG_EXCLUSIVE_DEPENDENCY, "entity": p_entity_ref})


func _remove_strong_exclusive_dependency(p_entity_ref: RefCounted) -> void:
	var _mutex_lock: RefCounted = mutex_lock_const.new(dependency_mutex)
	pending_dependency_commands.push_back({"command": DependencyCommand.REMOVE_STRONG_EXCLUSIVE_DEPENDENCY, "entity": p_entity_ref})


func _update_dependencies() -> void:
	for pending_dependency in pending_dependency_commands:
		var entity: RuntimeEntity = pending_dependency["entity"]._entity
		if entity:
			match pending_dependency["command"]:
				DependencyCommand.ADD_STRONG_EXCLUSIVE_DEPENDENCY:
					if strong_exclusive_dependencies.has(entity):
						strong_exclusive_dependencies[entity] += 1
					else:
						if EntityManagerFunctions.check_if_dependency_is_cyclic(self, entity, true):
							printerr("Error: tried to create a cyclic dependency!")
						else:
							strong_exclusive_dependencies[entity] = 1
							entity.strong_exclusive_dependents.push_back(self)
				DependencyCommand.REMOVE_STRONG_EXCLUSIVE_DEPENDENCY:
					if !strong_exclusive_dependencies.has(entity):
						printerr("Does not have exclusive strong dependency!")
					else:
						strong_exclusive_dependencies[entity] -= 1
						if strong_exclusive_dependencies[entity] <= 0:
							if strong_exclusive_dependencies.erase(entity):
								entity.strong_exclusive_dependents.erase(self)
							else:
								printerr("Could not erase strong exclusive dependency!")
	pending_dependency_commands.clear()


func request_to_become_master() -> void:
	$"/root/NetworkManager".network_replication_manager.request_to_become_master(network_identity_node.network_instance_id, self, $"/root/NetworkManager".get_current_peer_id())


func process_master_request(p_id: int) -> void:
	set_multiplayer_authority(p_id)


func _entity_about_to_add() -> void:
	if network_logic_node:
		network_logic_node._entity_about_to_add()
	else:
		printerr("_entity_about_to_add missing network logic node")


func _entity_ready() -> void:
	_entity_cache()

	if !Engine.is_editor_hint():
		if simulation_logic_node and simulation_logic_node.has_method("_entity_ready"):
			simulation_logic_node._entity_ready()
		else:
			printerr("_entity_ready is missing simulation logic node!")

		if network_identity_node:
			network_identity_node._entity_ready()
		else:
			printerr("Missing network identity node")

		if network_logic_node:
			network_logic_node._entity_ready()
		else:
			printerr("_entity_ready is missing network logic node")

		network_identity_node.update_name()


func _entity_representation_process(p_delta: float) -> void:
	var start_ticks: int = Time.get_ticks_usec()

	if network_logic_node:
		network_logic_node._entity_representation_process(p_delta)
	else:
		printerr("_entity_representation_process is missing network logic node")
	if simulation_logic_node and simulation_logic_node.has_method("_entity_representation_process"):
		simulation_logic_node._entity_representation_process(p_delta)
	else:
		printerr("_entity_representation_process is missing simulation logic node!")

	representation_process_ticks_usec = Time.get_ticks_usec() - start_ticks


func _entity_physics_pre_process(p_delta) -> void:
	if simulation_logic_node and simulation_logic_node.has_method("_entity_physics_pre_process"):
		simulation_logic_node._entity_physics_pre_process(p_delta)
	else:
		printerr("_entity_physics_pre_process is missing simulation logic node!")


func _entity_physics_process(p_delta: float) -> void:
	var start_ticks: int = Time.get_ticks_usec()

	# Clear the job for next time the scheduler is run
	current_job = null

	if network_logic_node:
		network_logic_node._entity_physics_process(p_delta)
	else:
		printerr("_entity_physics_process is missing network logic node")
	if simulation_logic_node and simulation_logic_node.has_method("_entity_physics_process"):
		simulation_logic_node._entity_physics_process(p_delta)
	else:
		printerr("Missing simulation logic node!")

	physics_process_ticks_usec = Time.get_ticks_usec() - start_ticks


func _entity_kinematic_integration_callback(p_delta: float) -> void:
	if simulation_logic_node:
		simulation_logic_node._entity_kinematic_integration_callback(p_delta)
	else:
		printerr("_entity_kinematic_integration_callback is missing simulation logic node!")


func _entity_physics_post_process(p_delta) -> void:
	if simulation_logic_node and simulation_logic_node.has_method("_entity_physics_post_process"):
		simulation_logic_node._entity_physics_post_process(p_delta)


func get_attachment_id(p_attachment_name: String) -> int:
	return simulation_logic_node.get_attachment_id(p_attachment_name)


func get_attachment_node(p_attachment_id: int) -> Node:
	return simulation_logic_node.get_attachment_node(p_attachment_id)


func cache_nodes() -> void:
	transform_notification_node = get_node_or_null(transform_notification_node_path)
	if transform_notification_node == self:
		transform_notification_node = null

	hierarchy_component_node = get_node_or_null(hierarchy_component_node_path)
	if hierarchy_component_node == self:
		hierarchy_component_node = null

	simulation_logic_node = get_node_or_null(simulation_logic_node_path)
	if simulation_logic_node == self:
		simulation_logic_node = null

	network_identity_node = get_node_or_null(network_identity_node_path)
	if network_identity_node == self:
		network_identity_node = null

	network_logic_node = get_node_or_null(network_logic_node_path)
	if network_logic_node == self:
		network_logic_node = null

	rpc_table_node = get_node_or_null(rpc_table_node_path)
	if rpc_table_node == self:
		rpc_table_node = null


func get_entity() -> Node:
	return self


func get_entity_ref() -> RefCounted:
	return entity_ref


func _entity_deletion() -> void:
	entity_deletion.emit()
	for dependent in strong_exclusive_dependents:
		dependent.strong_exclusive_dependencies.erase(self)

	if _EntityManager:
		_EntityManager._entity_deleting(self)


func can_request_master_from_peer(p_id: int) -> bool:
	if simulation_logic_node:
		return simulation_logic_node.can_request_master_from_peer(p_id)
	else:
		return false


func can_transfer_master_from_session_master(p_id: int) -> bool:
	if simulation_logic_node:
		return simulation_logic_node.can_transfer_master_from_session_master(p_id)
	else:
		return false


func create_strong_exclusive_dependency_for(p_entity_ref: EntityRef):
	return _EntityManager.create_strong_dependency(p_entity_ref, get_entity_ref())


func create_strong_exclusive_dependency_to(p_entity_ref: EntityRef):
	return _EntityManager.create_strong_dependency(get_entity_ref(), p_entity_ref)


func get_dependent_entity(p_entity_ref: RefCounted):
	return _EntityManager.get_dependent_entity_for_dependency(get_entity_ref(), p_entity_ref)


func register_kinematic_integration_callback() -> void:
	_EntityManager.register_kinematic_integration_callback(self)


func unregister_kinematic_integration_callback() -> void:
	_EntityManager.unregister_kinematic_integration_callback(self)


func get_entity_type() -> String:
	if simulation_logic_node:
		return simulation_logic_node._entity_type
	else:
		return "Unknown Entity Type"


func get_last_transform():
	if simulation_logic_node and simulation_logic_node is node_2d_simulation_logic_const or simulation_logic_node is node_3d_simulation_logic_const:
		return simulation_logic_node.get_last_transform()

	return Transform3D()


func send_entity_message(p_target_entity: RefCounted, p_message: String, p_message_args: Dictionary) -> void:
	_EntityManager.send_entity_message(get_entity_ref(), p_target_entity, p_message, p_message_args)


func _receive_entity_message(p_message: String, p_args: Dictionary) -> void:
	entity_message.emit(p_message, p_args)


static func get_entity_properties(p_show_properties: bool) -> Array:
	var usage: int
	if p_show_properties:
		usage = PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_SCRIPT_VARIABLE
	else:
		usage = 0

	var entity_properties: Array = [{"name": "transform_notification_node_path", "type": TYPE_NODE_PATH, "usage": usage, "hint": PROPERTY_HINT_FLAGS, "hint_string": "NodePath"}, {"name": "hierarchy_component_node_path", "type": TYPE_NODE_PATH, "usage": usage, "hint": PROPERTY_HINT_FLAGS, "hint_string": "NodePath"}, {"name": "simulation_logic_node_path", "type": TYPE_NODE_PATH, "usage": usage, "hint": PROPERTY_HINT_FLAGS, "hint_string": "NodePath"}, {"name": "network_identity_node_path", "type": TYPE_NODE_PATH, "usage": usage, "hint": PROPERTY_HINT_FLAGS, "hint_string": "NodePath"}, {"name": "network_logic_node_path", "type": TYPE_NODE_PATH, "usage": usage, "hint": PROPERTY_HINT_FLAGS, "hint_string": "NodePath"}, {"name": "rpc_table_node_path", "type": TYPE_NODE_PATH, "usage": usage, "hint": PROPERTY_HINT_FLAGS, "hint_string": "NodePath"}]

	return entity_properties


func is_root_entity() -> bool:
	return false


func get_rpc_table() -> Node:
	return rpc_table_node


func _entity_cache() -> void:
	if not nodes_cached:
		propagate_call("cache_nodes", [], true)
		nodes_cached = true


func _get_property_list() -> Array:
	var properties: Array = RuntimeEntity.get_entity_properties(is_root_entity())
	return properties


func _get(p_property: StringName):
	match p_property:
		"transform_notification_node_path":
			return transform_notification_node_path
		"hierarchy_component_node_path":
			return hierarchy_component_node_path
		"simulation_logic_node_path":
			return simulation_logic_node_path
		"network_identity_node_path":
			return network_identity_node_path
		"network_logic_node_path":
			return network_logic_node_path
		"rpc_table_node_path":
			return rpc_table_node_path


func _set(p_property: StringName, p_value) -> bool:
	match p_property:
		"transform_notification_node_path":
			transform_notification_node_path = p_value
			return true
		"hierarchy_component_node_path":
			hierarchy_component_node_path = p_value
			return true
		"simulation_logic_node_path":
			simulation_logic_node_path = p_value
			return true
		"network_identity_node_path":
			network_identity_node_path = p_value
			return true
		"network_logic_node_path":
			network_logic_node_path = p_value
			return true
		"rpc_table_node_path":
			rpc_table_node_path = p_value
			return true

	return false


func _notification(what) -> void:
	if what == NOTIFICATION_PREDELETE:
		if !Engine.is_editor_hint():
			entity_ref._entity = null

			_entity_deletion()


func _ready() -> void:
	if !Engine.is_editor_hint():
		_EntityManager = $"/root/EntityManager"
		if _EntityManager == null:
			push_error(str(self) + " failed to find EntityManager!")
		if _EntityManager:
			add_to_group("Entities")

			if self.ready.connect(_EntityManager._entity_ready.bind(self)) != OK:
				printerr("entity: _ready could not be connected!")


func _threaded_instance_setup(p_instance_id: int, p_network_reader: RefCounted) -> void:
	_entity_cache()

	if not has_method("_threaded_instance_setup"):
		return

	if simulation_logic_node:
		simulation_logic_node._threaded_instance_setup(p_instance_id, p_network_reader)
	if network_logic_node:
		network_logic_node._threaded_instance_setup(p_instance_id, p_network_reader)
	if network_identity_node:
		network_identity_node._threaded_instance_setup(p_instance_id, p_network_reader)
