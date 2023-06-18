# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# player_controller.gd
# SPDX-License-Identifier: MIT

@tool
extends "res://addons/actor/actor_controller.gd"

# Consts
const vr_manager_const = preload("res://addons/sar1_vr_manager/vr_manager.gd")

@export var _target_node_path: NodePath = NodePath()
@onready var _target_node: Node3D = get_node_or_null(_target_node_path)

@export var _target_smooth_node_path: NodePath = NodePath()
@onready var _target_smooth_node: Node3D = get_node_or_null(_target_smooth_node_path)

@export var _camera_controller_node_path: NodePath = NodePath()
@onready var _camera_controller_node: Node3D = get_node_or_null(_camera_controller_node_path)

@export var _player_input_path: NodePath = NodePath()
@onready var _player_input: Node = get_node_or_null(_player_input_path)

@export var _player_interaction_controller_path: NodePath = NodePath()
var _player_interaction_controller: Node = null

@export var _player_teleport_controller_path: NodePath = NodePath()
var _player_teleport_controller: Node = null

@export var _player_info_tag_controller_path: NodePath = NodePath()
var _player_info_tag_controller: Node = null

@export var _player_hand_controller_path: NodePath = NodePath()
var _player_hand_controller: Node = null

@export var _collider_path: NodePath = NodePath()
var _collider: CollisionShape3D = null

@export_flags_3d_physics var local_player_collision: int = 1
@export_flags_3d_physics var other_player_collision: int = 1

@onready var physics_fps: int = ProjectSettings.get_setting("physics/common/physics_ticks_per_second")

@export var ik_space_path: NodePath = NodePath()
var _ik_space: Node3D = null

@export var avatar_loader_path: NodePath = NodePath()
var _avatar_loader: Node = null

@export var avatar_display_path: NodePath = NodePath()
var _avatar_display: Node3D = null

# The offset between the camera position and ARVROrigin center (none transformed)
var frame_offset: Vector3 = Vector3()
var origin_offset: Vector3 = Vector3()

# Movement / Interpolation
var current_origin: Vector3 = Vector3()
var movement_lock_count: int = 0

##################
# Avatar changes #
##################


func get_avatar_display() -> Node3D:
	return _avatar_display


func _update_avatar(p_path: String) -> void:
	_avatar_loader.set_avatar_model_path(p_path)
	_avatar_loader.load_model(false, false)


func _player_network_avatar_path_updated(p_network_id: int, p_path: String) -> void:
	if get_multiplayer_authority() == p_network_id:
		NetworkManager.update_player_avatar_path(get_multiplayer_authority(), p_path)
		_update_avatar(p_path)


func _on_rpc_avatar_path_updated(p_path):
	NetworkManager.update_player_avatar_path(get_multiplayer_authority(), p_path)
	_update_avatar(p_path)


func _local_avatar_path_updated(p_path: String) -> void:
	_update_avatar(p_path)
	get_entity_node().rpc_table_node.rpc("set_avatar_path", p_path)


#################


func _update_noclip_state() -> void:
	if VSKDebugManager.noclip_mode:
		_collider.disabled = true
		_state_machine.noclip = true
	else:
		_collider.disabled = false
		_state_machine.noclip = false


func _noclip_changed() -> void:
	_update_noclip_state()


func lock_movement() -> void:
	movement_lock_count += 1


func unlock_movement() -> void:
	movement_lock_count -= 1
	if movement_lock_count < 0:
		printerr("Player lock underflow!")


func movement_is_locked() -> bool:
	return movement_lock_count > 0 or !InputManager.ingame_input_enabled()


func using_flight_controls() -> bool:
	return VSKDebugManager.noclip_mode


func _master_movement(p_delta: float) -> void:
	_player_input.update_movement_input(_get_desired_direction())

	if _state_machine:
		_state_machine.set_input_magnitude(_player_input.input_magnitude)

		if !movement_is_locked():
			_state_machine.set_input_direction(_player_input.input_direction)
		else:
			_state_machine.set_input_direction(Vector3())

		_state_machine.update(p_delta)


func update_origin() -> void:
	# There is a slight delay in the movement, but this allows framerate independent movement
	if entity_node.hierarchy_component_node and entity_node.hierarchy_component_node.get_entity_parent():
		current_origin = entity_node.global_transform.origin
	else:
		current_origin = entity_node.transform.origin


