# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# network_replication_manager.gd
# SPDX-License-Identifier: MIT

@tool
extends Node

const ref_pool_const = preload("res://addons/gd_util/ref_pool.gd")

const network_constants_const = preload("network_constants.gd")
const network_writer_const = preload("network_writer.gd")

const MAXIMUM_REPLICATION_PACKET_SIZE = 1024

var network_manager: Object
var _EntityManager: Node = null


func _init(p_network_manager):
	network_manager = p_network_manager


var dummy_replication_writer = network_writer_const.new(MAXIMUM_REPLICATION_PACKET_SIZE)  # For debugging purposes
var replication_writers = {}

var signal_table: Array = [
	{"singleton": "NetworkManager", "signal": "peer_unregistered", "method": "_reclaim_peers_entities"},
	{"singleton": "NetworkManager", "signal": "entity_network_id_registered", "method": "_network_id_registered_added"},
	{"singleton": "NetworkManager", "signal": "entity_network_id_unregistered", "method": "_network_id_unregistered_added"},
	{"singleton": "NetworkManager", "signal": "network_process", "method": "_network_manager_process"},
	{"singleton": "NetworkManager", "signal": "network_flush", "method": "_network_manager_flush"},
	{"singleton": "NetworkManager", "signal": "game_hosted", "method": "_game_hosted"},
	{"singleton": "NetworkManager", "signal": "connection_succeeded", "method": "_connected_to_server"},
	{"singleton": "NetworkManager", "signal": "server_peer_connected", "method": "_server_peer_connected"},
	{"singleton": "NetworkManager", "signal": "server_peer_disconnected", "method": "_server_peer_disconnected"},
]

signal spawn_state_for_new_client_ready(p_network_id, p_network_writer)

# Server-only
var network_entity_ids_pending_spawn: Array = []
var network_entity_ids_pending_destruction: Array = []

# For each peer, retaining a list of entities which have been spawned
# during the creation of the server_state and ignore them so they don't
# get spawned twice on the next frame
var network_entity_ignore_table: Dictionary = {}

# Client/Server
var network_entity_ids_pending_request_transfer_master: Array = []


func _network_id_registered_added(p_entity_id: int) -> void:
	if network_manager.is_server():
		if network_entity_ids_pending_spawn.has(p_entity_id):
			NetworkLogger.error("Attempted to spawn two identical network entities")

		network_entity_ids_pending_spawn.push_back(p_entity_id)


func _network_id_unregistered_added(p_entity_id: int) -> void:
	if network_manager.is_server():
		if network_entity_ids_pending_request_transfer_master.has(p_entity_id):
			network_entity_ids_pending_request_transfer_master.remove_at(network_entity_ids_pending_request_transfer_master.find(p_entity_id))

		if network_entity_ids_pending_spawn.has(p_entity_id):
			network_entity_ids_pending_spawn.remove_at(network_entity_ids_pending_spawn.find(p_entity_id))
		else:
			network_entity_ids_pending_destruction.push_back(p_entity_id)


func _entity_request_transfer_master(p_entity_id: int) -> void:
	if network_entity_ids_pending_destruction.has(network_entity_ids_pending_destruction.find(p_entity_id)):
		return
	else:
		if !network_entity_ids_pending_request_transfer_master.has(p_entity_id):
			network_entity_ids_pending_request_transfer_master.push_back(p_entity_id)


##
##
##


func get_entity_root_node() -> Node:
	return network_manager.get_entity_root_node()


##  Network ids end

##
## Server
##


func write_entity_spawn_command(p_entity_id: int, p_network_writer: Object) -> Object:
	var network_entity_manager: Node = network_manager.network_entity_manager
	var entity_instance: Node = network_entity_manager.get_network_instance_for_instance_id(p_entity_id)

	p_network_writer = network_entity_manager.write_entity_scene_id(entity_instance, network_entity_manager.networked_scenes, p_network_writer)
	p_network_writer = network_entity_manager.write_entity_instance_id_for_entity(entity_instance, p_network_writer)
	p_network_writer = network_entity_manager.write_entity_multiplayer_authority(entity_instance, p_network_writer)

	var entity_state: Object = entity_instance.network_identity_node.get_state(null, true)

	var entity_state_size = entity_state.get_position()
	if entity_state_size >= 0xffff:
		NetworkLogger.error("State data exceeds 16 bits!")

	p_network_writer.put_writer(entity_state, entity_state.get_position())

	return p_network_writer


