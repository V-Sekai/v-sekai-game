extends Control
class_name VSKUIViewQuickMenu

var _next_update_time: float = 0.0

signal explore_menu_requested
signal avatar_menu_requested

func _is_xr_enabled() -> bool:
	return XRServer.primary_interface != null

func _on_explore_button_pressed() -> void:
	explore_menu_requested.emit()


func _on_avatars_button_pressed() -> void:
	avatar_menu_requested.emit()


func _on_props_button_pressed() -> void:
	pass # Replace with function body.


func _on_social_button_pressed() -> void:
	pass # Replace with function body.


func _on_settings_button_pressed() -> void:
	pass # Replace with function body.


func _on_more_button_pressed() -> void:
	pass # Replace with function body.

func _on_respawn_button_pressed() -> void:
	respawn_pressed.emit()

func _update_account_name() -> void:
	var game_service_manager: SarGameServiceManager = get_tree().get_first_node_in_group("game_service_managers")
	if game_service_manager:
		var uro: VSKGameServiceUro = game_service_manager.get_service("Uro")
		if uro:
			if account_label:
				var account_name: String = uro.get_current_account_address()
				if account_name:
					account_label.text = "%s" % uro.get_current_account_address()
				else:
					account_label.text = "[b]Not Logged in[/b]"

func _update_time_label() -> void:
	if time_label:
		time_label.text = Time.get_time_string_from_system(false)
		
func _update_button_visibility() -> void:
	if _is_xr_enabled():
		if calibrate_button:
			calibrate_button.show()
		if standing_sitting_button:
			standing_sitting_button.show()
	else:
		if calibrate_button:
			calibrate_button.hide()
		if standing_sitting_button:
			standing_sitting_button.hide()

func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		if get_viewport().mode == Window.Mode.MODE_MINIMIZED:
			return
		
		# TODO: Find out why are we using floats for this?
		var unix_time: float = floor(Time.get_unix_time_from_system())
		if unix_time >= _next_update_time:
			_update_time_label()
			_next_update_time = unix_time + 1.0

func _ready() -> void:
	if not Engine.is_editor_hint():
		_update_account_name()
		_update_time_label()
		
		_update_button_visibility()

###

@export var calibrate_button: BaseButton = null
@export var standing_sitting_button: BaseButton = null

signal respawn_pressed

@export var account_label: RichTextLabel = null
@export var time_label: Label = null
