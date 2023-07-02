# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_game_flow_manager.gd
# SPDX-License-Identifier: MIT

@tool
extends Node

var connection_util_const = preload("res://addons/gd_util/connection_util.gd")

############################
# V-Sekai Gameflow Manager #
############################

##
## The VSKGameflowManager is the highest level manager managing the lifecycle
## of the application.
##

##
## Table used to connect signals from other subsystems back as callbacks
## to this singleton.
##

var signal_table: Array = [{"singleton": "VSKGameFlowManager", "signal": "gameflow_state_changed", "method": "_gameflow_state_changed"}, {"singleton": "VSKNetworkManager", "signal": "session_ready", "method": "_session_ready"}, {"singleton": "VSKNetworkManager", "signal": "server_disconnected", "method": "_server_disconnected"}, {"singleton": "VSKNetworkManager", "signal": "connection_killed", "method": "_connection_killed"}, {"singleton": "VSKMapManager", "signal": "map_load_callback", "method": "_map_load_callback"}, {"singleton": "VSKNetworkManager", "signal": "network_callback", "method": "_network_callback"}, {"singleton": "BackgroundLoader", "signal": "thread_started", "method": "quit_callback_increment"}, {"singleton": "BackgroundLoader", "signal": "thread_ended", "method": "quit_callback_decrement"}, {"singleton": "ScreenshotManager", "signal": "screenshot_requested", "method": "_screenshot_requested"}, {"singleton": "SpatialGameViewportManager", "signal": "viewport_updated", "method": "_spatial_game_viewport_updated"}]

##
## Is responsible for recording IK as motion capture data
##
var mocap_manager: Node = null

##
## The viewport created by Node3D Game SubViewport Manager which all game world
## content is placed inside.
##
var game_viewport: SubViewport

##
## Another viewport created by Node3D Game SubViewport Manager for things like
## streaming camera.
##
var secondary_viewport: SubViewport

##
## gameroot is root node which a loaded game instantiate will be parented to
##
var gameroot: Node = null
##
## quit_callback_counter is a counter of pending tasks which must be completed
## before the application can safely quit.
##
var quit_callback_counter: int = 0

##
## If this flag is set to true, attempt to automatically quit instead of going
## to the the title screen. Used by servers and bots.
##
var autoquit: bool = false


##
## Base class for a MultiplayerRequest
##
class MultiplayerRequest:
	extends RefCounted
	var port: int = -1  # What port is the MultiplayerRequest considering
	var max_retries = 0


##
## A MultiplayerRequest for hosting a game
##
class MultiplayerRequestHost:
	extends MultiplayerRequest
	var map_path: String
	var game_mode_path: String
	var server_name: String
	var max_players: int = -1
	var dedicated_server: bool = false
	var advertise_server: bool = false


##
## A MultiplayerRequest for joining a game
##
class MultiplayerRequestJoin:
	extends MultiplayerRequest
	var ip: String


##
## The current multiplayer request
##
var multiplayer_request: MultiplayerRequest = null

##
## Enum determining what state the apps gameflow is in.
##
enum { GAMEFLOW_STATE_UNDEFINED, GAMEFLOW_STATE_PRELOADING, GAMEFLOW_STATE_TITLE, GAMEFLOW_STATE_INTERSTITIAL, GAMEFLOW_STATE_INGAME }  # Unknown gameflow state  # When we are in the preloading screen before the title  # When we are in the title  # When we are in the loading screen  # When we are connected to a server

##
## Enum indicating an error from another subsystem telling us what kind
## of error message we should display.
##
enum { CALLBACK_STATE_NONE, CALLBACK_STATE_KICKED_FROM_SERVER, CALLBACK_STATE_SERVER_DISCONNECTED, CALLBACK_STATE_MAP_UNKNOWN_FAILURE, CALLBACK_STATE_MAP_NETWORK_FETCH_FAILED, CALLBACK_STATE_MAP_RESOURCE_FAILED_TO_LOAD, CALLBACK_STATE_MAP_NOT_WHITELISTED, CALLBACK_STATE_MAP_FAILED_VALIDATION, CALLBACK_STATE_GAME_MODE_LOAD_FAILED, CALLBACK_STATE_GAME_MODE_NOT_WHITELISTED, CALLBACK_STATE_HOST_GAME_FAILED, CALLBACK_STATE_SHARD_REGISTRATION_FAILED, CALLBACK_STATE_INVALID_MAP, CALLBACK_STATE_NO_SERVER_INFO, CALLBACK_STATE_NO_SERVER_INFO_VERSION, CALLBACK_STATE_SERVER_INFO_VERSION_MISMATCH }