func write_entity_destroy_command(p_entity_id: int, p_network_writer: Object) -> Object:
	var network_entity_manager: Node = network_manager.network_entity_manager

	p_network_writer = network_entity_manager.write_entity_instance_id(p_entity_id, p_network_writer)

	return p_network_writer


func write_entity_request_master_command(p_entity_id: int, p_network_writer: Object) -> Object:
	var network_entity_manager: Node = network_manager.network_entity_manager
	var entity_instance: Node = network_entity_manager.get_network_instance_for_instance_id(p_entity_id)

	if not entity_instance:
		return p_network_writer

	p_network_writer = network_entity_manager.write_entity_instance_id_for_entity(entity_instance, p_network_writer)

	return p_network_writer


func write_entity_transfer_master_command(p_entity_id: int, p_network_writer: Object) -> Object:
	var network_entity_manager: Node = network_manager.network_entity_manager
	var entity_instance: Node = network_entity_manager.get_network_instance_for_instance_id(p_entity_id)

	p_network_writer = network_entity_manager.write_entity_instance_id_for_entity(entity_instance, p_network_writer)
	p_network_writer = network_entity_manager.write_entity_multiplayer_authority(entity_instance, p_network_writer)

	return p_network_writer


func create_entity_command(p_command: int, p_entity_id: int) -> Object:
	var network_writer: Object = network_manager.network_entity_command_writer_cache
	network_writer.seek(0)

	match p_command:
		network_constants_const.SPAWN_ENTITY_COMMAND:
			network_writer.put_u8(network_constants_const.SPAWN_ENTITY_COMMAND)
			network_writer = write_entity_spawn_command(p_entity_id, network_writer)
		network_constants_const.DESTROY_ENTITY_COMMAND:
			network_writer.put_u8(network_constants_const.DESTROY_ENTITY_COMMAND)
			network_writer = write_entity_destroy_command(p_entity_id, network_writer)
		network_constants_const.REQUEST_ENTITY_MASTER_COMMAND:
			network_writer.put_u8(network_constants_const.REQUEST_ENTITY_MASTER_COMMAND)
			network_writer = write_entity_request_master_command(p_entity_id, network_writer)
		network_constants_const.TRANSFER_ENTITY_MASTER_COMMAND:
			network_writer.put_u8(network_constants_const.TRANSFER_ENTITY_MASTER_COMMAND)
			network_writer = write_entity_transfer_master_command(p_entity_id, network_writer)
		_:
			NetworkLogger.error("Unknown entity message")

	return network_writer


func get_network_scene_id_from_path(p_path: String) -> int:
	var path: String = p_path
	var network_entity_manager: Node = network_manager.network_entity_manager

	while 1:
		var network_scene_id: int = network_entity_manager.networked_scenes.find(path)

		# If a valid packed scene was not found, try next to search for it via its inheritance chain
		if network_scene_id == -1:
			if path != "res://addons/vsk_entities/vsk_player.tscn":
				push_error("SECURITY: " + str(self) + "@" + str(self.get_path()) + ": Checking for resource at " + str(path))
				break
			if ResourceLoader.exists(path):
				var packed_scene: PackedScene = ResourceLoader.load(path)
				if packed_scene:
					var scene_state: SceneState = packed_scene.get_state()
					if scene_state.get_node_count() > 0:
						var sub_packed_scene: PackedScene = scene_state.get_node_instance(0)
						if sub_packed_scene:
							path = sub_packed_scene.resource_path
							continue
			break
		else:
			return network_scene_id

	NetworkLogger.error("Could not find network scene id for {path}".format({"path": path}))
	return -1


