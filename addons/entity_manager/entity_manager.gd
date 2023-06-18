# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# entity_manager.gd
# SPDX-License-Identifier: MIT

@tool
extends Node

@export var last_representation_process_usec: int = 0
@export var last_physics_process_usec: int = 0
@export var last_physics_post_process_usec: int = 0
@export var last_physics_pre_process_usec: int = 0
@export var last_update_dependencies_usec: int = 0

var _NetworkManager: Node = null

const network_constants_const = preload("res://addons/network_manager/network_constants.gd")
const entity_manager_const = preload("res://addons/entity_manager/entity_manager.gd")

const scene_tree_execution_table_const: Object = preload("res://addons/entity_manager/scene_tree_execution_table.gd")
var scene_tree_execution_table: Object = scene_tree_execution_table_const.new()


class EntityJob:
	extends RefCounted
	var entities: Array = []
	var overall_time_usec: int = 0

	func _init(p_entities: Array):
		entities = p_entities

	func combine(p_job: EntityJob) -> void:
		entities += p_job.entities
		overall_time_usec += p_job.overall_time_usec

	static func sort(a, b):
		if a.overall_time_usec > b.overall_time_usec:
			return true
		return false


# hack
func EntityJob_sort(a, b):
	if a.overall_time_usec > b.overall_time_usec:
		return true
	return false


var reparent_pending: Array = []
var entity_reference_dictionary: Dictionary = {}
var entity_kinematic_integration_callbacks: Array = []

signal entity_added(p_entity)
signal entity_removed(p_entity)

signal process_complete(p_delta)
signal physics_process_complete(p_delta)


# Returns the root node all network entities should parented to.
func get_entity_root_node() -> Node:
	if _NetworkManager == null:
		_NetworkManager = $"/root/NetworkManager"
	return _NetworkManager.get_entity_root_node()


# Dispatches a deferred add/remove entity command to the scene tree execution table.
func scene_tree_execution_command(p_command: int, p_entity_instance: Node):
	scene_tree_execution_table.scene_tree_execution_command(p_command, p_entity_instance)


func _add_entity(p_entity: Node) -> void:
	print("Adding: " + str(p_entity))
	if entity_reference_dictionary.has(p_entity):
		printerr("Entity already exists in the dictionary.")
		return
	entity_reference_dictionary[p_entity.get_entity_ref()] = p_entity


func _remove_entity(p_entity: Node) -> void:
	print("Removing: " + str(p_entity))
	var entity_ref = p_entity.get_entity_ref()
	if entity_reference_dictionary.has(entity_ref):
		if not entity_reference_dictionary.erase(entity_ref):
			printerr("Failed to remove entity from the dictionary.")
			return
	if entity_kinematic_integration_callbacks.has(p_entity):
		entity_kinematic_integration_callbacks.erase(p_entity)


func _delete_entity_unsafe(p_entity: Node) -> void:
	if p_entity and !p_entity.is_queued_for_deletion():
		# Set all the children of this entity to root
		for entity_child in p_entity.hierarchy_component_node.cached_entity_children:
			_reparent_unsafe(entity_child, null, 0)

		p_entity.queue_free()
		if p_entity.is_inside_tree():
			p_entity.get_parent().remove_child(p_entity)
			_remove_entity(p_entity)


func get_all_entities() -> Array:
	var return_array: Array = []
	for entity in entity_reference_dictionary.values():
		if entity == null:
			continue
		return_array.push_back(entity)

	return return_array


func register_kinematic_integration_callback(p_entity: RuntimeEntity) -> void:
	if !entity_kinematic_integration_callbacks.has(p_entity):
		entity_kinematic_integration_callbacks.push_back(p_entity)
	else:
		printerr("Attempted to add duplicate kinematic integration callback")


func unregister_kinematic_integration_callback(p_entity: RuntimeEntity) -> void:
	if entity_kinematic_integration_callbacks.has(p_entity):
		entity_kinematic_integration_callbacks.erase(p_entity)
	else:
		printerr("Attempted to remove invalid kinematic integration callback")


func _entity_ready(p_entity: RuntimeEntity) -> void:
	_add_entity(p_entity)
	entity_added.emit(p_entity)
	p_entity._entity_ready()


func _entity_deleting(p_entity: RuntimeEntity) -> void:
	_remove_entity(p_entity)
	entity_removed.emit(p_entity)


static func _has_immediate_dependency_link(p_dependent_entity: Node, p_dependency_entity: RuntimeEntity) -> bool:
	if p_dependent_entity.strong_exclusive_dependencies.has(p_dependency_entity):
		return true

	return false