##
## Enum indicating the the transition between an ingame and non-ingame state
##
enum { NO_INGAME_STATE_CHANGED, INGAME_STARTED, INGAME_ENDED }

##
## Are we requesting to quit the application
##
var quit_flag: bool = false

##
## Current external subsystem callback state
##
var callback_state: int = CALLBACK_STATE_NONE
var callback_dictionary: Dictionary = {}


func set_callback_state(p_new_callback_state: int, p_new_callback_dictionary: Dictionary) -> void:
	if quit_flag:
		return

	callback_state = p_new_callback_state
	callback_dictionary = p_new_callback_dictionary


##
## Current gameflow state. Its setter will also check the current gameflow
## state to determine if it has changed, and if it has, emit the
## gameflow_state_changed signal. Also checks if we have gone ingame or
## exited ingame and emits an appropriate signal.
##
var gameflow_state: int = GAMEFLOW_STATE_UNDEFINED:
	set = set_gameflow_state


func set_gameflow_state(p_new_gameflow_state: int) -> void:
	if quit_flag:
		return

	EntityManager.stop()

	if gameflow_state == p_new_gameflow_state:
		return

	var ingame_state_change: int = NO_INGAME_STATE_CHANGED

	if gameflow_state == GAMEFLOW_STATE_INGAME:
		ingame_state_change = INGAME_ENDED
	else:
		if p_new_gameflow_state == GAMEFLOW_STATE_INGAME:
			ingame_state_change = INGAME_STARTED
			EntityManager.start()

	gameflow_state = p_new_gameflow_state

	gameflow_state_changed.emit(gameflow_state)
	match ingame_state_change:
		INGAME_STARTED:
			ingame_started.emit()
		INGAME_ENDED:
			ingame_ended.emit()

	_entering_game_state(gameflow_state)


signal gameflow_state_changed(p_state)
signal map_loaded
signal server_hosted
signal ingame_started
signal ingame_ended
signal is_pre_quitting
signal is_quitting


##
##
##
func save_changes() -> void:
	VSKAudioManager.set_settings_values_and_save()
	VSKAvatarManager.set_settings_values_and_save()
	VSKPlayerManager.set_settings_values_and_save()


##
## Called when an external task is being preformed. Blocks the application from
## safely quitting until the quit_callback_counter has returned to 0.
##
func quit_callback_increment() -> void:
	quit_callback_counter += 1


##
## Called when an external task has completed. Decrements the quit_callback_counter,
## and force quits the app if the quit_flag has been set and it reaches 0.
##
func quit_callback_decrement() -> void:
	quit_callback_counter -= 1

	if quit_callback_counter < 0:
		assert(false, "quit callback underflow!")

	if quit_flag and quit_callback_counter == 0:
		force_quit()


##
## Called to cancel the active map load task and destroy the current map.
##
func cancel_map_load() -> void:
	VSKMapManager.cancel_map_load()
	VSKMapManager.destroy_map()


##
## Called to request the transfer to the preloading state
##
func go_to_preloading() -> void:
	if quit_flag:
		return

	set_gameflow_state(GAMEFLOW_STATE_PRELOADING)
	VSKNetworkManager.force_disconnect()


##
## Called to request the transfer to the ingame state
## p_fade_skipped indicates that the crossfade to go ingame was skipped.
##
func go_to_ingame(p_fade_skipped: bool) -> void:
	if quit_flag:
		return

	set_gameflow_state(GAMEFLOW_STATE_INGAME)

	if !p_fade_skipped:
		var _skipped: bool = await VSKFadeManager.execute_fade(true).fade_complete


##
## Called to request the transfer to the title state
## p_fade_skipped indicates that the crossfade to go ingame was skipped.
##
func go_to_title(p_fade_skipped: bool) -> void:
	if quit_flag:
		return

	set_gameflow_state(GAMEFLOW_STATE_TITLE)

	VSKNetworkManager.force_disconnect()

	if autoquit:
		request_quit()

	if !p_fade_skipped:
		var _skipped: bool = await VSKFadeManager.execute_fade(true).fade_complete