func create_spawn_state_for_new_client(p_network_id: int) -> void:
	_EntityManager.scene_tree_execution_table._execute_scene_tree_execution_table_unsafe()

	var ignore_list: Array = []

	var entities: Array = get_tree().get_nodes_in_group("NetworkedEntities")

	var network_writer_state: Object = null

	if p_network_id != -1:
		network_writer_state = replication_writers[p_network_id]
	else:
		network_writer_state = dummy_replication_writer

	network_writer_state.seek(0)

	NetworkLogger.printl("Spawn state = [")
	for entity in entities:
		if entity.is_inside_tree():
			NetworkLogger.printl("{ %s }" % entity.get_name())
	NetworkLogger.printl("] for %s" % str(p_network_id))

	for entity in entities:
		if entity.is_inside_tree():
			var entity_command_network_writer: Object = create_entity_command(network_constants_const.SPAWN_ENTITY_COMMAND, entity.network_identity_node.network_instance_id)
			network_writer_state.put_writer(entity_command_network_writer, entity_command_network_writer.get_position())

			ignore_list.push_back(entity)

	NetworkLogger.printl("Spawn state size: %s" % str(network_writer_state.get_position()))

	network_entity_ignore_table[p_network_id] = ignore_list

	spawn_state_for_new_client_ready.emit(p_network_id, network_writer_state)


func flush() -> void:
	network_entity_ids_pending_spawn = []
	network_entity_ids_pending_destruction = []
	network_entity_ids_pending_request_transfer_master = []

	network_entity_ignore_table = {}


func _network_manager_flush() -> void:
	flush()


func _network_manager_process(p_id: int, _delta: float) -> void:
	if network_entity_ids_pending_spawn.size() > 0 or network_entity_ids_pending_destruction.size() or network_entity_ids_pending_request_transfer_master.size() > 0:
		# Debugging information
		if network_entity_ids_pending_spawn.size():
			NetworkLogger.printl("Spawning entities = [")
			for entity_id in network_entity_ids_pending_spawn:
				var entity_instance: Node = network_manager.network_entity_manager.get_network_instance_for_instance_id(entity_id)
				if is_instance_valid(entity_instance):
					NetworkLogger.printl("{ %s }" % entity_instance.get_name())
			NetworkLogger.printl("]")

		if network_entity_ids_pending_destruction.size():
			NetworkLogger.printl("Destroying entities = [")
			for entity_id in network_entity_ids_pending_destruction:
				var entity_instance: Node = network_manager.network_entity_manager.get_network_instance_for_instance_id(entity_id)
				if is_instance_valid(entity_instance):
					NetworkLogger.printl("{ %s }" % entity_instance.get_name())
			NetworkLogger.printl("]")
		# Debugging end

		var synced_peers: Array = network_manager.copy_valid_send_peers(p_id, false)

		for synced_peer in synced_peers:
			var network_writer_state: Object = null

			var ignore_list: Array = []
			if network_entity_ignore_table.has(synced_peer):
				ignore_list = network_entity_ignore_table[synced_peer]

			if synced_peer != -1:
				network_writer_state = replication_writers[synced_peer]
			else:
				network_writer_state = dummy_replication_writer

			network_writer_state.seek(0)

			if p_id == network_manager.session_master:
				# Spawn commands
				for entity_id in network_entity_ids_pending_spawn:
					# If this entity is in the ignore list, skip it
					if ignore_list.has(network_manager.network_entity_manager.get_network_instance_for_instance_id(entity_id)):
						continue

					var entity_command_network_writer: Object = create_entity_command(network_constants_const.SPAWN_ENTITY_COMMAND, entity_id)
					network_writer_state.put_writer(entity_command_network_writer, entity_command_network_writer.get_position())

				# Destroy commands
				for entity_id in network_entity_ids_pending_destruction:
					var entity_command_network_writer: Object = create_entity_command(network_constants_const.DESTROY_ENTITY_COMMAND, entity_id)
					network_writer_state.put_writer(entity_command_network_writer, entity_command_network_writer.get_position())

				# Transfer master commands
				for entity_id in network_entity_ids_pending_request_transfer_master:
					var entity_command_network_writer: Object = create_entity_command(network_constants_const.TRANSFER_ENTITY_MASTER_COMMAND, entity_id)
					network_writer_state.put_writer(entity_command_network_writer, entity_command_network_writer.get_position())
			else:
				# Request master commands
				for entity_id in network_entity_ids_pending_request_transfer_master:
					var entity_command_network_writer: Object = create_entity_command(network_constants_const.REQUEST_ENTITY_MASTER_COMMAND, entity_id)
					network_writer_state.put_writer(entity_command_network_writer, entity_command_network_writer.get_position())

			if network_writer_state.get_position() > 0:
				var raw_data: PackedByteArray = network_writer_state.get_raw_data(network_writer_state.get_position())
				network_manager.network_flow_manager.queue_packet_for_send(ref_pool_const.new(raw_data), synced_peer, MultiplayerPeer.TRANSFER_MODE_RELIABLE)

		# Flush the pending spawn, parenting, and destruction queues
		flush()


