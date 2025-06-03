extends "res://addons/network_manager/network_rpc_table.gd"

signal session_master_spawn(p_requester_id, p_entity_callback_id)
signal session_puppet_spawn(p_entity_callback_id)


@rpc("any_peer") func spawn_prop(p_entity_callback_id, p_prop_url) -> void:
	if NetworkManager.is_session_master():
		session_master_spawn.emit(get_remote_sender_id(), p_entity_callback_id, p_prop_url)
	else:
		if get_remote_sender_id() == NetworkManager.get_current_peer_id():
			session_puppet_spawn.emit(p_entity_callback_id, p_prop_url)
