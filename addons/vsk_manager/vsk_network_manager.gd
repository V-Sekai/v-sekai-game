# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_network_manager.gd
# SPDX-License-Identifier: MIT

@tool
extends Node

###########################
# V-Sekai Network Manager #
###########################

##
## The VSKNetworkManager is a high level interface to the lower level
## general-purpose Network Manager handling things specific to V-Sekai
##

const node_util_const = preload("res://addons/gd_util/node_util.gd")
const entity_const = preload("res://addons/entity_manager/entity.gd")
const network_writer_const = preload("res://addons/network_manager/network_writer.gd")
const scene_tree_execution_table_const = preload("res://addons/entity_manager/scene_tree_execution_table.gd")
const vsk_map_definition_runtime_const = preload("res://addons/vsk_map/vsk_map_definition_runtime.gd")
const vsk_map_entity_instance_record_const = preload("res://addons/vsk_map/vsk_map_entity_instance_record.gd")
const vsk_network_manager_const = preload("res://addons/vsk_manager/vsk_network_manager.gd")
const connection_util_const = preload("res://addons/gd_util/connection_util.gd")

# Determines whether to the server should process the host state
# in a background thread (debugging).
var use_threaded_host_state_initalisation_func: bool = true
# Determines whether the client should process the server state
# in a background thread (debugging).
var use_threaded_received_server_state_func: bool = true

# Unique identifier to determine whether the client and server are on a
# compatible protocol.

# 0.3 - hand gesture IDs added
const NETWORK_MAJOR_VERSION = 0
const NETWORK_MINOR_VERSION = 3
const NETWORK_PROTOCOL_NAME = "vsk"


static func get_vsk_network_version_string() -> String:
	return "%s_v%s.%s" % [NETWORK_PROTOCOL_NAME, str(NETWORK_MAJOR_VERSION), str(NETWORK_MINOR_VERSION)]


# The default number of players for a server unless specified otherwise
const DEFAULT_MAX_PLAYERS = 64

# The default number of times to retry establishing a network session
const DEFAULT_MAX_RETRIES = 0

# The name given to a server if no name is provided.
const DEFAULT_SERVER_NAME = "V-Sekai Server"

# The group nodes which can act as spawners is called.
const NETWORK_SPAWNER_GROUP_NAME = "NetworkSpawnGroup"

# Resource ID for the resource preloader
const RESOURCE_ID_PLAYER_SCENE = 0

# Result IDs emitted by the network_callback signal
enum { HOST_GAME_OKAY, HOST_GAME_FAILED, SHARD_REGISTRATION_FAILED, INVALID_MAP, NO_SERVER_INFO, NO_SERVER_INFO_VERSION, SERVER_INFO_VERSION_MISMATCH }

var advertised_server: bool = false  # Whether this server is to be advertised
# on a backend server.

# Timer to send a heartbeat command to backend shard in order to keep it alive.
var shard_heartbeat_timer: Timer = null
var shard_heartbeat_frequency: float = 10.0  # In seconds


##
## This method is called by the shard heartbeat timer when it times out. It will
## attempt to yield and send a heartbeat command to the centeral server to keep
## the shard alive and then reset the timer to value set in
## 'shard_heartbeat_frequency'
##
func _heartbeat_timer_timout() -> void:
	if is_session_alive():
		VSKShardManager.call_deferred("shard_heartbeat", shard_id)
		# FIXME: Bug because signal returns wrong type
		var shard_callback = await VSKShardManager.shard_heartbeat_callback
		if shard_callback["result"] == OK:
			if is_session_alive() and advertised_server:
				shard_heartbeat_timer.start(shard_heartbeat_frequency)
		else:
			printerr("Shard heartbeat failed!")


var shard_create_callback: RefCounted = RefCounted.new()
var shard_delete_callback: RefCounted = RefCounted.new()


func refresh_shard_callbacks():
	shard_create_callback = RefCounted.new()
	shard_delete_callback = RefCounted.new()


# ID assigned from central shard master server
var shard_id: String = ""
var shard_port: int = 0

# Number of pending tasks
var host_state_tasks: int = 0

# Flag to tell threads that the network session should be killed
var kill_flag: bool = false


func _host_state_task_increment() -> void:
	host_state_tasks += 1


func _host_state_task_decrement() -> void:
	host_state_tasks -= 1

	if host_state_tasks < 0:
		push_error("Error: host state task underflow!")
		host_state_tasks = 0
		return

	if host_state_tasks == 0 and kill_flag:
		NetworkManager.request_network_kill()


# Spatial root containing an active game session, assigned externally by the
# VSKGameflowManager
var gameroot: Node = null

# Thread for handing various client/server state processing tasks.
var state_initialization_thread: Thread = null

