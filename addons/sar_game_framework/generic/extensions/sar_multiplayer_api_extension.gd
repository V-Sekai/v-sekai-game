class_name SarMultiplayerAPIExtension
extends MultiplayerAPIExtension

var base_multiplayer: SceneMultiplayer = SceneMultiplayer.new()

func get_unique_id_string() -> String:
	if has_multiplayer_peer() and multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		return str(get_unique_id())
	else:
		return "UNASSIGNED"

func _init() -> void:
	var cts: Signal = connected_to_server
	var cf: Signal = connection_failed
	var pc: Signal = peer_connected
	var pd: Signal = peer_disconnected
	var sd: Signal = server_disconnected
	assert(base_multiplayer.connected_to_server.connect(func() -> void: cts.emit()) == OK)
	assert(base_multiplayer.connection_failed.connect(func() -> void: cf.emit()) == OK)
	assert(base_multiplayer.peer_connected.connect(func(id: int) -> void: pc.emit(id)) == OK)
	assert(base_multiplayer.peer_disconnected.connect(func(id: int) -> void: pd.emit(id)) == OK)
	assert(base_multiplayer.server_disconnected.connect(func() -> void: sd.emit()) == OK)

func _rpc(peer: int, object: Object, method: StringName, args: Array) -> Error: # Error
	#print(get_unique_id_string() + ": Got RPC for %d: %s::%s(%s)" % [peer, object, method, args])
	assert(base_multiplayer)
	return base_multiplayer.rpc(peer, object, method, args)

func _object_configuration_add(object: Object, config: Variant) -> Error:
	#if config is MultiplayerSynchronizer:
	#	print(get_unique_id_string() + ": Adding synchronization configuration for %s. Synchronizer: %s" % [object, config])
	#elif config is MultiplayerSpawner:
	#	print(get_unique_id_string() + ": Adding node %s to the spawn list. Spawner: %s" % [object, config])
	assert(base_multiplayer)
	return base_multiplayer.object_configuration_add(object, config)

func _object_configuration_remove(object: Object, config: Variant) -> Error:
	#if config is MultiplayerSynchronizer:
	#	print(get_unique_id_string() + ": Removing synchronization configuration for %s. Synchronizer: %s" % [object, config])
	#elif config is MultiplayerSpawner:
	#	print(get_unique_id_string() + ": Removing node %s from the spawn list. Spawner: %s" % [object, config])
	assert(base_multiplayer)
	return base_multiplayer.object_configuration_remove(object, config)

func _set_multiplayer_peer(p_peer: MultiplayerPeer) -> void:
	assert(base_multiplayer)
	base_multiplayer.multiplayer_peer = p_peer

func _get_multiplayer_peer() -> MultiplayerPeer:
	assert(base_multiplayer)
	return base_multiplayer.multiplayer_peer

func _get_unique_id() -> int:
	assert(base_multiplayer)
	return base_multiplayer.get_unique_id()

func _get_peer_ids() -> PackedInt32Array:
	assert(base_multiplayer)
	return base_multiplayer.get_peers()
	
func _get_remote_sender_id() -> int:
	assert(base_multiplayer)
	return base_multiplayer.get_remote_sender_id()
	
func _poll() -> Error:
	assert(base_multiplayer)
	return base_multiplayer.poll()
