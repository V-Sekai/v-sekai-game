extends RigidBody3D

const physics_state_sync_const = preload("res://net_demo/core/physics_state_synchronizer.gd")

@onready var original_transfrom = transform

# These values control how transparent this object should appear when it is
# asleep vs when it's awake.
const AWAKE_STATE_TRANSPARENCY = 0.0
const SLEEP_STATE_TRANSPARENCY = 0.25

# Index into the color table for multiplayer
var multiplayer_color_id: int = -1

# This flag is set if the player tries to gain authority over this rigid body. They will
# ignore incoming updates while it is set and instead act like they have control over it.
# (Currently there is no interface for explicitly requesting ownership, so simulation will
# not match.)
@export var allow_authority_steal_on_touch: bool = true
var pending_authority_request: bool = false


# Function returns if the game is running without a multiplayer peer,
# if the we have explicit authority over this node, or
# we are pending explicit authority over.
func has_authority() -> bool:
	if !multiplayer.has_multiplayer_peer() or is_multiplayer_authority() or pending_authority_request:
		return true
	else:
		return false


func _update_collision() -> void:
	if has_authority():
		set_collision_mask_value(2, true)
		if allow_authority_steal_on_touch:
			set_collision_mask_value(3, true)
		else:
			set_collision_mask_value(3, true)
	else:
		if allow_authority_steal_on_touch:
			set_collision_mask_value(2, true)
			set_collision_mask_value(3, true)
		else:
			set_collision_mask_value(3, false)
			set_collision_mask_value(3, false)


# Applies quantization locally to gain improved simulation consistency between peers
# (currently causes objects to jitter; disabling local quantization during
# sleep state helps a bit, but still needs further investigation).
func _quantize_simulation_locally() -> void:
	var physics_state: physics_state_sync_const.PhysicsState = physics_state_sync_const.PhysicsState.new()
	physics_state.set_from_rigid_body(self)

	physics_state = physics_state_sync_const.PhysicsState.decode_physics_state(physics_state_sync_const.PhysicsState.encode_physics_state(physics_state))

	transform = Transform3D(Basis(physics_state.rotation), physics_state.origin)
	linear_velocity = physics_state.linear_velocity
	angular_velocity = physics_state.angular_velocity


# Sleeping rigid bodies will show up as partially transparent.
func _update_sleep_visualization() -> void:
	if sleeping:
		$MeshInstance3D.transparency = SLEEP_STATE_TRANSPARENCY
	else:
		$MeshInstance3D.transparency = AWAKE_STATE_TRANSPARENCY


func _on_body_entered(p_body: PhysicsBody3D) -> void:
	if allow_authority_steal_on_touch:
		if p_body is CharacterBody3D and p_body.is_multiplayer_authority():
			if p_body.get_multiplayer_authority() != get_multiplayer_authority():
				if !pending_authority_request:
					pending_authority_request = true
					assert($MultiplayerSynchronizer.rpc_id(1, "claim_authority") == OK)


func _physics_process(_delta: float) -> void:
	$MultiplayerSynchronizer.public_visibility = true

	_update_sleep_visualization()

	if (
		(multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED and is_multiplayer_authority())
		or pending_authority_request
	):
		_quantize_simulation_locally()
		$Label3D.text = str(get_tree().get_multiplayer().get_unique_id())