# The path to scene file for the player entity
var player_scene_path: String = ""
# The packed scene used for player entities
var player_scene: PackedScene = null

var validated_peers: Array = []

# Dictionaries describing the current active display names and avatars
var player_display_names = {}
var player_avatar_paths = {}

var player_instances: Dictionary = {}

var signal_table: Array = [
	{"singleton": "NetworkManager", "signal": "requested_server_info", "method": "_requested_server_info"},
	{"singleton": "NetworkManager", "signal": "requested_server_state", "method": "_requested_server_state"},
	{"singleton": "NetworkManager", "signal": "create_server_info", "method": "_host_create_server_info"},
	{"singleton": "NetworkManager", "signal": "create_server_state", "method": "_host_create_server_state"},
	{"singleton": "NetworkManager", "signal": "connection_succeeded", "method": "_connection_succeeded"},
	{"singleton": "NetworkManager", "signal": "connection_failed", "method": "_connection_failed"},
	{"singleton": "NetworkManager", "signal": "peer_registered", "method": "_peer_registered"},
	{"singleton": "NetworkManager", "signal": "peer_unregistered", "method": "_peer_unregistered"},
	{"singleton": "NetworkManager", "signal": "peer_list_changed", "method": "_peer_list_changed"},
	{"singleton": "NetworkManager", "signal": "peer_registration_complete", "method": "_peer_registration_complete"},
	{"singleton": "NetworkManager", "signal": "network_peer_packet", "method": "_network_peer_packet"},
	{"singleton": "NetworkManager", "signal": "server_disconnected", "method": "_server_disconnected"},
	{"singleton": "NetworkManager", "signal": "received_server_info", "method": "_received_server_info"},
	{"singleton": "NetworkManager", "signal": "received_server_state", "method": "_received_server_state"},
	{"singleton": "NetworkManager", "signal": "received_client_info", "method": "_received_client_info"},
	{"singleton": "NetworkManager", "signal": "session_data_reset", "method": "_session_data_reset"},
	{"singleton": "NetworkManager", "signal": "connection_killed", "method": "_connection_killed"},
	{"singleton": "NetworkManager", "signal": "peer_became_active", "method": "_peer_became_active"},
	{"singleton": "VSKGameFlowManager", "signal": "is_quitting", "method": "_is_quitting"},
	{"singleton": "VSKGameFlowManager", "signal": "map_loaded", "method": "_map_loaded"},
	{"singleton": "VSKGameFlowManager", "signal": "server_hosted", "method": "_server_hosted"},
	{"singleton": "NetworkManager", "signal": "requesting_server_info", "method": "_requesting_server_info"},
	{"singleton": "NetworkManager", "signal": "requesting_server_state", "method": "_requesting_server_state"},
]

signal network_callback(p_result, p_args)

signal registering_shard

signal host_creating_server_info
signal host_creating_server_state

signal requesting_server_info
signal requesting_server_state

signal server_state_initialising
signal server_state_ready  # Fired before a fadeout

signal session_ready(fade_skipped)  # Fired when we're ready to go ingame

signal connection_succeeded
signal connection_failed
signal server_disconnected

signal connection_killed

signal player_display_name_updated(p_id, p_name)
signal player_avatar_path_updated(p_id, p_name)


##
## If the shard is active, attempt to send a kill command to the server
##
func attempt_to_kill_shard() -> void:
	if not shard_id.is_empty():
		shard_heartbeat_timer.stop()

		var shard_id_pending_deletion: String = shard_id

		shard_id = ""

		refresh_shard_callbacks()
		await VSKShardManager.delete_shard(shard_delete_callback, shard_id_pending_deletion)


##
## Callback from the main network manager telling us the connection has successfully shutdown
##
func _connection_killed() -> void:
	attempt_to_kill_shard()
	destroy_all_entities()
	kill_flag = false

	clear_all_player_display_names()
	clear_all_player_avatar_paths()
	clear_all_validated_peers()

	connection_killed.emit()


##
## Returns true if we have an active network session in the NetworkManager
##
func is_session_alive() -> bool:
	if !kill_flag:
		if NetworkManager.has_active_peer():
			return true

	return false


##
## Loops through all active entities and deletes them.
##
func destroy_all_entities() -> void:
	EntityManager.scene_tree_execution_table.cancel_scene_tree_execution_table()

#	 Clear all in-built networked entities out of the map
	var entities = get_tree().get_nodes_in_group("NetworkedEntities")
	for entity in entities:
		entity.queue_free()
		entity.get_parent().remove_child(entity)


##
## Ends the current network session
##
func force_disconnect():
	kill_flag = true
	if host_state_tasks == 0:
		NetworkManager.request_network_kill()


