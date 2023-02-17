extends Control


func _update_menu_visibility() -> void:
	$ToggleMenu.show()


func _ready() -> void:
	if (
		multiplayer
		and multiplayer.has_multiplayer_peer()
		and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED
	):
		$PeerBoxContainer/PeerIDLabel.set_text("Peer ID: %s" % str(multiplayer.get_unique_id()))
	else:
		$PeerBoxContainer/PeerIDLabel.set_text("Peer ID: UNASSIGNED")


func _on_disconnect_button_pressed() -> void:
	$"/root/GameManager".close_connection()