##
## Client
##


func get_scene_path_for_scene_id(p_scene_id: int) -> String:
	if network_manager.network_entity_manager.networked_scenes.size() > p_scene_id:
		var network_entity_manager: Node = network_manager.network_entity_manager
		var path: String = network_entity_manager.networked_scenes[p_scene_id]

		return path
	else:
		return ""


func get_packed_scene_for_path(p_path: String) -> PackedScene:
	if p_path != "res://addons/vsk_entities/vsk_player.tscn":
		push_error("SECURITY: " + str(self) + "@" + str(self.get_path()) + ": get_packed_scene_for_path at " + str(p_path))
		return null

	if ResourceLoader.exists(p_path):
		var packed_scene: PackedScene = ResourceLoader.load(p_path)

		if packed_scene is PackedScene:
			return packed_scene
		else:
			return null
	else:
		return null


func decode_entity_spawn_command(p_packet_sender_id: int, p_network_reader: Object) -> Object:
	var network_entity_manager: Node = network_manager.network_entity_manager
	var valid_sender_id = false

	if p_packet_sender_id == network_manager.session_master or p_packet_sender_id == network_constants_const.SERVER_MASTER_PEER_ID:
		valid_sender_id = true

	if p_network_reader.is_eof():
		NetworkLogger.error("decode_entity_spawn_command: eof!")
		return null

	var scene_id: int = network_entity_manager.read_entity_scene_id(p_network_reader, network_entity_manager.networked_scenes)
	if p_network_reader.is_eof():
		NetworkLogger.error("decode_entity_spawn_command: eof!")
		return null

	var instance_id: int = network_entity_manager.read_entity_instance_id(p_network_reader)
	if instance_id <= network_entity_manager.NULL_NETWORK_INSTANCE_ID:
		NetworkLogger.error("decode_entity_spawn_command: eof!")
		return null

	if p_network_reader.is_eof():
		NetworkLogger.error("decode_entity_spawn_command: eof!")
		return null

	var multiplayer_authority: int = network_entity_manager.read_entity_multiplayer_authority(p_network_reader)
	if p_network_reader.is_eof():
		NetworkLogger.error("decode_entity_spawn_command: eof!")
		return null

	# If this was not from a valid send, return null
	if !valid_sender_id:
		NetworkLogger.error("decode_entity_spawn_command: received spawn command from non server ID!")
		return null

	var scene_path: String = get_scene_path_for_scene_id(scene_id)
	if scene_path == "":
		NetworkLogger.error("decode_entity_spawn_command: received invalid scene id {scene_id}!".format({"scene_id": scene_id}))
		return null

	var packed_scene: PackedScene = get_packed_scene_for_path(scene_path)
	if packed_scene == null:
		NetworkLogger.error("decode_entity_spawn_command: received invalid packed_scene for path {scene_path}!".format({"scene_path": scene_path}))
		return null

	var entity_instance: Node = packed_scene.instantiate()
	if entity_instance == null:
		NetworkLogger.error("decode_entity_spawn_command: null instantiate!")
		return null

	entity_instance._threaded_instance_setup(instance_id, p_network_reader)

	entity_instance.set_name("NetEntity_{instance_id}".format({"instance_id": str(entity_instance.network_identity_node.network_instance_id)}))
	entity_instance.set_multiplayer_authority(multiplayer_authority)

	_EntityManager.scene_tree_execution_command(_EntityManager.scene_tree_execution_table_const.ADD_ENTITY, entity_instance)

	return p_network_reader