##
## Searches for a spawn location from the list and returns a transform.
## p_spawners should be an array of spatial nodes
## Returns the Transform3D for a random location to use for spawning
##
func get_random_spawn_transform_for_spawners(p_spawners: Array) -> Transform3D:
	var spawn_location = Transform3D()

	if p_spawners.size() > 0:
		var spawn_index = randi() % p_spawners.size()
		var spawner: Node3D = p_spawners[spawn_index]
		if spawner:
			if spawner.is_inside_tree():
				spawn_location = spawner.global_transform
			else:
				spawn_location = node_util_const.get_relative_global_transform(gameroot, spawner)
		else:
			var node: Node = p_spawners[spawn_index]
			if node:
				print("Node %s is invalid!" % node.get_name())
			else:
				printerr("Invalid spawner!")

	return spawn_location


func get_random_spawn_transform() -> Transform3D:
	var spawn_nodes: Array = get_tree().get_nodes_in_group(NETWORK_SPAWNER_GROUP_NAME)
	return get_random_spawn_transform_for_spawners(spawn_nodes)


##
## Instantiates a player scene, usually called by the server host when
## a peer is about to enter the server.
## p_master_id is network id for the client we're creating this player scene for.
## Returns the node for the player scene
##
func add_player_scene(p_master_id: int) -> Node:
	print("Adding player scene for {master_id}...".format({"master_id": str(p_master_id)}))

	if !player_instances.has(p_master_id):
		var instantiate: Node = EntityManager.instantiate_entity_and_setup(player_scene, {"avatar_path": VSKPlayerManager.avatar_path}, "NetEntity_Player_{master_id}".format({"master_id": str(p_master_id)}), p_master_id)

		player_instances[p_master_id] = instantiate

		if instantiate == null:
			printerr("Could not instantitate player!")

		return instantiate
	else:
		printerr("Attempted to add duplicate client player scene!")
		return null


## Destroys a player scene, usually called by the server host when a peer
## is leaving the server.
## p_master_id is network id for the client we're creating this player scene for.
##
func remove_player_scene(p_master_id: int) -> void:
	print("Removing player scene for {master_id}...".format({"master_id": str(p_master_id)}))

	if not player_instances.has(p_master_id):
		printerr("Attempted to remove unrecorded client player scene!")
		return

	var instantiate: Node = player_instances[p_master_id]
	player_instances.erase(p_master_id)
	EntityManager._delete_entity_unsafe(instantiate)


##
## Destroys all the player scene instances, called as part of the cleanup phase.
##
func clear_all_player_scenes() -> void:
	print("_clear_all_player_scenes")

	for key in player_instances.keys():
		remove_player_scene(key)


##
## Returns the EntityRef for the player instantiate of the corresponding network ID
##
func get_player_instance_ref(p_network_id: int) -> EntityRef:
	if player_instances.has(p_network_id):
		return player_instances[p_network_id].get_entity_ref()
	else:
		return null


##
## Returns a dictionary containing EntityRefs for all the valid player instances
##
func get_all_player_instance_refs() -> Dictionary:
	var player_dictionary: Dictionary = {}
	for key in player_instances.keys():
		player_dictionary[key] = player_instances[key].get_entity_ref()

	return player_dictionary


##
## Callback function to the NetworkManager, called when the session data
## in the NetworkManager is cleared, usually when the session is disconnected.
##
func _session_data_reset() -> void:
	print("_session_data_reset")

	clear_all_player_scenes()
	clear_all_player_display_names()
	clear_all_player_avatar_paths()
	clear_all_validated_peers()


##
## Assigns the display name for a new peer.
## p_master_id is the network id for the peer.
## p_display_name is the corresponding display name to be assigned to this peer.
## Returns true if the display name was successfully added.
##
func update_player_display_name(p_master_id: int, p_display_name: String) -> void:
	print("Adding player display name for {master_id}...".format({"master_id": str(p_master_id)}))

	player_display_names[p_master_id] = p_display_name
	player_display_name_updated.emit(p_master_id, p_display_name)


##
## Removes the display name for a corresponding peer.
## p_master_id is the network id for the peer.
##
func remove_player_display_name(p_master_id: int) -> void:
	print("Removing player display name for {master_id}...".format({"master_id": str(p_master_id)}))

	if player_display_names.has(p_master_id):
		player_display_names.erase(p_master_id)
	else:
		printerr("Attempted to remove unrecorded client display name!")


##
## Removes all of the player display names
##
func clear_all_player_display_names() -> void:
	print("Clearing all player display names")

	for key in player_display_names.keys():
		remove_player_display_name(key)


