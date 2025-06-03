@tool
extends "res://addons/vsk_entities/extensions/model_simulation_logic.gd"

const vr_constants_const = preload("res://addons/sar1_vr_manager/vr_constants.gd")

@export var hit_sample: AudioStreamWAV = null
@export var hit_velocity: float = 0.25
@export var physics_material: PhysicsMaterial = null

@export var mass: float = 1.0
@export_flags_3d_physics var collison_layers: int = 1
@export_flags_3d_physics var collison_mask: int = 1

var sleeping: bool = false

@export var _render_smooth_path: NodePath = NodePath()
@export var _target_path: NodePath = NodePath()
var _render_smooth: Node3D = null
var _target: Node3D = null

var physics_node_root: RigidBody3D = null

var throw_offset = Vector3(0.0, 0.0, 0.0)
var throw_velocity = Vector3(0.0, 0.0, 0.0)

var prev_linear_velocity_length: float = 0.0


func _network_transform_update(p_transform: Transform3D) -> void:
	super._network_transform_update(p_transform)

	if get_entity_node().hierarchy_component_node.parent_entity_is_valid:
		_target.transform = get_transform()


# Overloaded set_global_origin function which also sets the global transform of the physics node
func set_global_origin(p_origin: Vector3, _p_update_physics: bool = false) -> void:
	super.set_global_origin(p_origin, _p_update_physics)
	if _p_update_physics:
		if physics_node_root:
			physics_node_root.set_global_transform(get_global_transform())


# Overloaded set_transform function which also updates the global transform of the physics node
func set_transform(p_transform: Transform3D, _p_update_physics: bool = false) -> void:
	super.set_transform(p_transform, _p_update_physics)
	if _p_update_physics:
		if physics_node_root:
			physics_node_root.set_transform(get_transform())


# Overloaded set_global_transform function which also sets the global transform of the physics node
func set_global_transform(p_global_transform: Transform3D, _p_update_physics: bool = false) -> void:
	super.set_global_transform(p_global_transform, _p_update_physics)
	if _p_update_physics:
		if physics_node_root:
			physics_node_root.set_global_transform(get_global_transform())


# Change the properties of the rigid body based on whether or not it is parented
func _update_parented_node_state():
	var parent: Node = get_entity_node().hierarchy_component_node.get_entity_parent()

	if (!is_inside_tree()):
		push_error("Error in _update_parented_node_state: node is not inside tree")
		return

	if parent:
		physics_node_root.freeze = true
		physics_node_root.collision_layer = collison_layers
		physics_node_root.collision_mask = 0
		if !Engine.is_editor_hint():
			physics_node_root.set_as_top_level(false)
			physics_node_root.set_transform(Transform3D())

			_render_smooth.set_as_top_level(false)
			_render_smooth.set_enabled(false)
			_render_smooth.set_transform(Transform3D())

			_target.set_as_top_level(false)
			_target.transform = Transform3D()
	else:
		physics_node_root.freeze = false
		physics_node_root.collision_layer = collison_layers
		physics_node_root.collision_mask = collison_mask
		if !Engine.is_editor_hint():
			physics_node_root.set_as_top_level(true)

			# Reset velocity
			physics_node_root.linear_velocity = Vector3()
			physics_node_root.angular_velocity = Vector3()

			physics_node_root.apply_impulse(throw_offset, throw_velocity)
			throw_velocity = Vector3()
			throw_offset = Vector3()

			_render_smooth.set_as_top_level(true)
			_render_smooth.set_enabled(true)

			_target.set_as_top_level(true)
			_target.transform = get_global_transform().orthonormalized()

	# Can fix the glitches without relying on this since it can cause mild snapping?
	_render_smooth._m_trCurr = _target.global_transform
	_render_smooth._m_trPrev = _target.global_transform
	_render_smooth.global_transform = _target.global_transform


# Delete the previous physics node and disconnect associated signals
func _delete_physics_collider_nodes() -> void:
	if physics_node_root:
		for node in physics_node_root.get_children():
			node.queue_free()
			physics_node_root.get_parent().remove_child(node)


