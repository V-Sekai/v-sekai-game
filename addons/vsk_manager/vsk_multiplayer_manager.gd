# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_game_mode_manager.gd
# SPDX-License-Identifier: MIT
@tool
extends Node
##
## This class is responsible for managing Godot multiplayer sessions
## for V-Sekai.
##

##
## This signal is used to provide result callbacks for interacting
## with a multiplayer session.
##
signal multiplayer_callback(p_result, p_args)

##
## This signal is called when a shard is about to registered on
## a master server.
##
signal registering_shard

##
## This signal is fired when we're about to go ingame.
## fade_skipped indicates if we have deliberately skipped
## the crossfade.
##
signal session_ready(fade_skipped)

##
## This signal is fired if we have successfully connected to a session.
##
signal connection_succeeded

##
## This signal is fired if we have failed to connect to a session.
##
signal connection_failed

##
## This signal is fired if the server we are connected to disconnected.
##
signal server_disconnected

##
## This signal is fired if the connection to the server is deliberately
## killed.
##
signal connection_killed

##
## The string we should use for an authoritative server.
##
const AUTHORITATIVE_SERVER_NAME = "authoritative"

##
## The string we should use for an relay server.
##
const RELAY_SERVER_NAME = "relay"

##
## The port number which should be used if none are explicitly set.
##
const DEFAULT_PORT = 7777

##
## The IP address representing your local machine.
##
const LOCALHOST_IP = "127.0.0.1"

##
## ALL_PEERS is a special number indicating that a remote call should
## be sent to all peers.
##
const ALL_PEERS: int = 0

##
## HOST_PEER_ID is the peer id always given the server host.
##
const HOST_PEER_ID: int = 1

##
## The default number of players for a server unless specified otherwise
##
const DEFAULT_MAX_PLAYERS: int = 64

##
## The default number of times to retry establishing a network session
##
const DEFAULT_MAX_RETRIES: int = 0

##
## The name given to a server if no name is provided.
##
const DEFAULT_SERVER_NAME: String = "V-Sekai Server"

##
## The group nodes which can act as spawners is called.
##
const NETWORK_SPAWNER_GROUP_NAME: String = "NetworkSpawnGroup"

##
## The scene representing the player controller.
##
const PLAYER_SCENE: PackedScene = preload("res://addons/vsk_entities/vsk_player.tscn")

##
## Scene representing MultiplayerSpawner responsible for spawning players.
##
const PLAYER_SPAWNER_SCENE: PackedScene = preload("multiplayer/vsk_player_spawner.tscn")

##
## Enum representing the various stages a peer can be during an authentication
## state.
##
enum AuthenticationStage {
	AUTHENTICATING,
	MAP_LOADED,
}

##
## Enum representing results emitted by the multiplayer_callback signal
##
enum MultiplayerCallbackID {
	HOST_GAME_OKAY,
	HOST_GAME_FAILED,
	SHARD_REGISTRATION_FAILED,
	INVALID_MAP,
	NO_SERVER_INFO,
	NO_SERVER_INFO_VERSION,
	SERVER_INFO_VERSION_MISMATCH
}

##
## Feature flag to indicate if we should be using the rewritten multiplayer 
## code. This will eventually be removed when fully migrated to the new system.
##
var use_multiplayer_manager: bool = false

##
## Flag indicates if currently hosted server advertising its presence to an
## external shard master server.
##
var advertised_server = false

##
## This dictionary tracks the current authentication state of peers who
## have not fully authenticated.
##
var _authentication_peers_state_table: Dictionary = {}

##############
### Shards ###
##############

##
## Timer to send a heartbeat command to backend shard in order to keep it alive.
##
var _shard_heartbeat_timer: Timer = null

##
## The amount of time (in seconds) required to elapse before sending a shard
## heartbeat request to keep it alive.
##
var _shard_heartbeat_frequency: float = 10.0  # In seconds

##
## ID assigned from central shard master server
##
var _shard_id: String = ""

###

##
## Root containing the currently active game session.
## Assigned by setup_multiplayer method.
##
var _gameroot: Node = null

##
## Flag indicating if the current server is a dedicated server.
##
var _is_dedicated_server: bool = false

