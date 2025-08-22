@tool
extends VSKUIViewContentMenu
class_name VSKUIViewMapMenu

var _request: SarGameServiceRequest = null

func _fetch_content() -> void:
	if _request:
		push_error("Request already in progress")
		return
	
	_clear_content()
	
	var uro: VSKGameServiceUro = _get_uro_service()
	if uro:
		var dict: Dictionary = uro.get_current_username_and_domain()
		_request = uro.create_request(dict)
		var result: Dictionary = await uro.get_maps_async(_request)
		_request = null
		if GodotUroHelper.requester_result_is_ok(result):
			if content_browser:
				var output: Dictionary = result.get("output", {})
				var data: Dictionary = output.get("data", {})
				var maps: Array = data.get("maps", [])
				for map in maps:
					if map is Dictionary:
						var url: String = "https://" + dict.get("domain", "") + map.get("user_content_preview", "")
						var button: VSKButton = content_browser.add_content_item(
							map.get("name", ""),
							url)
							
						var map_url: String = "uro://" + dict.get("domain", "") + "/" + map.get("id", "")
						if not SarUtils.assert_ok(button.pressed.connect(_content_selected.bind(map_url)),
							"Could not connect signal 'button.pressed' to '_content_selected.bind(map_url)'"):
							return

						
	else:
		push_error("Could not access Uro service for map browser.")
