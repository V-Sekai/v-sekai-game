extends Node

var ingame_menu_visible: bool = false:
	set(value):
		ingame_menu_visible = value
		if ingame_menu_visible or is_dedicated_server:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

# The node which all the player scenes are parented to
var player_parent_scene: Node3D = null

const player_spawner_const = preload("player_spawner.tscn")
var player_spawner: MultiplayerSpawner = null

# This list of active players in this session (including self and peers)
var player_list: Array = []

# This is only known to the host and indicates they should not spawn a player
var is_dedicated_server: bool = false

signal player_spawned(p_peer_id)
signal player_unspawned(p_peer_id)

func add_player_to_list(p_id: int) -> void:
	player_list.push_back(p_id)
	player_spawned.emit(p_id)
	
func remove_player_from_list(p_id: int) -> void:
	player_list.erase(p_id)
	player_unspawned.emit(p_id)

func is_movement_locked() -> bool:
	if ingame_menu_visible == true:
		return true
	else:
		return false

func is_session_authority(p_peer_id: int) -> bool:
	if p_peer_id == 1:
		return true
		
	# If the peer is not peer 1, the authority is always the first player in the list
	if player_list.find(p_peer_id) == 0:
		return true
		
	return false
	
# Picks a player to be designated as the authority for the session, who will have the final say on authority claims.
func get_session_authority() -> int:
	if player_list.size() > 0:
		return player_list[0]
		
	return 1

func load_main_menu_scene() -> void:
	assert(get_tree().change_scene_to_file("res://net_demo/uiux/main_menu.tscn") == OK)
	ingame_menu_visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func load_default_scene() -> void:
	assert(get_tree().change_scene_to_file("res://net_demo/scenes/SCENE_game_map.tscn") == OK)
	ingame_menu_visible = false
	
func get_random_spawn_point() -> Transform3D:
	var spawn_points: Array = get_tree().get_nodes_in_group("spawners")
	assert(spawn_points.size() > 0)
	
	var spawn_point_transform: Transform3D = spawn_points[randi_range(0, spawn_points.size()-1)].global_transform

	return spawn_point_transform
	
func _update_window_title() -> void:
	var window: Window = get_viewport()
	if window:
		var project_settings_title: String = ProjectSettings.get_setting("application/config/name")
		
		var peer: MultiplayerPeer = multiplayer.multiplayer_peer
		if peer:
			window.title = project_settings_title + (" (peer_id: %s)" % multiplayer._get_unique_id_string())
		else:
			window.title = project_settings_title

func _server_hosted() -> void:
	if !is_dedicated_server:
		var spawn_point_transform: Transform3D = get_random_spawn_point()
		var _new_player: Node = player_spawner.spawn(player_spawner.get_player_spawn_buffer(1, spawn_point_transform))
		
func _on_connected_to_server() -> void:
	print(str(multiplayer.get_unique_id()) + ": _on_connected_to_server")
	
	load_default_scene()
	
	_update_window_title()
	
func _on_connection_failed() -> void:
	print(str(multiplayer.get_unique_id()) + ": _on_connection_failed")
	
	_update_window_title()
	load_main_menu_scene()

func _on_peer_connect(p_id : int) -> void:
	print(str(multiplayer.get_unique_id()) + ": _on_peer_connect(%s)" % str(p_id))
	if multiplayer.is_server():
		var spawn_point_transform: Transform3D = get_random_spawn_point()
		var _new_player: Node = player_spawner.spawn(player_spawner.get_player_spawn_buffer(p_id, spawn_point_transform))

func _on_peer_disconnect(p_id : int) -> void:
	print(str(multiplayer.get_unique_id()) + ": _on_peer_disconnect(%s)" % str(p_id))
	if multiplayer.is_server():
		MultiplayerColorTable.erase_multiplayer_peer_id(p_id)
		var player_instance: Node3D = player_parent_scene.get_node_or_null("PlayerController_" + str(p_id))
		if player_instance:
			player_instance.queue_free()
			player_parent_scene.remove_child(player_instance)
	
	remove_player_from_list(p_id)

func _on_server_disconnected() -> void:
	print(str(multiplayer.get_unique_id()) + ": _on_server_disconnected")
	MultiplayerColorTable.clear_multiplayer_color_table()
	load_main_menu_scene()
		
func host_server(p_port: int, p_max_players: int, p_dedicated: bool) -> void:
	MultiplayerColorTable.reset_colors()
	
	assert(p_max_players < MultiplayerColorTable.multiplayer_materials.size())
	
	player_list = []
	is_dedicated_server = p_dedicated
	var peer: MultiplayerPeer = ENetMultiplayerPeer.new()
	if peer.create_server(p_port, p_max_players) == OK:
		multiplayer.multiplayer_peer = peer
	
		_update_window_title()
		load_default_scene()
		call_deferred("_server_hosted")
	else:
		load_main_menu_scene()
	
func join_server(p_address: String, p_port: int) -> void:
	MultiplayerColorTable.reset_colors()
	
	player_list = []
	var peer = ENetMultiplayerPeer.new()
	if peer.create_client(p_address, p_port) == OK:
		multiplayer.multiplayer_peer = peer
	else:
		load_main_menu_scene()
	
func close_connection() -> void:
	# Destroy all players
	var players: Array = player_parent_scene.get_children()
	for player in players:
		player.queue_free()
		player_parent_scene.remove_child(player)
		
	if multiplayer and multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_DISCONNECTED:
		multiplayer.multiplayer_peer.close()
		multiplayer.set_multiplayer_peer(null)
		
	MultiplayerColorTable.clear_multiplayer_color_table()
		
	_update_window_title()
	load_main_menu_scene()
	
func get_multiplayer_id() -> int:
	if multiplayer and multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		return multiplayer.get_unique_id()
		
	return -1
	
func _ready() -> void:
	randomize()
	
	get_tree().set_multiplayer(MultiplayerExtension.new())
	
	_update_window_title()
	
	player_spawner = player_spawner_const.instantiate()
	player_spawner.name = "PlayerSpawner"
	add_child(player_spawner)
	
	player_parent_scene = Node3D.new()
	player_parent_scene.name = "Players"
	add_child(player_parent_scene)
	
	player_spawner.spawn_path = player_spawner.get_path_to(player_parent_scene)
	
	assert(multiplayer.connected_to_server.connect(_on_connected_to_server) == OK)
	assert(multiplayer.connection_failed.connect(_on_connection_failed) == OK)
	assert(multiplayer.peer_connected.connect(_on_peer_connect) == OK)
	assert(multiplayer.peer_disconnected.connect(_on_peer_disconnect) == OK)
	assert(multiplayer.server_disconnected.connect(_on_server_disconnected) == OK)
	
	Performance.add_custom_monitor("NetworkID", get_multiplayer_id, [])
