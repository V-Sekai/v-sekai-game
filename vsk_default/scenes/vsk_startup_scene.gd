class_name VSKStartupScene
extends Node3D

# TODO: make this nicer. This is a pretty inelegant implementation the default startup scene
# built with the intention of rapidly iterating. Once we've nailed down how this should go,
# we should probably rewrite it into something more elegant.

var _skip_sign_in: bool = false
var _renew_uro_session_request: VSKGameServiceRequestUro = null

@export var navigation_controller_2d: SarUINavigationController = null

const _WELCOME_VIEW_CONTROLLER: PackedScene = preload("res://addons/vsk_ui/view_controllers/vsk_ui_view_controller_welcome.tscn")
const _SESSION_LOADING_VIEW_CONTROLLER: PackedScene = preload("res://addons/vsk_ui/view_controllers/vsk_ui_view_controller_session_loading.tscn")
const _VALIDATING_VIEW_CONTROLLER: PackedScene = preload("res://addons/vsk_ui/view_controllers/vsk_ui_view_controller_validating.tscn")

const DEFAULT_GAME_SCENE_URL: String = "res://vsk_default/example_ugc/maps/cc0_hut/cc0_hut.tscn"
const DEFAULT_GAME_SCENE_URL_ALT: String = "res://vsk_default/example_ugc/maps/haven/haven.tscn"

func _get_uro_service() -> VSKGameServiceUro:
	var service_manager: VSKGameServiceManager = get_tree().get_first_node_in_group("game_service_managers")
	if service_manager:
		var game_service: VSKGameServiceUro = service_manager.get_service("Uro")
		return game_service
		
	return null

func _scene_load_complete(p_scene_url: String, p_packed_scene: Resource) -> void:
	navigation_controller_2d.pop_view_controller(false)
	
	if not SarUtils.assert_exists(get_tree()):
		return

	if p_packed_scene is PackedScene:
		if not SarUtils.assert_exists(get_tree()):
			return
		var game_session_manager: VSKGameSessionManager = get_tree().get_first_node_in_group("game_session_managers")
		var scene_changed = get_tree().scene_changed

		# TODO: Call set_active_map_path() from SarGameScene3D
		# _ready() or _notify_scene_changed() instead
		game_session_manager.set_active_map_path(p_scene_url)

		get_tree().change_scene_to_packed(p_packed_scene)
		await scene_changed

func _sign_in_complete(p_id: String) -> void:
	_show_scene_loading_screen()

func _skipped_complete() -> void:
	_ensure_sign_in()
	_sign_in_complete("")
	
func _ensure_sign_in() -> void:
	if _skip_sign_in:
		return

	# TODO: Domain selection UI for guest mode. Using defaults for now.
	var domain: String = ""
	var homeserver_info: VSKHomeServerInfo = load("res://addons/vsk_game_framework/data/vsk_default_homeserver_info.tres")
	if homeserver_info:
		if homeserver_info.homeserver_list.size() > 0:
			domain = homeserver_info.homeserver_list[0]
	else:
		push_error("Could not set default API domain url.")

	var game_service: VSKGameServiceUro = _get_uro_service()
	game_service.sign_in_guest(domain)

func _show_scene_loading_screen() -> void:
	var view_controller: VSKUIViewControllerSessionLoading = _SESSION_LOADING_VIEW_CONTROLLER.instantiate()
	view_controller.content_url = DEFAULT_GAME_SCENE_URL
	
	if not SarUtils.assert_exists(get_tree()):
		return

	if not SarUtils.assert_ok(view_controller.scene_loaded.connect(_scene_load_complete),
		"Could not connect signal 'view_controller.scene_loaded' to '_scene_load_complete'"):
		return

	navigation_controller_2d.push_view_controller(view_controller, false)
	
func _show_welcome_screen() -> void:
	var view_controller: VSKUIViewControllerWelcome = _WELCOME_VIEW_CONTROLLER.instantiate()
	navigation_controller_2d.push_view_controller(view_controller, false)
	
	if not SarUtils.assert_ok(view_controller.signed_in.connect(_sign_in_complete),
		"Could not connect signal 'view_controller.signed_in' to '_sign_in_complete'"):
		return
	if not SarUtils.assert_ok(view_controller.skipped.connect(_skipped_complete),
		"Could not connect signal 'view_controller.skipped' to '_skipped_complete'"):
		return

func _show_validate_screen() -> void:
	var view_controller: VSKUIViewControllerValidating = _VALIDATING_VIEW_CONTROLLER.instantiate()
	navigation_controller_2d.push_view_controller(view_controller, false)

func _fade_in_complete() -> void:
	var game_session_manager: VSKGameSessionManager = get_tree().get_first_node_in_group("game_session_managers")
	var game_service: VSKGameServiceUro = _get_uro_service()
	if game_service:
		# Wait for the renew session request to finish.
		if _renew_uro_session_request:
			var view_controller: VSKUIViewControllerValidating = _VALIDATING_VIEW_CONTROLLER.instantiate()
			navigation_controller_2d.push_view_controller(view_controller, false)
			while game_service.is_request_active(_renew_uro_session_request):
				await get_tree().process_frame
			navigation_controller_2d.pop_view_controller(false)
			view_controller.queue_free()
			_renew_uro_session_request = null
		
		var network_opts: Dictionary = game_session_manager.get_startup_network_opts()
		if network_opts.get("host", false):
			if not SarUtils.assert_ok(game_session_manager.host_server(
				network_opts["port"], network_opts["max_players"], network_opts["dedicated"], network_opts["public"], network_opts["server_name"]),
				"Server hosting failed!" + JSON.stringify(network_opts)):
				get_tree().quit(1)
			_ensure_sign_in()
			_show_scene_loading_screen()
		elif network_opts.get("join", false):
			if not SarUtils.assert_ok(game_session_manager.join_server(network_opts["address"], network_opts["port"]),
				"Server joining failed!" + JSON.stringify(network_opts)):
				get_tree().quit(1)
			_ensure_sign_in()
			_show_scene_loading_screen()
		elif _skip_sign_in:
			_show_scene_loading_screen()
		else:
			# Launch title screen
			_show_welcome_screen()

func _on_fader_animation_player_current_animation_changed(p_anim_name: String) -> void:
	match p_anim_name:
		"fade_in_complete":
			_fade_in_complete()

func _on_fader_gui_input(p_event: InputEvent) -> void:
	if p_event is InputEventJoypadButton or \
	p_event is InputEventKey or \
	p_event is InputEventMouseButton:
		if animation_player.current_animation == "fade_in":
			animation_player.play("fade_in_complete")

func _attempt_to_renew_session() -> void:
	_skip_sign_in = false
	
	var game_service: VSKGameServiceUro = _get_uro_service()
	if game_service:
		var uro_id: String = game_service.get_selected_id()
		if not uro_id.is_empty():
			var address_dictionary = GodotUroHelper.get_username_and_domain_from_address(uro_id)
			_renew_uro_session_request = game_service.create_request(address_dictionary)
			var result: Dictionary = await game_service.renew_session(_renew_uro_session_request)
			if GodotUroHelper.requester_result_is_ok(result):
				_skip_sign_in = true

func _ready() -> void:
	_attempt_to_renew_session()
	return

###

@export var animation_player: AnimationPlayer = null
@export var ui_parent: Control = null