##
## Called to request the transfer to the connecting/loading state
## p_fade_skipped indicates that the crossfade to go ingame was skipped.
##
func go_to_interstitial_screen() -> void:
	if quit_flag:
		return

	var skipped: bool = await VSKFadeManager.execute_fade(false).fade_complete
	if quit_flag:
		return

	set_gameflow_state(GAMEFLOW_STATE_INTERSTITIAL)

	VSKNetworkManager.force_disconnect()

	if !skipped:
		skipped = await VSKFadeManager.execute_fade(true).fade_complete


##
## Called to request a server to be hosted.
## p_server_name is the advertised name of the server
## p_map_path is the URL to the map this server should use
## p_port is what port this server should be hosted on
## p_max_players is the maximum amount of players allowed in this server
## p_dedicated_server denotes whether this server should be hosted without
## the host spawning their own player instantiate
## p_advertise_server tells whether we should attempt to register this server
## on a master server
##
func host_server(p_server_name: String, p_map_path: String, p_game_mode_path: String, p_port: int, p_max_players: int, p_dedicated_server: bool, p_advertise_server: bool, p_max_retries: int) -> void:
	if quit_flag:
		return

	multiplayer_request = MultiplayerRequestHost.new()
	multiplayer_request.port = p_port
	multiplayer_request.map_path = p_map_path
	multiplayer_request.game_mode_path = p_game_mode_path
	multiplayer_request.server_name = p_server_name
	multiplayer_request.max_players = p_max_players
	multiplayer_request.dedicated_server = p_dedicated_server
	multiplayer_request.advertise_server = p_advertise_server
	multiplayer_request.max_retries = p_max_retries

	await go_to_interstitial_screen()


##
## Called to request joining a server on a specific ip and port
## p_ip is the server's IP address
## p_port is the server's port
##
func join_server(p_ip: String, p_port: int) -> void:
	if quit_flag:
		return

	multiplayer_request = MultiplayerRequestJoin.new()
	multiplayer_request.ip = p_ip
	multiplayer_request.port = p_port

	await go_to_interstitial_screen()


##
## Callback function to the VSKNetworkManager to when a network request has completed.
## p_callback indicates the result.
##
func _network_callback(p_callback: int, p_callback_dictionary: Dictionary) -> void:
	if quit_flag:
		return

	var return_to_title: bool = false

	match p_callback:
		VSKNetworkManager.HOST_GAME_OKAY:
			server_hosted.emit()
		VSKNetworkManager.HOST_GAME_FAILED:
			set_callback_state(CALLBACK_STATE_HOST_GAME_FAILED, p_callback_dictionary)
			return_to_title = true
		VSKNetworkManager.SHARD_REGISTRATION_FAILED:
			set_callback_state(CALLBACK_STATE_SHARD_REGISTRATION_FAILED, p_callback_dictionary)
			return_to_title = true
		VSKNetworkManager.INVALID_MAP:
			set_callback_state(CALLBACK_STATE_INVALID_MAP, p_callback_dictionary)
			return_to_title = true
		VSKNetworkManager.NO_SERVER_INFO:
			set_callback_state(CALLBACK_STATE_NO_SERVER_INFO, p_callback_dictionary)
			return_to_title = true
		VSKNetworkManager.NO_SERVER_INFO_VERSION:
			set_callback_state(CALLBACK_STATE_NO_SERVER_INFO_VERSION, p_callback_dictionary)
			return_to_title = true
		VSKNetworkManager.SERVER_INFO_VERSION_MISMATCH:
			set_callback_state(CALLBACK_STATE_SERVER_INFO_VERSION_MISMATCH, p_callback_dictionary)
			return_to_title = true

	if return_to_title:
		await go_to_title(false)


##
## Callback function for when a new gameflow state is about to be entered
##
func _entering_game_state(p_gameflow_state: int) -> void:
	VSKMenuManager.clear()

	var is_menu_state: bool = false
	var is_game_state: bool = false

	match p_gameflow_state:
		GAMEFLOW_STATE_PRELOADING:
			is_menu_state = true
			VSKMenuManager.setup_outgame()
			VSKMenuManager.setup_preloading_screen()
		GAMEFLOW_STATE_TITLE:
			if not is_game_state:
				is_menu_state = true
				VSKMenuManager.setup_outgame()
			VSKMenuManager.setup_title_screen()
		GAMEFLOW_STATE_INTERSTITIAL:
			is_menu_state = true
			VSKMenuManager.setup_outgame()
			VSKMenuManager.setup_loading_screen()
		GAMEFLOW_STATE_INGAME:
			is_menu_state = false
			is_game_state = true
			VSKMenuManager.setup_ingame()

	if is_menu_state:
		VSKMenuManager.show_menu()
		VRManager.set_origin_world_scale(1.0)
	else:
		VSKMenuManager.hide_menu()


