@tool
extends Node
class_name SarGameSessionManager

var _authentication_node: SarGameSessionAuthentication = null
var _player_spawner_node: MultiplayerSpawner = null

const _SHOW_WINDOW_TITLE_DEBUG_INFO_PATH: String = "game/session/show_window_title_debug_info"
const _PLAYER_SOUL_SCENE_PROJECT_SETTING_PATH: String = "game/session/player_soul_scene_path"
const _PLAYER_VESSEL_SCENE_PROJECT_SETTING_PATH: String = "game/session/player_vessel_scene_path"

var _is_dedicated: bool = false
var _max_players: int = 0

var _player_soul_scene: PackedScene = null
var _player_vessel_scene: PackedScene = null

var _local_player_soul_instance: SarSoul = null

# The host peer's ID is always 1
const _HOST_PEER_ID: int = 1

func _get_player_start_group_name() -> String:
	return "player_start"
	
func _get_player_vessel_scene() -> PackedScene:
	return _player_vessel_scene
	
func _get_player_soul_scene() -> PackedScene:
	return _player_soul_scene
	
func _create_authentication_node() -> SarGameSessionAuthentication:
	return null

func _update_window_title() -> void:
	var window: Window = get_viewport()
	if window:
		var project_settings_title: String = ProjectSettings.get_setting("application/config/name")
		window.title = project_settings_title
		
		var peer: MultiplayerPeer = multiplayer.multiplayer_peer
		if peer and multiplayer:
			window.title = project_settings_title + (" (local_peer_id: %s)" % str(multiplayer.get_unique_id()))

func _should_use_window_title_debug_behaviour() -> bool:
	return ProjectSettings.get_setting(_SHOW_WINDOW_TITLE_DEBUG_INFO_PATH, false)

func _create_player_spawner_node() -> MultiplayerSpawner:
	var spawner: MultiplayerSpawner = MultiplayerSpawner.new()
	var vessel_path: String = ProjectSettings.get_setting(_PLAYER_VESSEL_SCENE_PROJECT_SETTING_PATH, "")
	if vessel_path:
		spawner.add_spawnable_scene(vessel_path)
		
	return spawner
	
func _get_player_spawn_parent() -> Node:
	return get_tree().current_scene
	
func _update_player_spawn_path() -> void:
	if _player_spawner_node:
		_player_spawner_node.spawn_path = _player_spawner_node.get_path_to(_get_player_spawn_parent())
	
func _spawn_player_soul(p_id: int) -> SarSoul:
	var spawn_parent: Node = _get_player_spawn_parent()
	
	var player_soul_instance: SarSoul = _get_player_soul_scene().instantiate()
	assert(player_soul_instance)
	player_soul_instance.name = get_player_soul_name_prefix() + str(p_id)
	player_soul_instance.set_multiplayer_authority(p_id)
	spawn_parent.add_child(player_soul_instance)
	
	var player_node_instance: Node = spawn_parent.get_node_or_null(get_player_entity_name_prefix() + str(p_id))
	if player_node_instance is SarGameEntityVessel3D:
		player_soul_instance.possess(player_node_instance as SarGameEntityVessel3D)

	return player_soul_instance

func _spawn_player_vessel(p_id: int) -> void:
	var spawn_parent: Node = _get_player_spawn_parent()
	
	var player_node_instance: Node = _get_player_vessel_scene().instantiate()
	assert(player_node_instance)
	
	if player_node_instance is SarGameEntityVessel3D:
		(player_node_instance as SarGameEntityVessel3D).global_transform = find_valid_spawn_transform_for_peer_entity_3d(p_id)
	
	player_node_instance.name = get_player_entity_name_prefix() + str(p_id)
	
	spawn_parent.add_child(player_node_instance)

func _unspawn_player_vessel(p_id: int) -> void:
	var spawn_parent: Node = _get_player_spawn_parent()
	var instance: Node = spawn_parent.get_node_or_null(get_player_entity_name_prefix() + str(p_id))

	instance.queue_free()
	spawn_parent.remove_child(instance)
	
func _create_scene_property(p_path: String) -> void:
	if not ProjectSettings.has_setting(p_path):
		ProjectSettings.set_setting(p_path, "")
		
	ProjectSettings.set_as_basic(p_path, true)
	ProjectSettings.set_initial_value(p_path, "")

	var property_info: Dictionary = {
		"name": p_path,
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_FILE,
		"hint_string": "*.scn,*.tscn"
	}
	
	ProjectSettings.add_property_info(property_info)
			
