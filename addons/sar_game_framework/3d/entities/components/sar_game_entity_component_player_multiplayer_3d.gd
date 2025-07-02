@tool
extends SarGameEntityComponentGameEntityMultiplayer3D
class_name SarGameEntityComponentPlayerMultiplayer3D

# This callback determines if we should add this packets this frame.
# Right now, it only supports the F1 debug key to artificially drop
# frames, but we can hook it into priority system
func _sync_filter(_peer_id: int) -> bool:
	if Input.is_key_pressed(KEY_F1):
		return false
	return true

# Pretty hacky internal method. Since the session authority
# is currently responsible for spawning player entities,
# we want a means to transfer authority to their respective
# peers without an extra round-trip announcing their actual
# authority.
# Unless we want to go the route of writing our own spawner functions,
# this hacks around the problem by using the name of the entity
# as a reference for determining its actual authority.
# We obviously, *can* write our own spawning functions, but I'm
# concerning to prematurely writing too much extra bespoke multiplayer
# code we have to maintain ourselves, so this feels like a decent stopgap.
func _setup_authority() -> void:
	if not SarUtils.assert_true(game_entity, "SarGameEntityComponentPlayerMultiplayer3D: game_entity is not available"):
		return
	
	var game_session_manager: SarGameSessionManager = get_tree().get_first_node_in_group("game_session_managers")
	if not SarUtils.assert_true(game_session_manager, "SarGameEntityComponentPlayerMultiplayer3D: game_session_manager is not available"):
		return
	
	# Use the numbers at the end of the player name to determine the authority.
	# This allows the player scene to go into an auto-spawn list without having to write
	# custom bespoke spawning code which can be fragile and easy to break.
	var id_string: String = game_entity.name.lstrip(game_session_manager.get_player_entity_name_prefix())
	if id_string.is_valid_int():
		game_entity.set_multiplayer_authority(id_string.to_int())
	else:
		push_error("Game entity %s does not conform to the naming convention %s required to determine a user authority upon spawn" % [game_entity.name, game_session_manager.get_player_entity_name_prefix()])
	
	# The MultiplayerSynchronizerSpawn node always explicitly has its authority
	# owned by the host.
	if multiplayer_synchronizer_spawn:
		multiplayer_synchronizer_spawn.set_multiplayer_authority(game_session_manager.get_session_authority_id())

func _enter_tree() -> void:
	if not Engine.is_editor_hint():
		_setup_authority()
		var game_session_manager: SarGameSessionManager = get_tree().get_first_node_in_group("game_session_managers")
		if is_multiplayer_authority():
			# If we have a session manager and we have authority over this node,
			# announce it.
			if game_session_manager:
				game_session_manager.notify_player_vessel_3d_instance_added(game_entity)

func _exit_tree() -> void:
	if not Engine.is_editor_hint():
		if game_entity:
			var game_session_manager: SarGameSessionManager = get_tree().get_first_node_in_group("game_session_managers")
			if game_session_manager:
				# If we have a session manager and we have authority over this node,
				# announce it.
				game_session_manager.notify_player_vessel_3d_instance_removed(game_entity)