##
## This is the spawner responsible for the player scenes
##
var _player_spawner: MultiplayerSpawner = null

##
## The current map path being used by this session.
##
var _current_map_path: String = ""

##
## The current map instance being used by this session.
##
var _current_map_instance: Node = null

##
## Timer to send a heartbeat command via the authentication channel.
##
var _auth_heartbeat_timer: Timer = null

##
## The amount of time (in seconds) required to elapse before sending a shard
## heartbeat request to keep it alive.
##
var _auth_heartbeat_frequency: float = 5.0  # In seconds

##
## A list of currently connected peers.
##
var _peers: Array = []

##
## Returns true if we have an active network session.
##
func _is_session_alive() -> bool:
	if _has_active_peer():
		return true

	return false

##
## This method is called by the shard heartbeat timer when it times out. It will
## attempt to yield and send a heartbeat command to the centeral server to keep
## the shard alive and then reset the timer to value set in
## 'shard_heartbeat_frequency'
##
func _shard_heartbeat_timer_timeout() -> void:
	if _is_session_alive():
		var shard_callback: Dictionary = await VSKShardManager.shard_heartbeat(_shard_id)
		if shard_callback["result"] == OK:
			if _is_session_alive() and advertised_server:
				_shard_heartbeat_timer.start(_shard_heartbeat_frequency)
		else:
			printerr("Shard heartbeat failed!")
			
##
## If the shard is active, attempt to send a kill command to the server
##
func _attempt_to_kill_shard() -> void:
	if not _shard_id.is_empty():
		_shard_heartbeat_timer.stop()

		var shard_id_pending_deletion: String = _shard_id

		_shard_id = ""

		var shard_response: Dictionary = await VSKShardManager.delete_shard(Callable(), shard_id_pending_deletion)
		if shard_response["result"] == OK:
			print("Shard %s deleted sucessfully!" % shard_id_pending_deletion)
		else:
			print("Shard %s failed to delete!" % shard_id_pending_deletion)

##
## This method is called by the auth heartbeat timer when it times out. It will
## attempt to send an empty auth command to the host just to so they know
## the peer is still connected.
##
func _auth_heartbeat_timer_timeout() -> void:
	assert(!_is_server())
	
	if _is_session_alive():
		assert(get_tree().get_multiplayer().send_auth(HOST_PEER_ID, _encode_auth_message_buffer({})) == OK)
		_auth_heartbeat_timer.start(_auth_heartbeat_frequency)

##
## Returns a PackedByteArray representing an authentication message used
## to establish a handshake between the peer and the server.
## p_auth_dictionary is a dictionary containing the key/value pairs to
## used to encode the PackedByteArray.
##
static func _encode_auth_message_buffer(p_auth_dictionary: Dictionary) -> PackedByteArray:
	var stream_peer_buffer := StreamPeerBuffer.new()
	stream_peer_buffer.put_var(p_auth_dictionary)
	
	return stream_peer_buffer.data_array
	
##
## Returns a dictionary representing an authentication message used
## to establish a handshake between the peer and the server.
## p_auth_pba is a PackedByteArray representing the dictionary of
## key/value pairs which it will decoded into.
##
static func _decode_auth_message_buffer(p_auth_pba: PackedByteArray) -> Variant:
	var stream_peer_buffer: StreamPeerBuffer = StreamPeerBuffer.new()
	stream_peer_buffer.data_array = p_auth_pba
	
	return stream_peer_buffer.get_var()