func _setup_project_settings() -> void:
	if not Engine.is_editor_hint():
		var player_vessel_scene_path: String = ProjectSettings.get_setting(_PLAYER_VESSEL_SCENE_PROJECT_SETTING_PATH, "")
		if not player_vessel_scene_path.is_empty():
			_player_vessel_scene = load(player_vessel_scene_path)
		
		assert(_player_vessel_scene)
		
		var player_soul_scene_path: String = ProjectSettings.get_setting(_PLAYER_SOUL_SCENE_PROJECT_SETTING_PATH, "")
		if not player_soul_scene_path.is_empty():
			_player_soul_scene = load(player_soul_scene_path)
		
		assert(_player_soul_scene)
	else:
		# Vessel
		_create_scene_property(_PLAYER_VESSEL_SCENE_PROJECT_SETTING_PATH)
		# Soul
		_create_scene_property(_PLAYER_SOUL_SCENE_PROJECT_SETTING_PATH)
		
		# Debug Window Title info
		if not ProjectSettings.has_setting(_SHOW_WINDOW_TITLE_DEBUG_INFO_PATH):
			ProjectSettings.set_setting(_SHOW_WINDOW_TITLE_DEBUG_INFO_PATH, false)
			
		ProjectSettings.set_as_basic(_SHOW_WINDOW_TITLE_DEBUG_INFO_PATH, true)
		ProjectSettings.set_initial_value(_SHOW_WINDOW_TITLE_DEBUG_INFO_PATH, "")

func _create_multiplayer_peer() -> MultiplayerPeer:
	return ENetMultiplayerPeer.new()
	
func _on_connected_to_server() -> void:
	if _should_use_window_title_debug_behaviour():
		_update_window_title()
	
func _on_connection_failed() -> void:
	if _should_use_window_title_debug_behaviour():
		_update_window_title()

func _on_peer_connect(p_id : int) -> void:
	if multiplayer.is_server():
		_spawn_player_vessel(p_id)

func _on_peer_disconnect(p_id : int) -> void:
	if multiplayer.is_server():
		_unspawn_player_vessel(p_id)
		
func _on_server_disconnected() -> void:
	pass

func _setup_multiplayer() -> void:
	# Multiplayer API
	get_tree().set_multiplayer(SarMultiplayerAPIExtension.new())
	get_tree().multiplayer_poll = true # TODO: Control this manually for timing precision

	var multiplayer_extension: SarMultiplayerAPIExtension = get_tree().get_multiplayer() as SarMultiplayerAPIExtension
	var scene_multiplayer: SceneMultiplayer = multiplayer_extension.base_multiplayer as SceneMultiplayer

	# Always disable object decoding for security reasons.
	scene_multiplayer.allow_object_decoding = false

	# Authentication
	# Create a node for authentication callbacks on multiplayer sessions.
	_authentication_node = _create_authentication_node()
	if _authentication_node:
		_authentication_node.game_session_manager = self
		_authentication_node.set_name("Authentication")
		
		scene_multiplayer.set_auth_callback(_authentication_node.auth_callback)
		assert(scene_multiplayer.peer_authenticating.connect(_authentication_node.peer_authenticating) == OK)
		assert(scene_multiplayer.peer_authentication_failed.connect(_authentication_node.peer_authentication_failed) == OK)
		
		add_child(_authentication_node)
		
		scene_multiplayer.auth_timeout = 10.0
				
	# Spawning
	_player_spawner_node = _create_player_spawner_node()
	_player_spawner_node.set_name("PlayerMultiplayerSpawner")
	add_child(_player_spawner_node)
	
	_update_player_spawn_path()

	# Peer connections
	assert(multiplayer.connected_to_server.connect(_on_connected_to_server) == OK)
	assert(multiplayer.connection_failed.connect(_on_connection_failed) == OK)

	assert(multiplayer.peer_connected.connect(_on_peer_connect) == OK)
	assert(multiplayer.peer_disconnected.connect(_on_peer_disconnect) == OK)

	assert(multiplayer.server_disconnected.connect(_on_server_disconnected) == OK)

func _enter_tree() -> void:
	if not Engine.is_editor_hint():
		add_to_group("game_session_managers")
	
	_setup_project_settings()
	
