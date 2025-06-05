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

func _get_uro_service() -> VSKGameServiceUro:
	var service_manager: VSKGameServiceManager = get_tree().get_first_node_in_group("game_service_managers")
	if service_manager:
		var game_service: VSKGameServiceUro = service_manager.get_service("Uro")
		return game_service
		
	return null

func _scene_load_complete(p_packed_scene: Resource) -> void:
	navigation_controller_2d.pop_view_controller(false)
	
	assert(get_tree())
	
	if p_packed_scene is PackedScene:
		assert(get_tree())
		var scene_changed = get_tree().scene_changed
		get_tree().change_scene_to_packed(p_packed_scene)
		await scene_changed

func _sign_in_complete(p_id: String) -> void:
	_show_scene_loading_screen()

func _show_scene_loading_screen() -> void:
	var view_controller: VSKUIViewControllerSessionLoading = _SESSION_LOADING_VIEW_CONTROLLER.instantiate()
	view_controller.content_url = DEFAULT_GAME_SCENE_URL
	
	assert(get_tree())
	
	assert(view_controller.scene_loaded.connect(_scene_load_complete) == OK)
	navigation_controller_2d.push_view_controller(view_controller, false)
	
func _show_welcome_screen() -> void:
	var view_controller: VSKUIViewControllerWelcome = _WELCOME_VIEW_CONTROLLER.instantiate()
	navigation_controller_2d.push_view_controller(view_controller, false)
	
	assert(view_controller.signed_in.connect(_sign_in_complete) == OK)
	assert(view_controller.skipped.connect(_sign_in_complete.bind("")) == OK)
	
func _show_validate_screen() -> void:
	var view_controller: VSKUIViewControllerValidating = _VALIDATING_VIEW_CONTROLLER.instantiate()
	navigation_controller_2d.push_view_controller(view_controller, false)

func _fade_in_complete() -> void:
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
		
		if _skip_sign_in:
			_show_scene_loading_screen()
		else:
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
			var splits: Array = uro_id.split("@")
			if splits.size() == 2:
				_renew_uro_session_request = game_service.create_request({"username":splits[0], "domain":splits[1]})
				var result: Dictionary = await game_service.renew_session(_renew_uro_session_request)
				if GodotUroHelper.requester_result_is_ok(result):
					_skip_sign_in = true

func _ready() -> void:
	_attempt_to_renew_session()
	return

###

@export var animation_player: AnimationPlayer = null
@export var ui_parent: Control = null