static func check_if_dependency_is_cyclic(p_root_entity: Node, p_current_enity: Node, p_is_root: bool) -> bool:
	return EntityManagerFunctions.check_if_dependency_is_cyclic(p_root_entity, p_current_enity, p_is_root)


static func _get_job_for_entity(p_entity: Node):
	var entity_job: EntityJob = p_entity.current_job
	if !entity_job:
		entity_job = EntityJob.new([p_entity])
		entity_job.overall_time_usec += p_entity.physics_process_ticks_usec
		for strong_dependency in p_entity.strong_exclusive_dependencies:
			var strong_dependency_entity_job: EntityJob = _get_job_for_entity(strong_dependency)
			if strong_dependency_entity_job != entity_job:
				strong_dependency_entity_job.combine(entity_job)
				entity_job = strong_dependency_entity_job
		p_entity.current_job = entity_job

	return entity_job


func _create_entity_update_jobs() -> Array:
	var jobs: Array = []
	var pending_entities: Array = entity_reference_dictionary.values()
	for entity in pending_entities:
		if entity == null:
			continue
		var entity_job: EntityJob = entity_manager_const._get_job_for_entity(entity)
		if !jobs.has(entity_job):
			jobs.push_back(entity_job)

	jobs.sort_custom(EntityJob_sort)
	return jobs


func get_dependent_entity_for_dependency(p_entity_dependency: RefCounted, p_entity_dependent: RefCounted) -> RuntimeEntity:
	if !p_entity_dependency._entity:
		printerr("Could not get entity for dependency!")
		return null
	if !p_entity_dependent._entity:
		printerr("Could not get entity for dependent!")
		return null

	if entity_manager_const._has_immediate_dependency_link(p_entity_dependent._entity, p_entity_dependency._entity):
		return p_entity_dependent._entity
	else:
		printerr("Does not have dependency!")

	return null


func check_bidirectional_dependency(p_entity_dependency: RefCounted, p_entity_dependent: RefCounted) -> bool:
	if !p_entity_dependency._entity or !p_entity_dependent._entity:
		return false

	if entity_manager_const._has_immediate_dependency_link(p_entity_dependency._entity, p_entity_dependent._entity):
		return true
	if entity_manager_const._has_immediate_dependency_link(p_entity_dependent._entity, p_entity_dependency._entity):
		return true

	return false


func create_strong_dependency(p_dependent: EntityRef, p_dependency: EntityRef) -> StrongExclusiveEntityDependencyHandle:
	if !p_dependent or !p_dependency:
		return null

	var dependent_entity: Node = p_dependent._entity
	var dependency_entity: Node = p_dependency._entity

	if !dependent_entity or !dependency_entity:
		printerr("Could not get entity ref!")
		return null
	if dependent_entity == dependency_entity:
		printerr("Attempted to create dependency on self!")
		return null

	return StrongExclusiveEntityDependencyHandle.new(p_dependent, p_dependency)


func get_entity_type_safe(p_target_entity: EntityRef) -> String:
	if p_target_entity._entity:
		return p_target_entity._entity.get_entity_type()
	else:
		return ""


func get_entity_last_transform_safe(p_target_entity: EntityRef) -> String:
	if p_target_entity._entity:
		return p_target_entity._entity.get_last_transform()
	else:
		return ""


func send_entity_message(p_source_entity: EntityRef, p_target_entity: EntityRef, p_message: String, p_message_args: Dictionary) -> void:
	if check_bidirectional_dependency(p_source_entity, p_target_entity):
		p_target_entity._entity._receive_entity_message(p_message, p_message_args)
	else:
		printerr("Could not send message to target entity! No dependency link!")


static func create_entity_instance(p_packed_scene: PackedScene, p_name: String = "NetEntity", p_master_id: int = network_constants_const.SERVER_MASTER_PEER_ID) -> Node:
	print_debug("Creating entity instantiate {name} of type {type}".format({"name": p_name, "type": p_packed_scene.resource_path}))
	var instantiate: Node = p_packed_scene.instantiate()
	instantiate.set_name(p_name)
	instantiate.set_multiplayer_authority(p_master_id)

	return instantiate


func instantiate_entity_and_setup(p_packed_scene: PackedScene, p_properties: Dictionary = {}, p_name: String = "NetEntity", p_master_id: int = network_constants_const.SERVER_MASTER_PEER_ID) -> Node:
	var instantiate: Node = entity_manager_const.create_entity_instance(p_packed_scene, p_name, p_master_id)

	instantiate._entity_cache()
	for key in p_properties.keys():
		instantiate.simulation_logic_node.set(key, p_properties[key])

	if _NetworkManager == null:
		_NetworkManager = $"/root/NetworkManager"
	instantiate._threaded_instance_setup(_NetworkManager.network_entity_manager.NULL_NETWORK_INSTANCE_ID, null)

	return instantiate


