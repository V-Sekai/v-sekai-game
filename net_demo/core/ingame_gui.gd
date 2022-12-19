extends Control


func _update_menu_visibility() -> void:
	# Can't call GameManager singleton directly yet due to circular dependency.
	if GameManager.ingame_menu_visible:
		$ToggleMenu.show()
	else:
		$ToggleMenu.hide()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("menu_toggle"):
		GameManager.ingame_menu_visible = !GameManager.ingame_menu_visible
		_update_menu_visibility()


func _ready():
	if multiplayer and multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		$PeerBoxContainer/PeerIDLabel.set_text("Peer ID: %s" % str(multiplayer.get_unique_id()))
	else:
		$PeerBoxContainer/PeerIDLabel.set_text("Peer ID: UNASSIGNED")


func _on_disconnect_button_pressed():
	GameManager.close_connection()