##
## Removes all of the validated peers
##
func clear_all_validated_peers() -> void:
	print("Clearing all validated peers")

	validated_peers = []


##
## Returns true if currently running as a dedicated
##


func is_dedicated_server() -> bool:
	return NetworkManager.server_dedicated


##
## Assigns the avatar path for a new peer.
## p_master_id is the network id for the peer.
## p_avatar_path is the corresponding avatar path to be assigned to this peer.
##
func update_player_avatar_path(p_master_id: int, p_avatar_path: String) -> void:
	print("Adding player avatar path for {master_id}...".format({"master_id": str(p_master_id)}))

	player_avatar_paths[p_master_id] = p_avatar_path
	player_avatar_path_updated.emit(p_master_id, p_avatar_path)


##
## Removes the avatar path for a corresponding peer.
## p_master_id is the network id for the peer.
##
func remove_player_avatar_path(p_master_id: int) -> void:
	print("Removing player avatar path for {master_id}...".format({"master_id": str(p_master_id)}))

	if player_avatar_paths.has(p_master_id):
		player_avatar_paths.erase(p_master_id)
	else:
		printerr("Attempted to remove unrecorded client avatar path!")


##
## Removes all of the player avatar paths
##
func clear_all_player_avatar_paths() -> void:
	print("Clearing all player avatar paths")

	for key in player_avatar_paths.keys():
		remove_player_avatar_path(key)


##
## Callback function for when a map has been loaded.
##
func _map_loaded() -> void:
	print("_map_loaded")

	if NetworkManager.get_current_peer_id() == NetworkManager.network_constants_const.SERVER_MASTER_PEER_ID:
		NetworkManager.send_create_server_state()
	else:
		NetworkManager.client_request_server_state({})


func _requesting_server_info() -> void:
	print("_requesting_server_info")

	requesting_server_info.emit()


func _requesting_server_state() -> void:
	print("_requesting_server_state")

	requesting_server_state.emit()


##########
# Server #
##########


##
## Callback from the gameflow manager that the server has been successfully hosted
##
func _server_hosted() -> void:
	if advertised_server:
		shard_heartbeat_timer.start(shard_heartbeat_frequency)
	NetworkManager.send_create_server_info()


##
## Host a new networked session.
## p_map_path is the url of the session's map.
## p_port is the UDP port number.
## p_max_players is the maximum number of peers which are allowed to connect.
## p_dedicated_server tells us whether we should enter the server as a player
## once hosted.
## p_advertised tells us whether we should advertise the presence of this server
## to an external shard master server.
## Returns enum Error
##
func host_game(p_server_name: String, p_map_path: String, p_game_mode_path: String, p_port: int, p_max_players: int, p_dedicated_server: bool, p_advertise: bool, p_retry_count: int) -> void:
	if p_port < 0:
		p_port = NetworkManager.default_port

	advertised_server = p_advertise

	print("VSKNetworkManager: TODO: add support for game mode path %s" % p_game_mode_path)

	if NetworkManager.host_game(p_port, p_max_players, p_dedicated_server, false, p_retry_count):
		var shard_callback: Dictionary = {"result": OK, "data": {}}
		if advertised_server:
			registering_shard.emit()
			refresh_shard_callbacks()
			VSKShardManager.call_deferred("create_shard", shard_create_callback, p_port, p_map_path, p_server_name, 0 if p_dedicated_server else 1, p_max_players)
			# FIXME: Godot bug with signal return type.
			var tmp = await VSKShardManager.shard_create_callback
			shard_callback = tmp

		shard_id = ""
		if shard_callback["result"] == OK:
			if shard_callback["data"].has("id"):
				shard_id = shard_callback["data"]["id"]
			shard_port = p_port
			if is_session_alive():
				NetworkManager.session_master = NetworkManager.network_constants_const.SERVER_MASTER_PEER_ID
				network_callback.emit(HOST_GAME_OKAY, {})
				return
		else:
			network_callback.emit(SHARD_REGISTRATION_FAILED, {})
	else:
		network_callback.emit(HOST_GAME_FAILED, {})


##
## Callback function for when the host has created the server info,
## infrequently changing data describing the server such as the current map.
##
func _host_create_server_info() -> void:
	print("_host_create_server_info")

	host_creating_server_info.emit()
	await VSKMapManager.request_map_load(VSKGameFlowManager.multiplayer_request.map_path, false, false)  # Warning, this skips all validation on localhosted maps