##
## Called whenever the network connection is killed, checking if there is
## a pending multiplayer host or join request.
##
func _process_multiplayer_request() -> void:
	if gameflow_state == GAMEFLOW_STATE_INTERSTITIAL:
		if multiplayer_request:
			if multiplayer_request is MultiplayerRequestHost:
				await (VSKNetworkManager.host_game(multiplayer_request.server_name, multiplayer_request.map_path, multiplayer_request.game_mode_path, multiplayer_request.port, multiplayer_request.max_players, multiplayer_request.dedicated_server, multiplayer_request.advertise_server, multiplayer_request.max_retries))
			elif multiplayer_request is MultiplayerRequestJoin:
				VSKNetworkManager.join_game(multiplayer_request.ip, multiplayer_request.port)


##
## Callback function to the VSKNetworkManager for when the network connection has
## been killed
##
func _connection_killed() -> void:
	cancel_map_load()
	await _process_multiplayer_request()


##
## Callback function connected to the VSKMapManager which is called
## when a map load is finished loading. If the map asset did not load correctly,
## the callback_state is set and the user will be sent back to the menu with
## an appropriate error message.
## p_callback is the VSKAssetManager callback enum which denotes the result
## of the map load.
##
func _map_load_callback(p_callback: int, p_callback_dictionary: Dictionary) -> void:
	if quit_flag:
		return

	var return_to_menu: bool = false

	match p_callback:
		VSKAssetManager.ASSET_OK:
			map_loaded.emit()
		VSKAssetManager.ASSET_UNKNOWN_FAILURE:
			set_callback_state(CALLBACK_STATE_MAP_UNKNOWN_FAILURE, p_callback_dictionary)
			return_to_menu = true
		VSKAssetManager.ASSET_UNAUTHORIZED:
			set_callback_state(CALLBACK_STATE_MAP_NETWORK_FETCH_FAILED, p_callback_dictionary)
			return_to_menu = true
		VSKAssetManager.ASSET_FORBIDDEN:
			set_callback_state(CALLBACK_STATE_MAP_NETWORK_FETCH_FAILED, p_callback_dictionary)
			return_to_menu = true
		VSKAssetManager.ASSET_INVALID:
			set_callback_state(CALLBACK_STATE_MAP_NETWORK_FETCH_FAILED, p_callback_dictionary)
			return_to_menu = true
		VSKAssetManager.ASSET_NOT_FOUND:
			set_callback_state(CALLBACK_STATE_MAP_NETWORK_FETCH_FAILED, p_callback_dictionary)
			return_to_menu = true
		VSKAssetManager.ASSET_NOT_WHITELISTED:
			set_callback_state(CALLBACK_STATE_MAP_NOT_WHITELISTED, p_callback_dictionary)
			return_to_menu = true
		VSKAssetManager.ASSET_FAILED_VALIDATION_CHECK:
			set_callback_state(CALLBACK_STATE_MAP_FAILED_VALIDATION, p_callback_dictionary)
			return_to_menu = true
		VSKAssetManager.ASSET_RESOURCE_LOAD_FAILED:
			set_callback_state(CALLBACK_STATE_MAP_RESOURCE_FAILED_TO_LOAD, p_callback_dictionary)
			return_to_menu = true
		_:
			set_callback_state(CALLBACK_STATE_MAP_UNKNOWN_FAILURE, p_callback_dictionary)
			return_to_menu = true
			assert(false, "Unknown map_load_callback")

	if return_to_menu:
		await go_to_title(false)


##
## Callback function connected to the VSKNetworkManager which is called when
## the server finished loading the current map and is ready to sync server
## state to peers or the client has received the server state and is about
## to enter the current map
##
func _session_ready(p_fade_skipped: bool) -> void:
	if quit_flag:
		return

	if multiplayer_request:
		if multiplayer_request is MultiplayerRequestHost:
			await go_to_ingame(p_fade_skipped)
		elif multiplayer_request is MultiplayerRequestJoin:
			await go_to_ingame(p_fade_skipped)


##
## Callback function for when the gameflow state has changed.
## p_gameflow_state is the gameflow state enum which denotes what the
## gameflow state should be.
##
func _gameflow_state_changed(_gameflow_state: int) -> void:
	if quit_flag:
		return


