@tool
extends VSKUIViewControllerAccountAction
class_name VSKUIViewControllerRegister

signal signed_up(p_result: VSKUIViewControllerRegistering.RegisterResult, p_id: String)

const _REGISTERING_ACCOUNT_VIEW_CONTROLLER: PackedScene = preload("res://addons/vsk_ui/view_controllers/vsk_ui_view_controller_registering_account.tscn")

@export var view_account_action: VSKUIViewAccountAction = null

func _get_uro_service() -> VSKGameServiceUro:
	var service_manager: SarGameServiceManager = get_tree().get_first_node_in_group("game_service_managers")
	if service_manager:
		var uro_service: VSKGameServiceUro = service_manager.get_service("Uro")
		return uro_service
		
	return null

func _sign_up_complete(p_result: VSKUIViewControllerRegistering.RegisterResult, p_id: String) -> void:
	if p_result == VSKUIViewControllerRegistering.RegisterResult.OK:
		get_navigation_controller().pop_view_controller(true)
		
		signed_up.emit(p_result, p_id)

func _on_view_sign_up_selected() -> void:
	var domain: String = view_account_action.get_domain()
	var email: String = view_account_action.get_register_email()
	var username: String = view_account_action.get_register_username()
	var password: String = view_account_action.get_register_password()
	var repeat_password: String = view_account_action.get_register_repeat_password()
	var email_notifications: bool = view_account_action.get_email_notifications()

	var view_controller: VSKUIViewControllerRegistering = _REGISTERING_ACCOUNT_VIEW_CONTROLLER.instantiate()
	
	var register_data: Dictionary = {
		"domain":domain.to_lower(),
		"email":email.to_lower(),
		"username":username.to_lower(),
		"password":password,
		"repeat_password":repeat_password,
		"email_notifications":email_notifications
	}
	
	view_controller.register(_get_uro_service(), register_data)
	get_navigation_controller().push_view_controller(view_controller, true)
	
	assert(view_controller.sign_up_complete.connect(_sign_up_complete) == OK)
