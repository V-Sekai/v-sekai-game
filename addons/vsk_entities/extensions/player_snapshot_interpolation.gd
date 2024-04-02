extends Node

const quantization_const = preload("../quantization.gd")

# Path to the player node
@export_node_path("CharacterBody3D") var player_controller: NodePath = NodePath()
@onready var _player_controller_node: CharacterBody3D = get_node_or_null(player_controller)

# Current snapshot to sync to the actual player node
var target_player_snapshot: PlayerSnapshot = PlayerSnapshot.new()


# A player snapshot contains a world origin and a single rotation for their
# y euler angle.
class PlayerSnapshot:
	extends RefCounted
	const PACKET_LENGTH = 8

	var origin: Vector3
	var y_rotation: float

	# Encodes and quantizes a snapshot into a byte array.
	static func encode_player_snapshot(p_player_snapshot: PlayerSnapshot) -> PackedByteArray:
		assert(p_player_snapshot)

		var buf: PackedByteArray = PackedByteArray()
		assert(buf.resize(PACKET_LENGTH) == OK)

		buf.encode_half(0, p_player_snapshot.origin.x)
		buf.encode_half(2, p_player_snapshot.origin.y)
		buf.encode_half(4, p_player_snapshot.origin.z)
		buf.encode_s16(6, quantization_const.quantize_euler_angle_to_s16_angle(p_player_snapshot.y_rotation))

		return buf

	# Decodes and dequantizes a snapshot from a byte array.
	static func decode_player_snapshot(p_player_snapshot_byte_array: PackedByteArray) -> PlayerSnapshot:
		var new_player_snapshot: PlayerSnapshot = PlayerSnapshot.new()

		if p_player_snapshot_byte_array.size() == PACKET_LENGTH:
			var new_origin: Vector3 = Vector3()
			new_origin.x = p_player_snapshot_byte_array.decode_half(0)
			new_origin.y = p_player_snapshot_byte_array.decode_half(2)
			new_origin.z = p_player_snapshot_byte_array.decode_half(4)

			var new_rotation_y: float = quantization_const.dequantize_s16_angle_to_euler_angle(
				p_player_snapshot_byte_array.decode_s16(6)
			)

			new_player_snapshot.origin = new_origin
			new_player_snapshot.y_rotation = new_rotation_y

		return new_player_snapshot


# Syncs snapshot to the actual player node.
func _sync_values() -> void:
	_player_controller_node.network_transform_update(target_player_snapshot.origin, target_player_snapshot.y_rotation)


# This value encodes/decodes and quantizes the player's origin and y rotation
# when accessed.
@export var sync_net_state: PackedByteArray:
	get:
		var buf: PackedByteArray = PackedByteArray()

		if _player_controller_node:
			var new_player_snapshot: PlayerSnapshot = PlayerSnapshot.new()
			new_player_snapshot.origin = _player_controller_node.transform.origin
			new_player_snapshot.y_rotation = _player_controller_node.y_rotation

			buf = PlayerSnapshot.encode_player_snapshot(new_player_snapshot)

		return buf

	set(value):
		if typeof(value) != TYPE_PACKED_BYTE_ARRAY:
			return
		if value.size() != PlayerSnapshot.PACKET_LENGTH:
			return

		if multiplayer.has_multiplayer_peer() and not is_multiplayer_authority():
			target_player_snapshot = PlayerSnapshot.decode_player_snapshot(value)

			if _player_controller_node:
				_sync_values()


func _ready() -> void:
	target_player_snapshot.origin = _player_controller_node.transform.origin
	target_player_snapshot.y_rotation = _player_controller_node.y_rotation

	if (
		multiplayer.has_multiplayer_peer()
		and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED
		and !is_multiplayer_authority()
		and _player_controller_node
	):
		_sync_values()