##
## The function is the callback for when the Multiplayer object exchanges
## buffers containing authentication handshake information.
##
func _auth_callback(p_sender_id: int, p_buffer: PackedByteArray) -> void:
	var buffer_var: Variant = _decode_auth_message_buffer(p_buffer)
	var auth_dict: Dictionary = {}
	
	# Check to see if we received a valid dictionary
	if buffer_var is Dictionary:
		auth_dict = buffer_var
	else:
		if _is_server():
			force_disconnect()
			printerr("Received invalid authentication message from host! Disconnecting!")
		else:
			multiplayer.disconnect_peer(p_sender_id)
			printerr("Received invalid authentication message from peer %s! Disconnecting!"
			% str(p_sender_id))
	
	if p_sender_id == HOST_PEER_ID:
		# The authentication message is coming from the host.
		
		if !_is_server():
			var new_map_path: String = ""
			
			# Simple heartbeat pong from host. Do nothing.
			if auth_dict.is_empty():
				return
			
			# Check if the dictionary has a map_path.
			if auth_dict.has("map_path"):
				new_map_path = auth_dict["map_path"]
				
				# If we do not currently have the map loaded,
				# attempt to load it.
				if new_map_path != VSKMapManager.get_current_map_path():
					if new_map_path != VSKMapManager.get_pending_map_path():
						VSKMapManager.cancel_map_load()
						if new_map_path:
							VSKMapManager.request_map_load(new_map_path, false, false)
						else:
							force_disconnect()
				else:
					_auth_heartbeat_timer.stop()
					
					# I don't think we need to send anymore auth messages now...
					
					var result: Error = multiplayer.complete_auth(p_sender_id)
					if result != OK:
						printerr("multiplayer.complete_auth error code %s!" % str(result))
	else:
		if _is_server():
			var peer_map_path: String = ""
			
			# Simple heartbeat ping from peer. Send an empty dictionary in
			# response.
			if auth_dict.is_empty():
				assert(get_tree().get_multiplayer().send_auth(p_sender_id, _encode_auth_message_buffer({})) == OK)
				return
			
			if auth_dict.has("map_path"):
				peer_map_path = auth_dict["map_path"]
				if peer_map_path == VSKMapManager.get_pending_map_path():
					print("Peer had loaded the correct map %s." % peer_map_path)
					
					_authentication_peers_state_table[p_sender_id] = AuthenticationStage.MAP_LOADED
					assert(get_tree().get_multiplayer().send_auth(p_sender_id, _encode_auth_message_buffer(auth_dict)) == OK)
					
					var result: Error = multiplayer.complete_auth(p_sender_id)
					if result != OK:
						printerr("multiplayer.complete_auth error code %s!" % str(result))
				else:
					printerr("Peer's map path does not match peer: %s / host: %s!"
					% [peer_map_path, VSKMapManager.get_current_map_path()])
					
					# TODO: instead of disconnecting the peer, send another message
					# with the correct map path.
					
					multiplayer.disconnect_peer(p_sender_id)
			
###
### Returns a boolean indicating if a multiplayer sessions is active.
###
func _has_active_peer() -> bool:
	return multiplayer and multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_DISCONNECTED

###
###  Returns a boolean indicating if the peer is currently the server.
###
func _is_server() -> bool:
	return (!_has_active_peer()) or (multiplayer.is_server())
	
###
### Resets all variables tracking the state of the current session to default
###
func _reset_session_data() -> void:
	_is_dedicated_server = false
	
	_peers = []
	_authentication_peers_state_table = {}
##
## Returns a Transform3D representing the global_transform of a randomly
## selected node in the NETWORK_SPAWNER_GROUP_NAME group or Transform3D
## if not spawn points could be found.
## 
func _get_random_spawn_point() -> Transform3D:
	var spawn_point_transform: Transform3D = Transform3D()
	
	var spawn_points: Array = get_tree().get_nodes_in_group(NETWORK_SPAWNER_GROUP_NAME)
	if spawn_points.size() > 0:
		spawn_point_transform = spawn_points[randi_range(0, spawn_points.size()-1)].global_transform

	return spawn_point_transform

##
## Spawns a player scene for the associated 'p_id'
##
func _spawn_player(p_id: int) -> void:
	var player_instance: Node3D = PLAYER_SCENE.instantiate()
	
	assert(player_instance)
	
	player_instance.name = "Player_" + str(p_id)
	player_instance.global_transform = _get_random_spawn_point()
	
	var node_to_spawn_on: Node = _player_spawner.get_node_or_null(_player_spawner.spawn_path)
	assert(node_to_spawn_on)
	
	node_to_spawn_on.add_child(player_instance)
	player_instance.set_multiplayer_authority(p_id)
	
