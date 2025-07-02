@tool
extends VSKUIViewContentMenu
class_name VSKUIViewAvatarMenu

var _request: SarGameServiceRequest = null

func _fetch_content() -> void:
	if _request:
		push_error("Request already in progress")
		return
	
	_clear_content()
	
	var uro: VSKGameServiceUro = _get_uro_service()
	if uro:
		var dict: Dictionary = GodotUroHelper.get_username_and_domain_from_address(uro.get_current_account_address())
		_request = uro.create_request(dict)
		var result: Dictionary = await uro.get_dashboard_avatars_async(_request)
		_request = null
		if GodotUroHelper.requester_result_is_ok(result):
			if content_browser:
				var output: Dictionary = result.get("output", {})
				var data: Dictionary = output.get("data", {})
				var avatars: Array = data.get("avatars", [])
				for avatar in avatars:
					if avatar is Dictionary:
						var url: String = "https://" + dict.get("domain", "") + avatar.get("user_content_preview", "")
						var button: VSKButton = content_browser.add_content_item(
							avatar.get("name", ""),
							url)
							
						var avatar_url: String = "uro://" + dict.get("domain", "") + "/" + avatar.get("id", "")
						if not SarUtils.assert_ok(button.pressed.connect(_content_selected.bind(avatar_url)),
							"Could not connect signal 'button.pressed' to '_content_selected.bind(avatar_url)'"):
							return
	else:
		push_error("Could not access Uro service for avatar browser.")
