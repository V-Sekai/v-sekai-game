@tool
extends SarUIViewController
class_name VSKUIViewControllerWelcome

const _LOGIN_VIEW_CONTROLLER: PackedScene = preload("res://addons/vsk_ui/view_controllers/vsk_ui_view_controller_login.tscn")
const _REGISTER_VIEW_CONTROLLER: PackedScene = preload("res://addons/vsk_ui/view_controllers/vsk_ui_view_controller_register.tscn")

signal signed_in(p_id: String)
signal skipped

func _signed_in(p_result: VSKUIViewControllerLoggingIn.LogInResult, p_id: String) -> void:
	if p_result == VSKUIViewControllerLoggingIn.LogInResult.OK:
		get_navigation_controller().pop_view_controller(true)
		signed_in.emit(p_id)

func _on_welcome_menu_sign_in_pressed() -> void:
	var view_controller: VSKUIViewControllerLogin = _LOGIN_VIEW_CONTROLLER.instantiate()
	get_navigation_controller().push_view_controller(view_controller, true)

	assert(view_controller.signed_in.connect(_signed_in) == OK)

func _on_welcome_menu_register_pressed() -> void:
	var view_controller: SarUIViewController = _REGISTER_VIEW_CONTROLLER.instantiate()
	get_navigation_controller().push_view_controller(view_controller, true)

func _on_welcome_menu_skip_pressed() -> void:
	get_navigation_controller().pop_view_controller(true)
	skipped.emit()