## Called when server has initialised their host state. Called from the main thread.
## p_instances contains ['map'] and ['players'], map containing the instantiate
## map scene, and players contains a list player instances, assigns them random
## spawn locations and dispatches the scene tree execution command to add them to
## the tree. The NetworkManager is then told to start sending state data to clients.
## p_fade_skipped tells us whether the crossfade transitioning to this state was
## skipped.
##
func _host_setup_map(p_instances: Dictionary, p_fade_skipped: bool) -> void:
	print("_host_setup_map")

	if not is_session_alive():
		return

	if not p_instances["map"]:
		printerr("Could not instantiate map!")
		network_callback.emit(INVALID_MAP, {})
		return

	VSKMapManager._set_current_map_unsafe(p_instances["map"])
	var players: Array = p_instances["players"]
	var spawn_nodes = node_util_const.find_nodes_in_group(NETWORK_SPAWNER_GROUP_NAME, p_instances["map"])
	for player_instance in players:
		if not player_instance:
			continue
		var transform: Transform3D = get_random_spawn_transform_for_spawners(spawn_nodes)
		player_instance.transform = transform

		EntityManager.scene_tree_execution_command(scene_tree_execution_table_const.ADD_ENTITY, player_instance)

	EntityManager.scene_tree_execution_table._execute_scene_tree_execution_table_unsafe()
	# Tell the server it is now safe to send server state
	# to connected peers
	NetworkManager.confirm_server_state_ready()
	session_ready.emit(p_fade_skipped)


##
##
##
func _host_state_complete(p_instances: Dictionary) -> void:
	if is_session_alive():
		if p_instances["map"]:
			server_state_ready.emit()
			var skipped: bool = await VSKFadeManager.execute_fade(false).fade_complete
			_host_setup_map(p_instances, skipped)
		else:
			network_callback.emit(INVALID_MAP, {})


##
##
##
func _host_state_instance() -> Dictionary:
	var instanced_nodes: Dictionary = {}
	var map_instance: Node = VSKMapManager.instance_map(false)

	var new_player_instances: Array = []
	if map_instance and map_instance is vsk_map_definition_runtime_const:
		VSKMapManager.instance_embedded_map_entities(map_instance, [player_scene_path])

		if !NetworkManager.server_dedicated:
			# Create player instance for server if server is not a
			# dedicated server
			var player_instance: Node = add_player_scene(NetworkManager.network_constants_const.SERVER_MASTER_PEER_ID)

			new_player_instances.push_back(player_instance)

	instanced_nodes["map"] = map_instance
	instanced_nodes["players"] = new_player_instances

	return instanced_nodes


##
## Called in the main thread once the host_state_initialization thread function
## has completed.
##
func _threaded_host_state_initialization_complete() -> void:
	var instances = state_initialization_thread.wait_to_finish()

	print("_threaded_host_state_initialization_complete")

	await _host_state_complete(instances)

	_host_state_task_decrement()


##
## Threaded function for processing the host state. Mostly used for instancing
## map and entities.
##
func _threaded_host_state_initialization_func() -> Dictionary:
	print("_threaded_host_state_initialization_func")

	var instanced_nodes: Dictionary = _host_state_instance()

	call_deferred("_threaded_host_state_initialization_complete")
	return instanced_nodes


func _unthreaded_host_state_initialization_func() -> void:
	print("_unthreaded_host_state_initialization_func")

	var instanced_nodes: Dictionary = _host_state_instance()
	await get_tree().process_frame
	_host_state_complete(instanced_nodes)

	_host_state_task_decrement()


func _host_create_server_state() -> void:
	print("_host_create_server_state")

	host_creating_server_state.emit()
	NetworkManager.network_entity_manager.reset_server_instances()

	if !is_session_alive():
		return

	server_state_initialising.emit()

	_host_state_task_increment()
	if use_threaded_host_state_initalisation_func:
		if state_initialization_thread.start(_threaded_host_state_initialization_func) != OK:
			_host_state_task_decrement()
			printerr("Could not start 'state_initialization_thread' thread'")
	else:
		call_deferred("_unthreaded_host_state_initialization_func")


func _requested_server_info(p_network_id: int) -> void:
	print("_requested_server_info")

	var server_info: Dictionary = NetworkManager.get_default_server_info()

	server_info["version"] = (vsk_network_manager_const.get_vsk_network_version_string() + "_" + NetworkManager.get_network_version_string())
	server_info["map_path"] = VSKMapManager.get_current_map_path()
	server_info["game_mode_path"] = VSKGameModeManager.get_current_game_mode_path()

	NetworkManager.server_send_server_info(p_network_id, server_info)


##########################
# Requested Server State #
##########################


