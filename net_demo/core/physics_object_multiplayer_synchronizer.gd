extends MultiplayerSynchronizer

# Any peer can call this function
@rpc(any_peer, call_local)
func claim_authority() -> void:
	var sender_id: int = multiplayer.get_remote_sender_id()
	if GameManager.is_session_authority(multiplayer.get_unique_id()):
		MultiplayerPhysicsOwnershipTracker.request_authority(self, sender_id)
	
@rpc(any_peer, call_local)
func assign_authority(p_peer_id: int):
	var sender_id: int = multiplayer.get_remote_sender_id()
	if GameManager.is_session_authority(sender_id):
		var physics_body: PhysicsBody3D = get_node(root_path)
		if physics_body:
			physics_body.set_multiplayer_authority(p_peer_id)
			physics_body.pending_authority_request = false
			physics_body.update_color_id_and_material()

func player_spawned(p_peer_id: int) -> void:
	if multiplayer.get_unique_id() == 1:
		if is_multiplayer_authority() and GameManager.is_dedicated_server:
			assert(rpc_id(p_peer_id, "assign_authority", p_peer_id) == OK)
			var physics_body: PhysicsBody3D = get_node(root_path)
			if physics_body:
				physics_body.set_multiplayer_authority(p_peer_id)
		else:
			assert(rpc_id(p_peer_id, "assign_authority", get_multiplayer_authority()) == OK)
		
func player_unspawned(p_peer_id: int) -> void:
	if GameManager.player_list.find(p_peer_id) == -1:
		var physics_body: PhysicsBody3D = get_node(root_path)
		if physics_body:
			if physics_body.get_multiplayer_authority() == p_peer_id:
				physics_body.set_multiplayer_authority(GameManager.get_session_authority())
				physics_body.pending_authority_request = false
				physics_body.update_color_id_and_material()

func _ready():
	assert(GameManager.player_spawned.connect(player_spawned) == OK)
	assert(GameManager.player_unspawned.connect(player_unspawned) == OK)
	
	if get_multiplayer_authority() == 1:
		var physics_body: PhysicsBody3D = get_node(root_path)
		if physics_body:
			physics_body.set_multiplayer_authority(GameManager.get_session_authority())
