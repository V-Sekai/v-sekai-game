@tool
extends VSKUIViewControllerAccountAction
class_name VSKUIViewControllerLogin

signal signed_in(p_result: VSKUIViewControllerLoggingIn.LogInResult, p_id: String)

const _LOGGING_IN_VIEW_CONTROLLER: PackedScene = preload("res://addons/vsk_ui/view_controllers/vsk_ui_view_controller_logging_in.tscn")

@export var view_account_action: VSKUIViewAccountAction = null

func _get_uro_service() -> VSKGameServiceUro:
	var service_manager: SarGameServiceManager = get_tree().get_first_node_in_group("game_service_managers")
	if service_manager:
		var uro_service: VSKGameServiceUro = service_manager.get_service("Uro")
		return uro_service
		
	return null

func _sign_in_complete(p_result: VSKUIViewControllerLoggingIn.LogInResult, p_id: String) -> void:
	if p_result == VSKUIViewControllerLoggingIn.LogInResult.OK:
		get_navigation_controller().pop_view_controller(true)
		
		signed_in.emit(p_result, p_id)

func _on_view_sign_in_selected() -> void:
	var domain: String = view_account_action.get_domain()
	var username_or_email: String = view_account_action.get_sign_in_username_or_email()
	var password: String = view_account_action.get_sign_in_password()
	
	var view_controller: VSKUIViewControllerLoggingIn = _LOGGING_IN_VIEW_CONTROLLER.instantiate()
	
	var sign_in_data: Dictionary = {
		"domain":domain.to_lower(),
		"username_or_email":username_or_email.to_lower(),
		"password":password
	}
	
	view_controller.sign_in(_get_uro_service(), sign_in_data)
	get_navigation_controller().push_view_controller(view_controller, true)
	
	assert(view_controller.sign_in_complete.connect(_sign_in_complete) == OK)