func _ready() -> void:
	if not Engine.is_editor_hint():
		_setup_multiplayer.call_deferred()

func _parse_commandline_args() -> void:
	var _commandline_argument_dictionary = SarGameSessionCommandline.parse_commandline_arguments(
		OS.get_cmdline_args()
	)
	
	if not Engine.is_editor_hint():
		pass

func _init() -> void:
	_parse_commandline_args()

###

## Called to indicate that the currently active game scene has now changed.
func notify_game_scene_changed() -> void:
	if not Engine.is_editor_hint():
		_update_player_spawn_path()
		var current_scene: Node = get_tree().current_scene
		if current_scene is SarGameScene3D:
			if (multiplayer.is_server() and not is_dedicated()) or not multiplayer.is_server():
				_local_player_soul_instance = _spawn_player_soul(multiplayer.get_unique_id())
				if multiplayer.is_server():
					_spawn_player_vessel(get_host_peer_id())
					
## Notifys the game session manager that a player vessel has just entered the game scene.
func notify_player_vessel_3d_instance_added(p_player_vessel: SarGameEntityVessel3D) -> void:
	var player_soul: SarSoul = get_local_player_soul_instance()
	if player_soul and not player_soul.is_possessing_vessel():
		if p_player_vessel.get_multiplayer_authority() == multiplayer.get_unique_id():
			player_soul.possess(p_player_vessel)

## Notifys the game session manager that a player vessel has just exited the game scene.
func notify_player_vessel_3d_instance_removed(p_player_vessel: SarGameEntityVessel3D) -> void:
	var player_soul: SarSoul = get_local_player_soul_instance()
	if player_soul and not player_soul.get_possessed_vessel() == p_player_vessel:
		if p_player_vessel.get_multiplayer_authority() == multiplayer.get_unique_id():
			player_soul.unpossess()

## Returns the name we should give to player entities which should prefix their
## peer id.
func get_player_entity_name_prefix() -> String:
	return "player_entity_"

## Returns the name we should give to player souls which should prefix their
## peer id.
func get_player_soul_name_prefix() -> String:
	return "player_soul_"

## Returns the peer id for the session host.
func get_host_peer_id() -> int:
	return _HOST_PEER_ID
	
## Returns true if we are running on a dedicated server.
func is_dedicated() -> bool:
	return _is_dedicated
	
## Returns peer id for the current session authority.
func get_session_authority_id() -> int:
	return get_host_peer_id()

## Returns a Transform3D for the peer with current id to spawn on.
func find_valid_spawn_transform_for_peer_entity_3d(_id: int) -> Transform3D:
	var player_spawns: Array[Node] = get_tree().get_nodes_in_group(_get_player_start_group_name())
	
	if player_spawns.size():
		var index: int = randi_range(0, player_spawns.size()-1)
		var spawn_3d: Node3D = player_spawns.get(index)
		if spawn_3d:
			return spawn_3d.global_transform
			
	return Transform3D()

## Returns the soul instance for the local player.
func get_local_player_soul_instance() -> SarSoul:
	return _local_player_soul_instance

## Hosts a new multiplayer server:
## p_port is the network port to host this server on.
## p_max_players is the maximum number of peers permitted to join this server.
## p_is_dedicated flags whether this should be a dedicated server and not
## to spawn a player entity and soul for the host.
func host_server(p_port: int, p_max_players: int, p_is_dedicated: bool) -> Error:
	_is_dedicated = p_is_dedicated
	_max_players = p_max_players
	
	var peer: MultiplayerPeer = _create_multiplayer_peer()
	
	var result: Error = FAILED
	if peer is ENetMultiplayerPeer:
		result  = (peer as ENetMultiplayerPeer).create_server(p_port, p_max_players)
		
	if result == OK:
		get_tree().get_multiplayer().multiplayer_peer = peer
		if _should_use_window_title_debug_behaviour():
			_update_window_title()
		
	return result

## Attempts to join a multiplayer server.
## p_address is the ip address of the server you are attempting to join.
## p_port is the network port this server is hosted on.
func join_server(p_address: String, p_port: int) -> Error:
	var peer: MultiplayerPeer = _create_multiplayer_peer()
	
	var result: Error = FAILED
	if peer is ENetMultiplayerPeer:
		result = (peer as ENetMultiplayerPeer).create_client(p_address, p_port)
		
	if result == OK:
		multiplayer.set_multiplayer_peer(peer)
		
	return result
