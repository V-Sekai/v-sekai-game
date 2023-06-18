# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# network_reader.gd
# SPDX-License-Identifier: MIT

@tool
extends RefCounted

var eof_reached: bool = false
var stream_peer_buffer: StreamPeerBuffer = null


static func decode_24_bit_value(p_buffer: PackedByteArray) -> int:
	var integer: int = 0
	integer = (p_buffer[0] & 0x000000ff | (p_buffer[1] << 8) & 0x0000ff00 | (p_buffer[2] << 16) & 0x00ff0000)
	return integer


func _init(p_buffer: PackedByteArray):
	if typeof(p_buffer) != TYPE_PACKED_BYTE_ARRAY:
		return

	stream_peer_buffer = StreamPeerBuffer.new()
	stream_peer_buffer.data_array = p_buffer


func is_eof() -> bool:
	return eof_reached


func get_position() -> int:
	return stream_peer_buffer.get_position()


func get_size() -> int:
	return stream_peer_buffer.get_size()


func seek(p_position: int) -> void:
	if p_position > get_size():
		eof_reached = true
	else:
		eof_reached = false
		stream_peer_buffer.seek(p_position)


# Core
func get_8() -> int:
	if stream_peer_buffer.get_available_bytes() < 1:
		eof_reached = true
		return 0
	return stream_peer_buffer.get_8()


func get_16() -> int:
	if stream_peer_buffer.get_available_bytes() < 2:
		eof_reached = true
		return 0
	return stream_peer_buffer.get_16()


func get_24() -> int:
	if stream_peer_buffer.get_available_bytes() < 3:
		eof_reached = true
		return 0

	var value_buffer = PackedByteArray([stream_peer_buffer.get_8(), stream_peer_buffer.get_8(), stream_peer_buffer.get_8()])
	if stream_peer_buffer.big_endian:
		value_buffer.reverse()

	return decode_24_bit_value(value_buffer)


func get_32() -> int:
	if stream_peer_buffer.get_available_bytes() < 4:
		eof_reached = true
		return 0
	return stream_peer_buffer.get_32()


func get_64() -> int:
	if stream_peer_buffer.get_available_bytes() < 8:
		eof_reached = true
		return 0
	return stream_peer_buffer.get_64()


func get_u8() -> int:
	if stream_peer_buffer.get_available_bytes() < 1:
		eof_reached = true
		return 0
	return stream_peer_buffer.get_u8()


func get_u16() -> int:
	if stream_peer_buffer.get_available_bytes() < 2:
		eof_reached = true
		return 0
	return stream_peer_buffer.get_u16()


func get_u24() -> int:
	return get_24()


func get_u32() -> int:
	if stream_peer_buffer.get_available_bytes() < 4:
		eof_reached = true
		return 0
	return stream_peer_buffer.get_u32()


func get_u64() -> int:
	if stream_peer_buffer.get_available_bytes() < 8:
		eof_reached = true
		return 0
	return stream_peer_buffer.get_u64()


func get_float() -> float:
	if stream_peer_buffer.get_available_bytes() < 4:
		eof_reached = true
		return 0.0
	return stream_peer_buffer.get_float()


func get_double() -> float:
	if stream_peer_buffer.get_available_bytes() < 8:
		eof_reached = true
		return 0.0
	return stream_peer_buffer.get_double()


func get_8bit_pascal_string(p_utf8: bool) -> String:
	var string: String = ""
	var size: int = get_8()
	if size > 0:
		var buffer: PackedByteArray = get_buffer(size)
		if p_utf8:
			string = buffer.get_string_from_utf8()
		else:
			string = buffer.get_string_from_ascii()

	return string


func get_buffer(p_size) -> PackedByteArray:
	if stream_peer_buffer.get_available_bytes() < p_size:
		eof_reached = true
		stream_peer_buffer.seek(stream_peer_buffer.get_size())
		return PackedByteArray()

	var pos: int = stream_peer_buffer.get_position()
	var buffer: PackedByteArray = stream_peer_buffer.data_array.slice(pos, pos + p_size)
	stream_peer_buffer.seek(pos + p_size)

	return buffer


# Helpers


func get_vector2() -> Vector2:
	return Vector2(get_float(), get_float())


func get_vector3() -> Vector3:
	return Vector3(get_float(), get_float(), get_float())


func get_rect2() -> Rect2:
	return Rect2(get_float(), get_float(), get_float(), get_float())


func get_quat() -> Quaternion:
	return Quaternion(get_float(), get_float(), get_float(), get_float())


func get_basis() -> Basis:
	return Basis(get_vector3(), get_vector3(), get_vector3())


func get_transform() -> Transform3D:
	return Transform3D(get_basis(), get_vector3())


func get_var():
	return stream_peer_buffer.get_var(false)


func get_entity_id() -> int:
	return get_u32()


func get_entity() -> Object:
	return null
