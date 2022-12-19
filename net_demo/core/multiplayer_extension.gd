extends MultiplayerAPIExtension
class_name MultiplayerExtension

var base_multiplayer = SceneMultiplayer.new()

func _get_unique_id_string() -> String:
	if has_multiplayer_peer() and multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		return str(get_unique_id())
	else:
		return "UNASSIGNED"

func _init():
	var cts = connected_to_server
	var cf = connection_failed
	var pc = peer_connected
	var pd = peer_disconnected
	var sd = server_disconnected
	base_multiplayer.connected_to_server.connect(func(): cts.emit())
	base_multiplayer.connection_failed.connect(func(): cf.emit())
	base_multiplayer.peer_connected.connect(func(id): pc.emit(id))
	base_multiplayer.peer_disconnected.connect(func(id): pd.emit(id))
	base_multiplayer.server_disconnected.connect(func(): sd.emit())

func _rpc(peer: int, object: Object, method: StringName, args: Array) -> int: # Error
	print(_get_unique_id_string() + ": Got RPC for %d: %s::%s(%s)" % [peer, object, method, args])
	return base_multiplayer.rpc(peer, object, method, args)

func _object_configuration_add(object, config: Variant) -> int:
	if config is MultiplayerSynchronizer:
		print(_get_unique_id_string() + ": Adding synchronization configuration for %s. Synchronizer: %s" % [object, config])
	elif config is MultiplayerSpawner:
		print(_get_unique_id_string() + ": Adding node %s to the spawn list. Spawner: %s" % [object, config])
	return base_multiplayer.object_configuration_add(object, config)

func _object_configuration_remove(object, config: Variant) -> int:
	if config is MultiplayerSynchronizer:
		print(_get_unique_id_string() + ": Removing synchronization configuration for %s. Synchronizer: %s" % [object, config])
	elif config is MultiplayerSpawner:
		print(_get_unique_id_string() + ": Removing node %s from the spawn list. Spawner: %s" % [object, config])
	return base_multiplayer.object_configuration_remove(object, config)

func _set_multiplayer_peer(p_peer: MultiplayerPeer):
	base_multiplayer.multiplayer_peer = p_peer

func _get_multiplayer_peer() -> MultiplayerPeer:
	return base_multiplayer.multiplayer_peer

func _get_unique_id() -> int:
	return base_multiplayer.get_unique_id()

func _get_peer_ids() -> PackedInt32Array:
	return base_multiplayer.get_peers()
	
func _get_remote_sender_id() -> int:
	return base_multiplayer.get_remote_sender_id()
	
func _poll() -> int:
	return base_multiplayer.poll()