##
## Despawn a player scene for the associated 'p_id'
##
func _despawn_player(p_id: int) -> void:
	var node_to_despawn_on: Node = _player_spawner.get_node_or_null(_player_spawner.spawn_path)
	assert(node_to_despawn_on)
	
	var player_instance: Node3D = node_to_despawn_on.get_node_or_null("Player_" + str(p_id))
	
	if player_instance:
		player_instance.queue_free()
		if player_instance.is_inside_tree():
			player_instance.get_parent().remove_child(player_instance)

##
## Instantiates the current map and caches it in the
## _current_map_instance variable.
##
func _instantiate_and_cache_map_task() -> void:
	var instance_map_result: Dictionary = await VSKMapManager.instance_map(false)
	
	_current_map_instance = instance_map_result["node"]
	_current_map_path = instance_map_result["path"]

##
## Spawns the currently loaded map.
##
func _spawn_map() -> void:
	# TODO - revise VSKMapManager to have better interface.
	var _instantiate_and_cache_map_task_id: int = await WorkerThreadPool.add_task(
		_instantiate_and_cache_map_task,
		true,
		"_instantiate_and_cache_map_task")
	
	var task_result: Error = await WorkerThreadPool.wait_for_task_completion(_instantiate_and_cache_map_task_id)
	if task_result == OK:
		VSKMapManager.set_current_map(_current_map_path, _current_map_instance)

############################
### VSKGameflow Callbacks ##
############################

##
## Callback from the gameflow manager that the server has been successfully
## hosted
##
func _server_hosted() -> void:
	if advertised_server:
		_shard_heartbeat_timer.start(_shard_heartbeat_frequency)
	await VSKMapManager.request_map_load(VSKGameFlowManager.multiplayer_request.map_path, false, false)  # Warning, this skips all validation on localhosted maps
	# TODO - add validation for if the map load request was successful
	
##
## Callback function from the gameflow manager indicating that a map has loaded.
##
func _map_loaded() -> void:
	print("_map_loaded")
	
	#server_state_initialising.emit()
	
	var skipped: bool = await VSKFadeManager.execute_fade(VSKFadeManager.FadeState.FADE_OUT).fade_complete

	await _spawn_map()
	
	if _is_server():
		if !_is_dedicated_server:
			await _spawn_player(HOST_PEER_ID)
	
		session_ready.emit(skipped)
	else:
		var auth_dict: Dictionary = {
			"map_path":VSKMapManager.get_pending_map_path()
		}
		
		assert(get_tree().get_multiplayer().send_auth(HOST_PEER_ID, _encode_auth_message_buffer(auth_dict)) == OK)
		
##
## Callback function from the gameflow manager indicating that the application
## is about to close.
##
func _is_quitting() -> void:
	force_disconnect()
	
#################################
### SceneMultiplayer callbacks ##
#################################
	
func _peer_authenticating(p_peer_id: int) -> void:
	print("_peer_authenticating: %s" % p_peer_id)
	
	if _is_server():
		_authentication_peers_state_table[p_peer_id] = AuthenticationStage.AUTHENTICATING
		
		var auth_dict: Dictionary = {
			"map_path":VSKMapManager.get_pending_map_path()
		}
		
		assert(get_tree().get_multiplayer().send_auth(
			p_peer_id,
			_encode_auth_message_buffer(auth_dict)) == OK)
	else:
		_auth_heartbeat_timer.start()
			
func _peer_authentication_failed(p_peer_id: int) -> void:
	print("_peer_authentication_failed: %s" % p_peer_id)
	if _is_server():
		_authentication_peers_state_table.erase(p_peer_id)
	else:
		_auth_heartbeat_timer.stop()
	
################################
### Multiplayer API callbacks ##
################################
	
##
## Callback function from the multiplayer API indicating that a server
## connection was successfully established.
##
func _on_connected_to_server() -> void:
	connection_succeeded.emit()
	session_ready.emit(false)

##
## Callback function from the multiplayer API indicating that a connection
## failed.
##
func _on_connection_failed() -> void:
	connection_failed.emit()

##
## Callback from the multiplayer API that a peer has disconnected from the 
## session.
## p_id is the session id of the peer who just connected.
##
func _on_peer_connected(p_id: int) -> void:
	_peers.append(p_id)
		
	if _is_server():
		if _authentication_peers_state_table.has(p_id):
			_authentication_peers_state_table.erase(p_id)
			
		_spawn_player(p_id)
	