##
## This method instantiates an entity and queues is to be added
## to the scene. It is the function which should be called by
## entities which spawn other entities which are required to
## be avaliable next frame.
##
## Return an EntityRef handle for the instantiate.
##
func spawn_entity(p_packed_scene: PackedScene, p_properties: Dictionary = {}, p_name: String = "NetEntity", p_master_id: int = network_constants_const.SERVER_MASTER_PEER_ID) -> EntityRef:
	var instantiate: Node = instantiate_entity_and_setup(p_packed_scene, p_properties, p_name, p_master_id)
	if instantiate:
		self.scene_tree_execution_command(scene_tree_execution_table.ADD_ENTITY, instantiate)
		return instantiate.get_entity_ref()

	return null


func _reparent_unsafe(p_entity: Node, p_entity_parent_ref: EntityRef, p_attachment_id: int) -> void:
	var global_transform: Transform3D = p_entity.get_global_transform().orthonormalized()

	p_entity.get_parent().remove_child(p_entity)
	if p_entity_parent_ref:
		var attachment_node = p_entity_parent_ref._entity.get_attachment_node(p_attachment_id)
		var relative_transform = attachment_node.get_global_transform().affine_inverse() * global_transform
		p_entity.set_transform(relative_transform)
		attachment_node.add_child(p_entity, true)
	else:
		p_entity.set_transform(global_transform)
		get_entity_root_node().add_child(p_entity, true)


func _process_reparenting() -> void:
	for entity in reparent_pending:
		_reparent_unsafe(entity, entity.hierarchy_component_node.pending_entity_parent_ref, entity.hierarchy_component_node.pending_attachment_id)

	reparent_pending.clear()


func _process(p_delta: float) -> void:
	var all_entities_representation_process_usec_start: int = Time.get_ticks_usec()
	for entity in get_all_entities():
		if entity == null:
			push_error("Found a null entity in _process")
		else:
			entity._entity_representation_process(p_delta)
	last_representation_process_usec = Time.get_ticks_usec() - all_entities_representation_process_usec_start

	process_complete.emit(p_delta)


func _physics_process(p_delta: float) -> void:
	scene_tree_execution_table._execute_scene_tree_execution_table_unsafe()

	_process_reparenting()

	var jobs: Array = _create_entity_update_jobs()

	var entity_update_dependencies_usec_start: int = Time.get_ticks_usec()
	for entity in entity_reference_dictionary.values():
		if entity == null:
			continue
		entity._update_dependencies()
	last_update_dependencies_usec = Time.get_ticks_usec() - entity_update_dependencies_usec_start

	var entity_pre_physics_process_usec_start: int = Time.get_ticks_usec()
	for entity in entity_reference_dictionary.values():
		if entity == null:
			continue
		entity._entity_physics_pre_process(p_delta)
	last_physics_pre_process_usec = Time.get_ticks_usec() - entity_pre_physics_process_usec_start

	var entity_physics_process_usec_start: int = Time.get_ticks_usec()
	for job in jobs:
		for entity in job.entities:
			entity._entity_physics_process(p_delta)
	last_physics_process_usec = Time.get_ticks_usec() - entity_physics_process_usec_start

	for entity in entity_kinematic_integration_callbacks:
		if not entity:
			continue
		entity._entity_kinematic_integration_callback(p_delta)

	var entity_post_physics_process_usec_start: int = Time.get_ticks_usec()
	for entity in entity_reference_dictionary.values():
		if entity == null:
			continue
		entity._entity_physics_post_process(p_delta)
	last_physics_post_process_usec = Time.get_ticks_usec() - entity_post_physics_process_usec_start

	_process_reparenting()

	physics_process_complete.emit(p_delta)


func apply_project_settings() -> void:
	if Engine.is_editor_hint():
		if !ProjectSettings.has_setting("entities/config/process_priority"):
			ProjectSettings.set_setting("entities/config/process_priority", 0)
			if ProjectSettings.save() != OK:
				printerr("Could not save project settings!")


func get_project_settings() -> void:
	process_priority = ProjectSettings.get_setting("entities/config/process_priority")


func start() -> void:
	set_process(true)
	set_physics_process(true)


func stop() -> void:
	set_process(false)
	set_physics_process(false)


func setup() -> void:
	scene_tree_execution_table.root_node = get_entity_root_node()


func _ready() -> void:
	apply_project_settings()
	get_project_settings()

	stop()
