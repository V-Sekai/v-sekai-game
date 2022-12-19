extends Control

func _update_menu_visibility() -> void:
	# Can't call GameManager singleton directly yet due to circular dependency.
	if get_node("/root/GameManager").ingame_menu_visible:
		$ToggleMenu.show()
	else:
		$ToggleMenu.hide()

func assign_peer_color(p_color: Color) -> void:
	$PeerBoxContainer/PeerColorID.color = p_color

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("menu_toggle"):
		get_node("/root/GameManager").ingame_menu_visible = !get_node("/root/GameManager").ingame_menu_visible
		_update_menu_visibility()

func _physics_process(_delta) -> void:
	if Input.is_action_pressed("block_physics_send"):
		$InfoContainer/BlockPhysicsUpdatesInfo.set("theme_override_colors/font_color", Color.RED)
	else:
		$InfoContainer/BlockPhysicsUpdatesInfo.set("theme_override_colors/font_color", Color.WHITE)

func _ready():
	if multiplayer and multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		$PeerBoxContainer/PeerIDLabel.set_text("Peer ID: %s" % str(multiplayer.get_unique_id()))
	else:
		$PeerBoxContainer/PeerIDLabel.set_text("Peer ID: UNASSIGNED")

func _on_disconnect_button_pressed():
	get_node("/root/GameManager").close_connection()