##
## Callback from the multiplayer API that a peer has disconnected from the 
## session.
## p_id is the session id of the peer who just disconnected.
##
func _on_peer_disconnected(p_id: int) -> void:
	if _is_server():
		_despawn_player(p_id)
		
	_peers.erase(p_id)
		
##
## Callback from the multiplayer API that the server has disconnected.
##
func _on_server_disconnected() -> void:
	force_disconnect()

	server_disconnected.emit()
	
func _ready() -> void:
	apply_project_settings()
	get_project_settings()
		
##
## Forces the current networking session to be terminated.
##
func force_disconnect():
	if _has_active_peer():
		print("Closing connection...")
		if get_tree().get_multiplayer().has_multiplayer_peer():
			get_tree().get_multiplayer().get_multiplayer_peer().close()
			get_tree().get_multiplayer().set_multiplayer_peer(null)
			
		# Clear all the player instances for this session.
		var node_to_clear: Node = _player_spawner.get_node_or_null(_player_spawner.spawn_path)
		if node_to_clear:
			for instance in node_to_clear.get_children():
				instance.queue_free()
				node_to_clear.remove_child(instance)

	_reset_session_data()
	
	_attempt_to_kill_shard()
	
	_auth_heartbeat_timer.stop()

	connection_killed.emit()
		
##
## Host a new networked session.
## p_server_name The name of hte server to displayed in any public master servers.
## p_map_path is the url of the session's map.
## p_game_mode_path is the url to the data file containing information about the
## sessions' currently active game mode (currently used)
## p_port is the UDP port number.
## p_max_players is the maximum number of peers which are allowed to connect.
## p_dedicated_server tells us whether we should enter the server as a player
## once hosted.
## p_advertised tells us whether we should advertise the presence of this server
## to an external shard master server.
## p_retry_max amount of attempts to create the server.
## Returns enum Error
##
func host_game(p_server_name: String, p_map_path: String, _p_game_mode_path: String, p_port: int, p_max_players: int, p_dedicated_server: bool, p_advertise: bool, p_retry_max: int) -> void:
	if p_port < 0:
		p_port = DEFAULT_PORT
		
	advertised_server = false
		
	var peer: MultiplayerPeer = ENetMultiplayerPeer.new()
	
	# Attempt to create the server for the amount of times specified by
	# p_retry_max.
	var result: Error = FAILED
	var retry_count = 0
	while true:
		result = peer.create_server(p_port, p_max_players)
		if result == OK:
			break
		if (retry_count % 10) == 0:
			print("Cannot create a server on port {port}! (Try {try}/{trymax})".format({"port": str(p_port), "try": str(retry_count), "trymax": str(p_retry_max)}))
		retry_count += 1
		if retry_count > p_retry_max:
			break
		OS.delay_msec(100)
	
	if result == OK:
		multiplayer.multiplayer_peer = peer
		_is_dedicated_server = p_dedicated_server
		
		multiplayer.server_relay = multiplayer.multiplayer_peer.is_server_relay_supported()
		
		advertised_server = p_advertise
		
		var shard_response: Dictionary = {"result": OK, "data": {}}
		if advertised_server:
			registering_shard.emit()
			shard_response = await VSKShardManager.create_shard(Callable(), p_port, p_map_path, p_server_name, 0 if p_dedicated_server else 1, p_max_players)
		
		_shard_id = ""
		if shard_response["result"] == OK:
			if shard_response["data"].has("id"):
				_shard_id = shard_response["data"]["id"]
			if _is_session_alive():
				multiplayer_callback.emit(MultiplayerCallbackID.HOST_GAME_OKAY, {})
				return
		else:
			multiplayer_callback.emit(MultiplayerCallbackID.SHARD_REGISTRATION_FAILED, {})
	else:
		multiplayer_callback.emit(MultiplayerCallbackID.HOST_GAME_FAILED, {})
		