func _threaded_requested_server_state_complete(p_thread: Thread, p_network_id: int) -> void:
	var player_instance: Node = p_thread.wait_to_finish()

	print("_threaded_requested_server_state_complete")

	if is_session_alive():
		player_instance.transform = get_random_spawn_transform()

		EntityManager.scene_tree_execution_command(scene_tree_execution_table_const.ADD_ENTITY, player_instance)

		EntityManager.scene_tree_execution_table._execute_scene_tree_execution_table_unsafe()

		if NetworkManager.network_replication_manager.connect("spawn_state_for_new_client_ready", self._server_state_ready_to_send) == OK:
			NetworkManager.network_replication_manager.create_spawn_state_for_new_client(p_network_id)
		else:
			printerr("Could not connect spawn_state_for_new_client_ready!")

	_host_state_task_decrement()


func _threaded_requested_server_state_func(p_userdata) -> Node:
	print("_threaded_requested_server_state_func")

	var player_instance: Node = add_player_scene(p_userdata.network_id)

	call_deferred("_threaded_requested_server_state_complete", p_userdata.thread, p_userdata.network_id)

	return player_instance


func _requested_server_state(p_network_id: int) -> void:
	print("_requested_server_state")

	var thread: Thread = Thread.new()

	if !is_session_alive():
		return

	_host_state_task_increment()
	var callable: Callable = Callable(self, "_threaded_requested_server_state_func")
	if thread.start(callable.bind({"thread": thread, "network_id": p_network_id})) != OK:
		_host_state_task_decrement()
		printerr("Could not start 'state_initialization_thread'!")


##########################


func _server_state_ready_to_send(p_network_id: int, p_network_writer: Object) -> void:
	print("_server_state_ready_to_send")

	NetworkManager.network_replication_manager.disconnect("spawn_state_for_new_client_ready", Callable(self, "_server_state_ready_to_send"))

	# For all the existing active peers, send them client info about the
	# new peer
	for active_peer in NetworkManager.active_peers:
		NetworkManager.server_send_client_info(active_peer, p_network_id, {"display_name": player_display_names[p_network_id], "avatar_path": player_avatar_paths[p_network_id]})

	NetworkManager.server_send_server_state(p_network_id, {"entity_state": p_network_writer.get_raw_data(p_network_writer.get_position())})
	NetworkManager.confirm_client_ready_for_sync(p_network_id)


# Join a network session by IP and port number
func join_game(p_ip: String, p_port: int) -> void:
	if NetworkManager.join_game(p_ip, p_port):
		pass
	else:
		printerr("Could not join game!")


func _peer_registration_complete() -> void:
	NetworkManager.client_request_server_info({"display_name": VSKPlayerManager.display_name, "avatar_path": VSKPlayerManager.avatar_path})


func _received_server_info(p_server_info: Dictionary) -> void:
	if p_server_info:
		if p_server_info.has("version"):
			var client_server_version_string: String = vsk_network_manager_const.get_vsk_network_version_string() + "_" + NetworkManager.get_network_version_string()

			if p_server_info["version"] == client_server_version_string:
				NetworkManager.session_master = NetworkManager.network_constants_const.SERVER_MASTER_PEER_ID
				await VSKMapManager.request_map_load(p_server_info["map_path"], false, false)

				return
			else:
				network_callback.emit(SERVER_INFO_VERSION_MISMATCH, {"server_network_version": p_server_info["version"], "client_network_version": client_server_version_string})
		else:
			network_callback.emit(NO_SERVER_INFO_VERSION, {})
	else:
		network_callback.emit(NO_SERVER_INFO, {})


func _received_client_info(p_network_id: int, p_client_info: Dictionary) -> void:
	_validated_peer_connected(p_network_id, p_client_info)


func _client_state_initialization_fade_complete(p_instance: Node, p_skipped: bool) -> void:
	if not is_session_alive():
		return

	if not p_instance:
		printerr("Could not instantiate map!")
		network_callback.emit(INVALID_MAP, {})
		return

	# Instance all networked entities received from the server
	NetworkManager.confirm_server_ready_for_sync()
	session_ready.emit(p_skipped)


func _client_state_initialization_complete(p_instance: Node) -> void:
	server_state_ready.emit()

	if not p_instance:
		printerr("Could not instantiate map!")
		network_callback.emit(INVALID_MAP, {})
		_host_state_task_decrement()
		return

	# is a bool
	var skipped = await VSKFadeManager.execute_fade(false).fade_complete
	if is_session_alive():
		_client_state_initialization_fade_complete(p_instance, skipped)


func _threaded_client_state_initialization_complete() -> void:
	var instantiate: Node = state_initialization_thread.wait_to_finish()
	await _client_state_initialization_complete(instantiate)


func _client_instance_map_func() -> Node:
	var instantiate: Node = VSKMapManager.instance_map(true)
	if instantiate:
		VSKMapManager.set_current_map(instantiate)

	return instantiate