func set_movement_vector(p_target_velocity: Vector3) -> void:
	super.set_movement_vector(p_target_velocity)
	var transformed_frame_offset: Vector3 = Vector3()
	if _player_input:
		# Get any potential offset (head-position, VR for this frame)
		frame_offset = _player_input.get_head_accumulator()
		transformed_frame_offset = _player_input.transform_origin_offset(frame_offset)
		_player_input.clear_head_accumulator()

		# Compensate for the offset
		origin_offset += frame_offset

	movement_vector += (transformed_frame_offset * physics_fps)


func move(p_movement_vector: Vector3) -> void:
	super.move(p_movement_vector)


func _on_target_smooth_transform_complete(p_delta) -> void:
	if _ik_space and _ik_space.has_method("transform_update"):
		_ik_space.transform_update(p_delta)


func cache_nodes() -> void:
	super.cache_nodes()
	_player_teleport_controller = get_node_or_null(_player_teleport_controller_path)
	_player_info_tag_controller = get_node_or_null(_player_info_tag_controller_path)
	_player_hand_controller = get_node_or_null(_player_hand_controller_path)

	_player_interaction_controller = get_node_or_null(_player_interaction_controller_path)

	_ik_space = get_node_or_null(ik_space_path)

	_avatar_display = get_node_or_null(avatar_display_path)

	_avatar_display.simulation_logic = self

	_avatar_loader = get_node_or_null(avatar_loader_path)

	_collider = get_node_or_null(_collider_path)


func _on_transform_changed() -> void:
	super._on_transform_changed()


func _get_desired_direction() -> Basis:
	var camera_controller_yaw_basis = Basis().rotated(Vector3(0, 1, 0), _camera_controller_node.rotation_yaw)

	var basis: Basis = camera_controller_yaw_basis

	if _camera_controller_node.camera:
		# Movement directions are relative to this. (TODO: refactor)
		match VRManager.vr_user_preferences.movement_orientation:
			VRManager.vr_user_preferences_const.movement_orientation_enum.HEAD_ORIENTED_MOVEMENT:
				basis = camera_controller_yaw_basis * _camera_controller_node.camera.transform.basis
			VRManager.vr_user_preferences_const.movement_orientation_enum.PLAYSPACE_ORIENTED_MOVEMENT:
				basis = camera_controller_yaw_basis
			VRManager.vr_user_preferences_const.movement_orientation_enum.HAND_ORIENTED_MOVEMENT:
				basis = camera_controller_yaw_basis * _player_input.vr_locomotion_component.get_controller_direction()

	if using_flight_controls():
		return Basis(Vector3(-cos(basis.get_euler().y), 0.0, sin(basis.get_euler().y)), Vector3(), Vector3(sin(basis.get_euler().y) * cos(basis.get_euler().x), sin(basis.get_euler().x), cos(basis.get_euler().y) * cos(basis.get_euler().x)))
	else:
		return Basis(Vector3(-cos(basis.get_euler().y), 0.0, sin(basis.get_euler().y)), Vector3(), Vector3(sin(basis.get_euler().y), 0.0, cos(basis.get_euler().y)))


func _on_touched_by_body(p_body) -> void:
	if p_body.has_method("touched_by_body_with_network_id"):
		p_body.touched_by_body_with_network_id(get_multiplayer_authority())


func entity_child_pre_remove(_p_entity_child: Node) -> void:
	pass


func get_attachment_node(p_attachment_id: int) -> Node:
	match p_attachment_id:
		_:
			return _render_node


func get_player_pickup_controller() -> Node:
	return null


func _setup_target() -> void:
	_target_node = get_node_or_null(_target_node_path)
	if _target_node:
		if _target_node == self or not _target_node is Node3D:
			_target_node = null
		else:
			# By default, kinematic body is not affected by its parent's movement
			_target_node.set_as_top_level(true)
			_target_smooth_node.set_as_top_level(true)
			_target_smooth_node.process_priority = EntityManager.process_priority + 1

			current_origin = get_global_transform().origin
			_target_node.global_transform = Transform3D(Basis(), current_origin)
			#_target_smooth_node.global_transform = _target_node.global_transform
		_target_smooth_node.teleport()


func _update_master_transform() -> void:
	var camera_controller_yaw_basis = Basis().rotated(Vector3(0, 1, 0), _camera_controller_node.rotation_yaw)

	set_transform(Transform3D(camera_controller_yaw_basis, get_origin()))


func _master_kinematic_integration_update(_delta: float) -> void:
	move(movement_vector)