##
## Attempts to connect to a networked session.
## p_address is the IP address you are attempting connect to.
## p_port is the UDP port number.
## Returns enum Error
##
func join_game(p_address: String, p_port: int) -> Error:
	var peer = ENetMultiplayerPeer.new()
	var result: Error = peer.create_client(p_address, p_port)
	if result == OK:
		multiplayer.set_multiplayer_peer(peer)
		
	return result

##
## Returns true if the currently you are a dedicated server.
##
func is_dedicated_server() -> bool:
	return _is_dedicated_server

##
## Creates and applies all the project settings associated with this manager.
##
func apply_project_settings() -> void:
	if Engine.is_editor_hint():
		if !ProjectSettings.has_setting("multiplayer/config/use_multiplayer_manager"):
			ProjectSettings.set_setting("multiplayer/config/use_multiplayer_manager", use_multiplayer_manager)
		if ProjectSettings.save() != OK:
			printerr("Could not save project settings!")

##
## Loads all the project settings associated with this manager.
##
func get_project_settings() -> void:
	use_multiplayer_manager = ProjectSettings.get_setting("multiplayer/config/use_multiplayer_manager")

##
## Creates and assigns the multiplayer API in the scene tree and sets up
## all associated callbacks, signals, and nodes.
## p_gameroot is the node representing the toplevel node where the
## multiplayer session will be instantiated and which the spawned player
## scenes will parented to.
func setup_manager(p_gameroot: Node) -> void:
	if !use_multiplayer_manager:
		return
	
	assert(p_gameroot)
	_gameroot = p_gameroot
	
	var _player_root = Node3D.new()
	_player_root.set_name("PlayerRoot")
	_gameroot.add_child(_player_root)
	
	# Assigns the Multiplayer API to the scene tree.
	var multiplayer_api: MultiplayerAPI = SceneMultiplayer.new()
	get_tree().set_multiplayer(multiplayer_api)
	
	# Setup authentication callback and timeout.
	multiplayer_api.auth_timeout = 0.0
	multiplayer_api.set_auth_callback(_auth_callback)
	
	# Sets up the player scene spawner.
	_player_spawner = PLAYER_SPAWNER_SCENE.instantiate()
	_player_spawner.name = "PlayerSpawner"
	_gameroot.add_child(_player_spawner)
	
	# Sets the player spawner root to the gameroot node.
	_player_spawner.spawn_path = _player_spawner.get_path_to(_player_root)
	
	assert(multiplayer_api.peer_authenticating.connect(self._peer_authenticating) == OK)
	assert(multiplayer_api.peer_authentication_failed.connect(self._peer_authentication_failed) == OK)
	
	assert(multiplayer.connected_to_server.connect(self._on_connected_to_server) == OK)
	assert(multiplayer.connection_failed.connect(self._on_connection_failed) == OK)
	assert(multiplayer.peer_connected.connect(self._on_peer_connected) == OK)
	assert(multiplayer.peer_disconnected.connect(self._on_peer_disconnected) == OK)
	assert(multiplayer.server_disconnected.connect(self._on_server_disconnected) == OK)
	
	assert(VSKGameFlowManager.is_quitting.connect(self._is_quitting) == OK)
	assert(VSKGameFlowManager.map_loaded.connect(self._map_loaded) == OK)
	assert(VSKGameFlowManager.server_hosted.connect(self._server_hosted) == OK)

##
## Sets up any required variables for this manager.
##
func setup() -> void:
	if !Engine.is_editor_hint():
		_shard_heartbeat_timer = Timer.new()
		_shard_heartbeat_timer.set_name("ShardHeartbeatTimer")
		add_child(_shard_heartbeat_timer, true)
		
		_auth_heartbeat_timer = Timer.new()
		_auth_heartbeat_timer.set_name("AuthHeartbeatTimer")
		add_child(_auth_heartbeat_timer, true)

		if _shard_heartbeat_timer.timeout.connect(self._shard_heartbeat_timer_timeout) != OK:
			printerr("Failed to connect ShardHeartbeatTimer timeout signal")
			return
			
		if _auth_heartbeat_timer.timeout.connect(self._auth_heartbeat_timer_timeout) != OK:
			printerr("Failed to connect AuthHeartbeatTimer timeout signal")
			return
