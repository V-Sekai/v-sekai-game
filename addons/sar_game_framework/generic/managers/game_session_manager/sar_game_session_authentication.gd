@tool
extends Node
class_name SarGameSessionAuthentication

var game_session_manager: SarGameSessionManager = null

# This dictionary tracks the current state of the peers who
# have not fully authenticated.
var authentication_peers_state_table: Dictionary = {}

enum AuthenticationStage {
	AUTHENTICATING,
	GAME_SCENE_LOADED,
	COMPLETE
}

func auth_callback(p_sender_id: int, p_buffer: PackedByteArray) -> void:
	print("auth_callback: %s" % p_sender_id)
	
	var multiplayer_extension: SarMultiplayerAPIExtension = get_tree().get_multiplayer() as SarMultiplayerAPIExtension
	var scene_multiplayer: SceneMultiplayer = multiplayer_extension.base_multiplayer as SceneMultiplayer
	
	var id: int = p_buffer.decode_u8(0)
	p_buffer.get_string_from_ascii()
	if p_sender_id == game_session_manager.get_host_peer_id():
		# Messages from the host.
		match id:
			AuthenticationStage.AUTHENTICATING:
				var scene_path: String = p_buffer.slice(1).get_string_from_ascii()
				get_tree().change_scene_to_file(scene_path)
				
				# Yeeesh, this is ugly. We really should have proper callback signal
				# or something for this.
				for i: int in range(0, 2):
					await get_tree().process_frame
				
				var auth_error_code: Error = scene_multiplayer.send_auth(
					p_sender_id,
					PackedByteArray([AuthenticationStage.GAME_SCENE_LOADED
					]))
				if auth_error_code != OK:
					push_error("send_auth returned with error code %s" % auth_error_code)
			AuthenticationStage.COMPLETE:
				var result: Error = scene_multiplayer.complete_auth(p_sender_id)
				if result == OK:
					pass
				else:
					push_error("multiplayer complete_auth returned an error code %s" % result)
	else:
		# Messages from the peers.
		match id:
			AuthenticationStage.GAME_SCENE_LOADED:
				var auth_error_code: Error = scene_multiplayer.send_auth(
					p_sender_id,
					PackedByteArray([AuthenticationStage.COMPLETE])
					)
				if auth_error_code == OK:
					var result: Error = scene_multiplayer.complete_auth(p_sender_id)
					if result == OK:
						if not SarUtils.assert_true(authentication_peers_state_table.erase(p_sender_id),
							"SarGameSessionAuthentication.auth_callback: Could not erase p_sender_id %s. Sender id not found in authentication_peers_state_table." % p_sender_id):
							return
					else:
						push_error("multiplayer complete_auth returned an error code %s" % result)
				else:
					push_error("send_auth returned with error code %s" % auth_error_code)
					
func create_authentication_buffer() -> PackedByteArray:
	var buffer: PackedByteArray = PackedByteArray()
	
	buffer.resize(1)
	buffer.encode_u8(0, AuthenticationStage.AUTHENTICATING)
	buffer.append_array(get_tree().current_scene.scene_file_path.to_ascii_buffer())
	
	return buffer
					
func peer_authenticating(p_peer_id: int) -> void:
	print("peer_authenticating: %s" % p_peer_id)
	
	if multiplayer.get_unique_id() == game_session_manager.get_host_peer_id():
		authentication_peers_state_table[p_peer_id] = AuthenticationStage.AUTHENTICATING
		
		var multiplayer_extension: SarMultiplayerAPIExtension = get_tree().get_multiplayer() as SarMultiplayerAPIExtension
		var scene_multiplayer: SceneMultiplayer = multiplayer_extension.base_multiplayer as SceneMultiplayer
		
		var result: Error = scene_multiplayer.send_auth(p_peer_id, create_authentication_buffer())
		if result != OK:
			push_error("multiplayer send_auth returned an error code %s" % result)
			
func peer_authentication_failed(p_peer_id: int) -> void:
	print("peer_authentication_failed: %s" % p_peer_id)
	if multiplayer.get_unique_id() == game_session_manager.get_host_peer_id():
		if not SarUtils.assert_true(authentication_peers_state_table.erase(p_peer_id),
			"SarGameSessionAuthentication.peer_authentication_failed: Could not erase p_peer_id %s. Peer id not found in authentication_peers_state_table." % p_peer_id):
			return