func _master_physics_update(p_delta: float) -> void:
	_player_input.update_physics_input()

	_player_input.input_direction = Vector3(0.0, 0.0, 0.0)
	_player_input.input_magnitude = 0.0

	if _player_teleport_controller:
		_player_teleport_controller.check_respawn_bounds()
		_player_teleport_controller.check_teleport()

	if _player_interaction_controller.has_method("update"):
		_player_interaction_controller.update(get_entity_node(), p_delta)

	_master_movement(p_delta)
	_update_master_transform()


func _entity_physics_process(p_delta: float) -> void:
	super._entity_physics_process(p_delta)

	if _ik_space and _ik_space.has_method("update_physics"):
		_ik_space.update_physics(p_delta)

	if is_entity_master():
		_master_physics_update(p_delta)

	update_origin()

	# There is a slight delay in the movement, but this allows framerate independent movement
	if entity_node.hierarchy_component_node and entity_node.hierarchy_component_node.get_entity_parent():
		current_origin = entity_node.global_transform.origin
	else:
		current_origin = entity_node.transform.origin

	if _target_node:
		_target_node.transform.origin = current_origin


func _entity_kinematic_integration_callback(p_delta: float) -> void:
	_master_kinematic_integration_update(p_delta)


func _entity_physics_post_process(p_delta: float) -> void:
	super._entity_physics_post_process(p_delta)


func _master_representation_process(p_delta: float) -> void:
	_player_input.update_representation_input(p_delta)
	_player_input.update_origin(origin_offset + Vector3(0.0, -_avatar_display.height_offset, 0.0))

	if _render_node:
		_render_node.transform.basis = get_transform().basis


func _puppet_representation_process(_delta) -> void:
	_render_node.transform.basis = get_transform().basis


func _master_ready() -> void:
	_update_noclip_state()

	get_entity_node().register_kinematic_integration_callback()

	### Avatar ###
	_update_avatar(VSKPlayerManager.avatar_path)
	if VSKPlayerManager.avatar_path_changed.connect(self._local_avatar_path_updated) != OK:
		push_error("Failed to connect avatar_path_changed signal.")
		return
	###

	_player_input.setup_xr_camera()

	_player_teleport_controller.setup(self)

	if VSKDebugManager.noclip_changed.connect(self._noclip_changed) != OK:
		push_error("Failed to connect noclip_changed signal.")
		return

	if _character_body:
		_character_body.collision_layer = local_player_collision


func _free_master_nodes() -> void:
	if _character_body:
		_character_body.queue_free()

	if _camera_controller_node:
		_camera_controller_node.queue_free()


func _puppet_ready() -> void:
	# Callback for when the first packet is received. If this entity is not
	# owned by the player, wait for the first packet to be received
	_render_node.hide()

	if get_entity_node().network_logic_node:
		if _ik_space.external_trackers_changed.connect(_render_node.show, CONNECT_ONE_SHOT) != OK:
			push_error("Failed to connect external_trackers_changed signal.")
			return

	_state_machine.start_state = NodePath("Networked")

	### Avatar ###
	if VSKNetworkManager.player_avatar_path_updated.connect(self._player_network_avatar_path_updated) != OK:
		push_error("Failed to connect player_avatar_path_updated signal.")
		return
	if VSKNetworkManager.player_avatar_paths.has(get_multiplayer_authority()):
		_update_avatar(VSKNetworkManager.player_avatar_paths[get_multiplayer_authority()])
	###

	_free_master_nodes()


func _entity_representation_process(p_delta: float) -> void:
	super._entity_representation_process(p_delta)

	if is_entity_master():
		_master_representation_process(p_delta)
	else:
		_puppet_representation_process(p_delta)

	entity_node.network_logic_node.set_dirty(true)


func _entity_ready() -> void:
	super._entity_ready()

	# State machine
	if !is_entity_master():
		_puppet_ready()
	else:
		_master_ready()

	_player_info_tag_controller.setup(self)
	_player_hand_controller.setup(self)

	_state_machine.start()

	if _ik_space.has_method("_entity_ready"):
		_ik_space._entity_ready()
	_avatar_display._entity_ready()

	_setup_target()

	# Set the camera controller's initial rotation to be that of entity's rotation
	if _camera_controller_node:
		_camera_controller_node.rotation_yaw = get_transform().basis.get_euler().y


func _threaded_instance_setup(p_instance_id: int, p_network_reader: RefCounted) -> void:
	super._threaded_instance_setup(p_instance_id, p_network_reader)

	_avatar_display._threaded_instance_setup()
