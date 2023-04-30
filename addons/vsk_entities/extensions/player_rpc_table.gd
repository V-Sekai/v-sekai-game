extends "res://addons/network_manager/network_rpc_table.gd"

signal avatar_path_updated(p_path)
signal did_teleport

@rpc("authority") func send_did_teleport() -> void:
	did_teleport.emit()


@rpc("authority") func send_set_avatar_path(p_path: String) -> void:
	avatar_path_updated.emit(p_path)