##
## Callback function for when the connection to the server was disconnected.
## Sends the player back to the title screen.
##
func _server_disconnected() -> void:
	set_callback_state(CALLBACK_STATE_SERVER_DISCONNECTED, {})
	await go_to_title(false)


##
## Forces the game to quit regardless of whether state has been saved.
##
func force_quit() -> void:
	if !Engine.is_editor_hint():
		get_tree().quit()


##
## Called to signal to other subsystems that the game is to be shutdown.
## Also sets the quit flag which is checked by other systems to check if the
## game is indeed shutting down.
##
func request_quit() -> void:
	if quit_flag:
		return

	VSKServiceManager.shutdown_services()

	save_changes()

	if !Engine.is_editor_hint():
		is_pre_quitting.emit()
		is_quitting.emit()
		quit_flag = true  # See you, space cowboy
		if quit_callback_counter <= 0:
			force_quit()


##
## Assigns custom inputs and callbacks to the InputManager singleton.
##
func _setup_input_manager() -> void:
	InputManager.add_new_axes("move_vertical", "move_forwards", "move_backwards", 0.0, 0.0, 1.0, false, InputManager.InputAxis.TYPE_ACTION, 0)
	InputManager.add_new_axes("move_horizontal", "move_right", "move_left", 0.0, 0.0, 1.0, false, InputManager.InputAxis.TYPE_ACTION, 0)
	InputManager.add_new_axes("mouse_x", "", "", 0.0, 0.0, 0.01, false, InputManager.InputAxis.TYPE_MOUSE_MOTION, 0)
	InputManager.add_new_axes("mouse_y", "", "", 0.0, 0.0, 0.01, false, InputManager.InputAxis.TYPE_MOUSE_MOTION, 1)
	InputManager.add_new_axes("look_vertical", "look_up", "look_down", 0.0, 0.0, 0.1, false, InputManager.InputAxis.TYPE_ACTION)
	InputManager.add_new_axes("look_horizontal", "look_right", "look_left", 0.0, 0.0, 0.1, false, InputManager.InputAxis.TYPE_ACTION)

	InputManager.assign_get_settings_value_funcref(VSKUserPreferencesManager, "get_value")
	InputManager.assign_set_settings_value_funcref(VSKUserPreferencesManager, "set_value")
	InputManager.assign_save_settings_funcref(VSKUserPreferencesManager, "save_settings")

	InputManager.get_settings_values()


##
## Assigns callbacks to the GraphicsManager singleton.
##
func _setup_graphics_manager() -> void:
	GraphicsManager.assign_get_settings_value_funcref(VSKUserPreferencesManager, "get_value")
	GraphicsManager.assign_set_settings_value_funcref(VSKUserPreferencesManager, "set_value")
	GraphicsManager.assign_save_settings_funcref(VSKUserPreferencesManager, "save_settings")

	GraphicsManager.get_settings_values()


##
## Assigns callbacks to the VRManager singleton.
##
func _setup_vr_manager() -> void:
	VRManager.vr_user_preferences.assign_get_settings_value_funcref(VSKUserPreferencesManager, "get_value")
	VRManager.vr_user_preferences.assign_set_settings_value_funcref(VSKUserPreferencesManager, "set_value")
	VRManager.vr_user_preferences.assign_save_settings_funcref(VSKUserPreferencesManager, "save_settings")

	VRManager.vr_user_preferences.get_settings_values()

	VRManager.initialise_vr_interface()


##
## Assigns callbacks to the MocapManager singleton.
##
func _setup_mocap_manager() -> void:
	if not has_node("/root/MocapManager"):
		return
	mocap_manager.assign_get_settings_value_funcref(VSKUserPreferencesManager, "get_value")
	mocap_manager.assign_set_settings_value_funcref(VSKUserPreferencesManager, "set_value")
	mocap_manager.assign_save_settings_funcref(VSKUserPreferencesManager, "save_settings")

	mocap_manager.get_settings_values()


##
## Callback for when a spatial game viewport has been updated
##
func _spatial_game_viewport_updated(p_viewport: SubViewport):
	if p_viewport == game_viewport:
		FlatViewport.texture_rect_ingame.texture = game_viewport.get_texture()