func decode_entity_destroy_command(p_packet_sender_id: int, p_network_reader: Object) -> Object:
	var network_entity_manager: Node = network_manager.network_entity_manager
	var valid_sender_id = false

	if p_packet_sender_id == network_manager.session_master or p_packet_sender_id == network_constants_const.SERVER_MASTER_PEER_ID:
		valid_sender_id = true

	if p_network_reader.is_eof():
		NetworkLogger.error("decode_entity_destroy_command: eof!")
		return null

	var instance_id: int = network_entity_manager.read_entity_instance_id(p_network_reader)
	if p_network_reader.is_eof():
		NetworkLogger.error("decode_entity_destroy_command: eof!")
		return null

	# If this was not from a valid send, return null
	if !valid_sender_id:
		NetworkLogger.error("decode_entity_destroy_command: received destroy command from non server ID!")
		return null

	if network_entity_manager.network_instance_ids.has(instance_id):
		var entity_instance: Node = network_entity_manager.get_network_instance_for_instance_id(instance_id)
		_EntityManager.scene_tree_execution_command(_EntityManager.scene_tree_execution_table_const.REMOVE_ENTITY, entity_instance)
	else:
		NetworkLogger.error("Attempted to destroy invalid node")

	return p_network_reader


func decode_entity_request_master_command(p_packet_sender_id: int, p_network_reader: Object) -> Object:
	var network_entity_manager: Node = network_manager.network_entity_manager

	var valid_sender_id = false

	if network_manager.is_session_master():
		valid_sender_id = true

	if p_network_reader.is_eof():
		NetworkLogger.error("decode_entity_request_master_command: eof!")
		return null

	var instance_id: int = network_entity_manager.read_entity_instance_id(p_network_reader)
	if instance_id <= network_entity_manager.NULL_NETWORK_INSTANCE_ID:
		NetworkLogger.error("decode_entity_request_master_command: eof!")
		return null

	# If this was not from a valid send, return null
	if !valid_sender_id:
		NetworkLogger.error("decode_entity_request_master_command: request master command sent directly to client!")
		return null

	var entity_instance: Node = network_entity_manager.get_network_instance_for_instance_id(instance_id)
	if entity_instance:
		if entity_instance.can_request_master_from_peer(p_packet_sender_id):
			request_to_become_master(instance_id, entity_instance, p_packet_sender_id)
		else:
			# The request was denied, but queue an update message anyway to
			# at least inform the client (possible optimisation, only send this
			# to the requesting client)
			_entity_request_transfer_master(instance_id)
	else:
		NetworkLogger.error("Attempted to request master of invalid node")

	return p_network_reader


