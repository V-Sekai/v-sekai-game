@tool
extends Control
class_name VSKUIViewAccountAction

@export var _action_label: Label = null
@export var _domain_label: Label = null
@export var _sign_in_content: Control = null
@export var _register_content: Control = null

@export var _sign_in_email_or_username_field: LineEdit = null
@export var _sign_in_password_field: LineEdit = null
@export var _sign_in_submit_button: BaseButton = null

signal sign_in_selected
signal pick_other_domain_selected

func _pick_other_domain_selected() -> void:
	pick_other_domain_selected.emit()

func _update_state() -> void:
	if not is_node_ready():
		await ready
	
	match account_action:
		AccountAction.REGISTER:
			if _action_label:
				_action_label.text = "Register account on:"
			if _register_content:
				_register_content.show()
			if _sign_in_content:
				_sign_in_content.hide()
		AccountAction.SIGN_IN:
			if _action_label:
				_action_label.text = "Signing into:"
			if _register_content:
				_register_content.hide()
			if _sign_in_content:
				_sign_in_content.show()
	
func _validate_sign_in_submit_button_state() -> void:
	if not Engine.is_editor_hint():
		if _sign_in_email_or_username_field.text.length() > 0 and \
		_sign_in_password_field.text.length() > 0:
			_sign_in_submit_button.disabled = false
		else:
			_sign_in_submit_button.disabled = true

func _on_sign_in_email_or_username_text_changed(_new_text: String) -> void:
	if not Engine.is_editor_hint():
		_validate_sign_in_submit_button_state()


func _on_sign_in_password_text_changed(_new_text: String) -> void:
	if not Engine.is_editor_hint():
		_validate_sign_in_submit_button_state()

func _on_sign_in_button_pressed() -> void:
	sign_in_selected.emit()

func _ready() -> void:
	if not Engine.is_editor_hint():
		var homeserver_url: String = ProjectSettings.get_setting("services/uro/host", "")
			
		if homeserver_url.is_empty():
			if homeserver_info:
				if homeserver_info.homeserver_list.size() > 0:
					set_domain(homeserver_info.homeserver_list[0])
		else:
			set_domain(homeserver_url)
			
		_validate_sign_in_submit_button_state()
			
	_update_state()

###

@export var homeserver_info: VSKHomeServerInfo = null

enum AccountAction {
	SIGN_IN,
	REGISTER,
}

## The type of account for this view.
@export var account_action: AccountAction = AccountAction.SIGN_IN:
	set(p_account_action):
		account_action = p_account_action
		_update_state()
		
## Sets the domain url for this account action view.
func set_domain(p_url: String) -> void:
	if not is_node_ready():
		await ready
		
	if not Engine.is_editor_hint():
		ProjectSettings.set_setting("services/uro/host", p_url)
		
	_domain_label.text = p_url
	
## Returns the domain url for this account action view.
func get_domain() -> String:
	return _domain_label.text
	
## Returns the text in the username or email sign in field.
func get_sign_in_username_or_email() -> String:
	return _sign_in_email_or_username_field.text
	
## Returns the text in the password sign in field.
func get_sign_in_password() -> String:
	return _sign_in_password_field.text
	