func set_viewport(new_viewport: SubViewport) -> void:
	game_viewport = new_viewport
	if game_viewport.get_parent() != null:
		game_viewport.get_parent().remove_child(game_viewport)
	add_child(game_viewport, true)
	game_viewport.owner = self
	FlatViewport.texture_rect_ingame.texture = game_viewport.get_texture()
	var viewport_path = game_viewport.owner.get_path_to(game_viewport)
	FlatViewport.texture_rect_ingame.texture.viewport_path = viewport_path

##
## Creates a secondary viewport for the gameroot.
##
func _setup_viewports() -> void:
	if !game_viewport:
		game_viewport = SpatialGameViewportManager.create_spatial_game_viewport()
		add_child(game_viewport, true)
		game_viewport.owner = self
	FlatViewport.texture_rect_ingame.texture = game_viewport.get_texture()
	var viewport_path = game_viewport.owner.get_path_to(game_viewport)
	FlatViewport.texture_rect_ingame.texture.viewport_path = viewport_path

	if !secondary_viewport:
		secondary_viewport = SpatialGameViewportManager.create_spatial_secondary_viewport()
		add_child(secondary_viewport, true)
		secondary_viewport.owner = self

	if !gameroot:
		gameroot = Node3D.new()
		gameroot.set_name("Gameroot")

	if gameroot.is_inside_tree():
		gameroot.get_parent().remove_child(gameroot)

	game_viewport.add_child(gameroot, true)
	FlatViewport.texture_rect_ingame.visible = true

	SpatialGameViewportManager.update_viewports()


##
## Runs setup phase on EntityManager
##
func _setup_entity_manager() -> void:
	EntityManager.setup()


##
## Assigns the gameroot reference to the other subsystems
##
func _assign_gameroots() -> void:
	VSKMapManager.gameroot = gameroot
	VSKNetworkManager.gameroot = gameroot
	NetworkManager.gameroot = gameroot


##
## Connects the is_quitting signal to is_quitting methods in varous other subsystems
##
func _connect_pre_quitting_signals() -> void:
	if connect("is_pre_quitting", BackgroundLoader.is_quitting) != OK:
		printerr("Could not connect is_quitting for BackgroundLoader")
	if connect("is_pre_quitting", InputManager.is_quitting) != OK:
		printerr("Could not connect is_quitting InputManager")
	if connect("is_pre_quitting", VRManager.is_quitting) != OK:
		printerr("Could not connect is_quitting VRManager")
	if connect("is_pre_quitting", GraphicsManager.is_quitting) != OK:
		printerr("Could not connect is_quitting GraphicsManager")
	if not mocap_manager:
		return
	if connect("is_pre_quitting", mocap_manager.is_quitting) != OK:
		printerr("Could not connect is_quitting MocapManager")


##
## When the screenshot manager requests a screenshot
##
func _screenshot_requested(p_info: Dictionary, p_callback: Callable) -> void:
	get_viewport().set_clear_mode(SubViewport.CLEAR_MODE_ONCE)
	await get_tree().process_frame
	await get_tree().process_frame
	var image: Image = get_viewport().get_texture().get_data()
	p_callback.call(p_info, image)


########
# Node #
########


func _input(p_event: InputEvent) -> void:
	if quit_flag:
		return

	if p_event.is_action_released("ui_cancel") and gameflow_state == GAMEFLOW_STATE_INGAME:
		await go_to_title(false)
	elif p_event.is_action_released("ui_cancel") and gameflow_state == GAMEFLOW_STATE_TITLE:
		await go_to_title(false)

	# Send input events to game viewport
	if game_viewport:
		game_viewport.push_input(p_event)


func _notification(p_notification: int) -> void:
	match p_notification:
		NOTIFICATION_WM_CLOSE_REQUEST:
			if !Engine.is_editor_hint():
				request_quit()


func setup() -> void:
	if Engine.is_editor_hint():
		return
	get_tree().set_auto_accept_quit(false)
	get_tree().set_quit_on_go_back(false)

	VSKAccountManager.call("start_session")

	_setup_input_manager()
	_setup_graphics_manager()
	_setup_vr_manager()
	_setup_mocap_manager()
	connection_util_const.connect_signal_table(signal_table, self)

	_setup_viewports()
	_assign_gameroots()
	_connect_pre_quitting_signals()

	_setup_entity_manager()

	if has_node("/root/MocapManager"):
		mocap_manager = get_node_or_null("/root/MocapManager")


func _ready():
	if !Engine.is_editor_hint():
		set_process_input(true)
	else:
		set_process_input(false)