func get_physics_node() -> RigidBody3D:
	if !physics_node_root:
		physics_node_root = model_rigid_body_const.new()
		physics_node_root.mass = mass
		physics_node_root.sleeping = sleeping
		physics_node_root.contact_monitor = true
		physics_node_root.max_contacts_reported = 3
		physics_node_root.owner_entity = get_entity_node()
		physics_node_root.physics_material_override = physics_material

		physics_node_root.set_name("Physics")
		if (physics_node_root.body_entered.connect(self._on_body_entered) != OK):
			push_error("Could not connect signal 'physics_node_root.body_entered' at prop_simulation_logic")
			return null
		if (physics_node_root.touched_by_body.connect(self._on_touched_by_body) != OK):
			push_error("Could not connect signal 'physics_node_root.touched_by_body' at prop_simulation_logic")
			return null
		if (physics_node_root.touched_by_body_with_network_id.connect(self._on_touched_by_body_with_network_id) != OK):
			push_error("Could not connect signal 'physics_node_root.touched_by_body_with_network_id' at prop_simulation_logic")
			return null

		get_entity_node().add_child(physics_node_root, true)

	return physics_node_root


# Create a new physics node
func _setup_physics_collider_nodes() -> void:
	for node in physics_nodes:
		physics_node_root.add_child(node, true)

	_update_parented_node_state()


func get_mass() -> float:
	return mass


func set_mass(p_mass: float) -> void:
	mass = p_mass
	if physics_node_root:
		physics_node_root.mass = mass


func _update_physics_nodes() -> void:
	if !Engine.is_editor_hint():
		physics_node_root = get_physics_node()

		_delete_physics_collider_nodes()
		_setup_physics_collider_nodes()


func _on_touched_by_body(p_body) -> void:
	if p_body.has_method("touched_by_body_with_network_id"):
		p_body.touched_by_body_with_network_id(get_multiplayer_authority())


func _on_touched_by_body_with_network_id(p_network_id: int) -> void:
	if NetworkManager.get_current_peer_id() == p_network_id:
		get_entity_node().request_to_become_master()


func is_pickup_valid(_attempting_pickup_controller: Node, _id: int) -> bool:
	return false


func is_drop_valid(_attempting_pickup_controller: Node, _id: int) -> bool:
	return false


func is_grabbable() -> bool:
	return true


func is_interactable() -> bool:
	return true


func _entity_parent_changed() -> void:
	super._entity_parent_changed()

	_update_parented_node_state()


func _on_body_entered(p_body):
	if p_body is CharacterBody3D or p_body is RigidBody3D:
		if p_body != physics_node_root:
			if p_body.has_method("touched_by_body"):
				p_body.touched_by_body(physics_node_root)


func can_request_master_from_peer(_id: int) -> bool:
	return true


func can_transfer_master_from_session_master(_id: int) -> bool:
	return true


func cache_nodes() -> void:
	super.cache_nodes()
	_target = get_node_or_null(_target_path)
	_render_smooth = get_node_or_null(_render_smooth_path)


func _entity_physics_process(p_delta: float) -> void:
	super._entity_physics_process(p_delta)
	if physics_node_root:
		var linear_velocity: Vector3 = physics_node_root.linear_velocity
		var linear_velocity_length: float = linear_velocity.length()

		var colliding_bodies: Array = physics_node_root.get_colliding_bodies()
		if colliding_bodies.size() > 0:
			if hit_sample:
				if prev_linear_velocity_length - linear_velocity_length >= hit_velocity:
					VSKAudioManager.play_oneshot_audio_stream_3d(
						hit_sample, VSKAudioManager.GAME_SFX_OUTPUT_BUS_NAME, get_global_transform()
					)

		prev_linear_velocity_length = linear_velocity_length

		entity_node.network_logic_node.set_dirty(true)


func _entity_representation_process(p_delta: float) -> void:
	super._entity_representation_process(p_delta)
	if physics_node_root and get_entity_node().hierarchy_component_node.get_entity_parent() == null:
		set_transform(physics_node_root.transform)
		if _target:
			_target.transform = physics_node_root.transform
	else:
		if _target:
			_target.transform = Transform3D()


func _entity_ready() -> void:
	if !Engine.is_editor_hint():
		if (model_loaded.connect(self._update_physics_nodes) != OK):
			push_error("Could not connect signal 'model_loaded' at prop_simulation_logic")
			return

	super._entity_ready()

	# model_load signal is triggered before this _entity_ready function, when node is first loaded
	# We must force update here to get _update_physics_nodes to run and setup physics
	# TODO: Investigate a better fix
	schedule_model_update()

	if !Engine.is_editor_hint():
		if _target:
			_target.set_as_top_level(true)
			_target.global_transform = get_entity_node().global_transform

		if _render_smooth:
			_render_smooth.set_as_top_level(true)
			_render_smooth.set_target(_render_smooth.get_path_to(_target))
			_render_smooth.teleport()

		entity_node.hierarchy_component_node.entity_parent_changed.connect(self._entity_parent_changed)