# Parse an entity transfer master command. Will only be accepted
func decode_entity_transfer_master_command(p_packet_sender_id: int, p_network_reader: Object) -> Object:
	var network_entity_manager: Node = network_manager.network_entity_manager

	var valid_sender_id: bool = false

	if p_packet_sender_id == network_manager.session_master or p_packet_sender_id == network_constants_const.SERVER_MASTER_PEER_ID:
		valid_sender_id = true

	if p_network_reader.is_eof():
		NetworkLogger.error("decode_entity_transfer_master_command: eof!")
		return null

	var instance_id: int = network_entity_manager.read_entity_instance_id(p_network_reader)
	if instance_id <= network_entity_manager.NULL_NETWORK_INSTANCE_ID:
		NetworkLogger.error("decode_entity_transfer_master_command: eof!")
		return null

	if p_network_reader.is_eof():
		NetworkLogger.error("decode_entity_transfer_master_command: eof!")
		return null

	var new_multiplayer_authority: int = network_entity_manager.read_entity_multiplayer_authority(p_network_reader)
	if p_network_reader.is_eof():
		NetworkLogger.error("decode_entity_transfer_master_command: eof!")
		return null

	# If this was not from a valid send, return null
	if !valid_sender_id:
		NetworkLogger.error("decode_entity_transfer_master_command: received transfer master command from non server ID!")
		return null

	if network_entity_manager.network_instance_ids.has(instance_id):
		var entity_instance: Node = network_entity_manager.network_instance_ids[instance_id].get_entity_node()
		if entity_instance.can_transfer_master_from_session_master(new_multiplayer_authority):
			entity_instance.process_master_request(new_multiplayer_authority)
	else:
		NetworkLogger.error("Attempted to transfer master of invalid node")

	return p_network_reader


# Called me the network manager to process replication messages
func decode_replication_buffer(p_packet_sender_id: int, p_network_reader: Object, p_command: int) -> Object:
	match p_command:
		network_constants_const.SPAWN_ENTITY_COMMAND:
			p_network_reader = decode_entity_spawn_command(p_packet_sender_id, p_network_reader)
		network_constants_const.DESTROY_ENTITY_COMMAND:
			p_network_reader = decode_entity_destroy_command(p_packet_sender_id, p_network_reader)
		network_constants_const.REQUEST_ENTITY_MASTER_COMMAND:
			p_network_reader = decode_entity_request_master_command(p_packet_sender_id, p_network_reader)
		network_constants_const.TRANSFER_ENTITY_MASTER_COMMAND:
			p_network_reader = decode_entity_transfer_master_command(p_packet_sender_id, p_network_reader)
		_:
			NetworkLogger.error("Unknown Entity replication command")

	return p_network_reader


# Called to claim mastership over an entity. Mastership
# will be immediately claimed an a request/transfer request
# will go into the queue
func request_to_become_master(p_entity_id: int, p_entity: Node, p_id: int) -> void:
	p_entity.process_master_request(p_id)
	_entity_request_transfer_master(p_entity_id)


# Called when peer disconnects. If the peer is currently the session master,
# they will attempt to claim mastership over all entities owned by the
# disconnecting peer
func _reclaim_peers_entities(p_id: int) -> void:
	if network_manager.is_session_master():
		var entities: Array = _EntityManager.get_all_entities()
		for entity_instance in entities:
			if entity_instance.get_multiplayer_authority() == p_id:
				if entity_instance.can_request_master_from_peer(network_manager.get_current_peer_id()):
					entity_instance.request_to_become_master()


func _game_hosted() -> void:
	replication_writers = {}


func _connected_to_server() -> void:
	replication_writers = {}
	var network_writer = network_writer_const.new(MAXIMUM_REPLICATION_PACKET_SIZE)
	replication_writers[network_constants_const.SERVER_MASTER_PEER_ID] = network_writer


func _server_peer_connected(p_id: int) -> void:
	var network_writer = network_writer_const.new(MAXIMUM_REPLICATION_PACKET_SIZE)
	replication_writers[p_id] = network_writer


func _server_peer_disconnected(p_id: int) -> void:
	if !replication_writers.erase(p_id):
		NetworkLogger.error("network_replication_manager: attempted disconnect invalid peer!")


func is_command_valid(p_command: int) -> bool:
	if p_command == network_constants_const.SPAWN_ENTITY_COMMAND or p_command == network_constants_const.DESTROY_ENTITY_COMMAND or p_command == network_constants_const.REQUEST_ENTITY_MASTER_COMMAND or p_command == network_constants_const.TRANSFER_ENTITY_MASTER_COMMAND:
		return true
	else:
		return false


func _ready() -> void:
	_EntityManager = $"/root/EntityManager"
	if !Engine.is_editor_hint():
		$"/root/ConnectionUtil".connect_signal_table(signal_table, self)