func _threaded_received_server_state_initialization_func(p_userdata) -> Node:
	var server_state: Dictionary = p_userdata.server_state
	var instantiate: Node = _client_instance_map_func()

	print("Decoding server state init buffer...")
	NetworkManager.decode_buffer(NetworkManager.network_constants_const.SERVER_MASTER_PEER_ID, server_state["entity_state"])
	print("Done!")

	call_deferred("_threaded_client_state_initialization_complete")

	return instantiate


func _unthreaded_received_server_state_initialization_func(p_server_state: Dictionary) -> void:
	var server_state: Dictionary = p_server_state
	var instantiate: Node = _client_instance_map_func()

	print("Decoding server state init buffer...")
	NetworkManager.decode_buffer(NetworkManager.network_constants_const.SERVER_MASTER_PEER_ID, server_state["entity_state"])
	print("Done!")

	await _client_state_initialization_complete(instantiate)


func _received_server_state(p_server_state: Dictionary) -> void:
	destroy_all_entities()

	if kill_flag:
		return

	_host_state_task_increment()
	if use_threaded_received_server_state_func and state_initialization_thread:
		var callable: Callable = Callable(self, "_threaded_received_server_state_initialization_func")
		callable = callable.bind({"server_state": p_server_state})
		if state_initialization_thread.start(callable) != OK:
			_host_state_task_decrement()
			printerr("Could not start 'state_initialization_thread'!")
	else:
		call_deferred("_unthreaded_received_server_state_initialization_func", p_server_state)


##
## Callback from the NetworkManager for when a connection has succeeded.
##
func _connection_succeeded() -> void:
	connection_succeeded.emit()


##
## Callback from the NetworkManager for when a connection has failed.
##
func _connection_failed() -> void:
	connection_failed.emit()


##
## Callback from the NetworkManager for when the list of peers has changed.
##
func _peer_list_changed() -> void:
	if NetworkManager.is_server() and advertised_server:
		VSKShardManager.call_deferred("shard_update_player_count", shard_id, NetworkManager.get_peer_count(true))

		var shard_callback = await VSKShardManager.shard_update_player_count_callback
		if shard_callback["result"] == OK:
			if is_session_alive() and advertised_server:
				shard_heartbeat_timer.start(shard_heartbeat_frequency)
		else:
			printerr("Shard peer list update failed!")


##
## Callback from the NetworkManager for when a particular peer has been classified
## as active, specifically that they are now sending and receiving state data.
##
func _peer_became_active(p_network_id: int) -> void:
	if NetworkManager.is_server():
		# Send info about server host as a regular peer
		# if the server is not dedicated
		if !NetworkManager.server_dedicated:
			NetworkManager.server_send_client_info(p_network_id, NetworkManager.network_constants_const.SERVER_MASTER_PEER_ID, {"display_name": VSKPlayerManager.display_name, "avatar_path": VSKPlayerManager.avatar_path})

		# Send info about all the other active peers to the new
		# peer
		for active_peer in NetworkManager.active_peers:
			if p_network_id != active_peer:
				NetworkManager.server_send_client_info(p_network_id, active_peer, {"display_name": player_display_names[active_peer], "avatar_path": player_avatar_paths[active_peer]})


##
## Called when a peers client info has been received.
##
func _validated_peer_connected(p_network_id: int, p_client_info: Dictionary) -> void:
	var display_name: String = ""
	var avatar_path: String = ""

	print("Client %s has connected!" % display_name)

	#var client_info: Dictionary = VSKGameModeManager.on_peer_connected(p_network_id, p_client_info)

	if not p_client_info.is_empty():
		if p_client_info.has("display_name"):
			if typeof(p_client_info["display_name"]) == TYPE_STRING:
				display_name = p_client_info["display_name"]
		if p_client_info.has("avatar_path"):
			if typeof(p_client_info["avatar_path"]) == TYPE_STRING:
				avatar_path = p_client_info["avatar_path"]

	validated_peers.push_back(p_network_id)

	update_player_display_name(p_network_id, display_name)
	update_player_avatar_path(p_network_id, avatar_path)


##
## Called when a peers client info has been received.
##
func _validated_peer_disconnected(p_network_id: int) -> void:
	print("Client %s has disconnected!" % player_display_names[p_network_id])
	VSKGameModeManager.on_peer_disconnected(p_network_id)

	if NetworkManager.is_server():
		remove_player_scene(p_network_id)

	remove_player_display_name(p_network_id)
	remove_player_avatar_path(p_network_id)
	validated_peers.erase(p_network_id)


##
## Callback from the NetworkManager for when a particular peer has connected
## p_network_id is the peer id for the peer who connected
##
func _peer_registered(_network_id: int) -> void:
	pass


