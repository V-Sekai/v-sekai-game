@tool
extends SarGameEntityComponent
class_name VSKGameEntityComponentAvatarSync

## This component contains the requested avatar path which is controlled by
## entity's peer authority and intended to be synced whenever it is changed.
## When it changes, it emits a signal.

# Warn if we're not actually connected to anything.
func _get_configuration_warnings() -> PackedStringArray:
	var strings: PackedStringArray = super._get_configuration_warnings()
	
	if not requested_avatar_path_changed.has_connections():
		strings.append("requested_avatar_path_changed signal is not connected anything.")
		
	return strings

###

## Emitted when the requested avatar path has been validated
## by the session manager and the path has subseqently been changed.
signal requested_avatar_path_changed(p_new_path: String)

## The actual path for the entity's avatar which is intended to be tracked
## via a MultiplayerSynchronizer.
@export var requested_avatar_path: String = "":
	set(p_new_path):
		if requested_avatar_path != p_new_path:
			# Got to put this here since on remote peers, the
			# MultiplayerSynchronizer can set the value before the node is ready
			# and is able to interface with the node tree. Without this,
			# it will not be able to access the VSKGameSessionManager needed 
			# to perform the validation step.
			if not is_node_ready():
				await ready
			
			# Validation step: check if we're allowed to change to this particular
			# avatar path for this game session. Rules can be implemented on
			# a per-instance basis.
			var game_session_manager: VSKGameSessionManager = get_tree().get_first_node_in_group("game_session_manager")
			if game_session_manager:
				if not game_session_manager.is_avatar_path_allowed_for_avatar_sync(self, p_new_path):
					return
			
			# Okay, we can now actually set the new path and emit signal.
			requested_avatar_path = p_new_path
			requested_avatar_path_changed.emit(requested_avatar_path)
	