##
## Callback from the NetworkManager for when a particular peer has disconnected
## p_network_id is the peer id for the peer who disconnected
##
func _peer_unregistered(p_network_id: int) -> void:
	if validated_peers.has(p_network_id):
		_validated_peer_disconnected(p_network_id)


##
## Callback from the NetworkManager when a new packet for a particular peer
## has been received.
## p_network_id is the peer id for this packet
## p_packet is the buffer containing the raw data
##
func _network_peer_packet(p_network_id: int, p_packet: PackedByteArray) -> void:
	NetworkManager.decode_buffer(p_network_id, p_packet)


##
## Called by regular _server_disconnected as a deferred function...I can't remember
## why.
##
func _server_disconnected_deferred() -> void:
	force_disconnect()

	clear_all_player_display_names()
	clear_all_player_avatar_paths()
	clear_all_validated_peers()

	server_disconnected.emit()


##
## Callback function from the NetworkManager if we have been disconnected from the
## server
##
func _server_disconnected() -> void:
	call_deferred("_server_disconnected_deferred")


##
## Callback function for when the application is about to close.
##
func _is_quitting() -> void:
	force_disconnect()


func assign_resource(p_resource: Resource, p_resource_id: int) -> void:
	match p_resource_id:
		RESOURCE_ID_PLAYER_SCENE:
			player_scene = p_resource


func get_preload_tasks() -> Dictionary:
	var preloading_tasks: Dictionary = {}
	preloading_tasks[player_scene_path] = {"target": self, "method": "assign_resource", "args": [RESOURCE_ID_PLAYER_SCENE]}

	var network_scene_paths = NetworkManager.get_network_scene_paths()
	for path in network_scene_paths:
		if !preloading_tasks.has(path):
			preloading_tasks[path] = {"target": null, "method": "", "args": []}

	return preloading_tasks


func setup() -> void:
	if !Engine.is_editor_hint():
		shard_heartbeat_timer = Timer.new()
		shard_heartbeat_timer.set_name("ShardHeartbeatTimer")
		add_child(shard_heartbeat_timer, true)

		if shard_heartbeat_timer.timeout.connect(self._heartbeat_timer_timout) != OK:
			printerr("Failed to connect ShardHeartbeatTimer timeout signal")
			return

		var godot_speech: Node = GodotSpeech
		if godot_speech:
			NetworkManager.network_voice_manager.get_voice_buffers = VSKAudioManager.get_voice_buffers
			if !NetworkManager.network_voice_manager.get_voice_buffers.is_valid():
				printerr("Could not register get_voice_buffers callfunc")

			NetworkManager.network_voice_manager.get_sequence_id = VSKAudioManager.get_current_voice_id
			if !NetworkManager.network_voice_manager.get_sequence_id.is_valid():
				printerr("Could not register get_sequence_id callfunc")
		else:
			printerr("Could not find GodotSpeech node")

		NetworkManager.network_voice_manager.should_send_audio = VSKAudioManager.should_send_audio
		if !NetworkManager.network_voice_manager.should_send_audio.is_valid():
			printerr("Could not register should_send_audio callfunc")

		if use_threaded_host_state_initalisation_func:
			state_initialization_thread = Thread.new()

		connection_util_const.connect_signal_table(signal_table, self)


func apply_project_settings() -> void:
	if Engine.is_editor_hint():
		if !ProjectSettings.has_setting("network/config/use_threaded_host_state_initalisation_func"):
			ProjectSettings.set_setting("network/config/use_threaded_host_state_initalisation_func", use_threaded_host_state_initalisation_func)

		if !ProjectSettings.has_setting("network/config/use_threaded_received_server_state_func"):
			ProjectSettings.set_setting("network/config/use_threaded_received_server_state_func", use_threaded_received_server_state_func)

		if !ProjectSettings.has_setting("network/config/player_scene"):
			ProjectSettings.set_setting("network/config/player_scene", player_scene_path)

		if !ProjectSettings.has_setting("network/config/shard_heartbeat_frequency"):
			ProjectSettings.set_setting("network/config/shard_heartbeat_frequency", shard_heartbeat_frequency)

		if ProjectSettings.save() != OK:
			printerr("Could not save project settings!")


func get_project_settings() -> void:
	use_threaded_host_state_initalisation_func = ProjectSettings.get_setting("network/config/use_threaded_host_state_initalisation_func")
	use_threaded_received_server_state_func = ProjectSettings.get_setting("network/config/use_threaded_received_server_state_func")
	player_scene_path = ProjectSettings.get_setting("network/config/player_scene")
	shard_heartbeat_frequency = ProjectSettings.get_setting("network/config/shard_heartbeat_frequency")


func _ready() -> void:
	apply_project_settings()
	get_project_settings()
