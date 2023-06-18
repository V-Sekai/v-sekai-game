# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# network_writer.gd
# SPDX-License-Identifier: MIT

@tool
extends RefCounted

var stream_peer_buffer: StreamPeerBuffer = StreamPeerBuffer.new()


static func encode_24_bit_value(p_value: int) -> PackedByteArray:
	return PackedByteArray([p_value & 0x000000ff, (p_value & 0x0000ff00) >> 8, (p_value & 0x00ff0000) >> 16])


func get_raw_data(p_size: int = 0) -> PackedByteArray:
	if stream_peer_buffer.data_array.size() == p_size or p_size <= 0:
		return stream_peer_buffer.data_array
	else:
		return stream_peer_buffer.data_array.slice(0, p_size)


func clear() -> void:
	stream_peer_buffer.clear()


func get_position() -> int:
	return stream_peer_buffer.get_position()


func get_size() -> int:
	return stream_peer_buffer.get_size()


func resize(p_resize) -> void:
	stream_peer_buffer.resize(p_resize)


func seek(p_position: int) -> void:
	if p_position > get_size():
		NetworkLogger.error("Tried to seek beyond size of buffer!")
	else:
		stream_peer_buffer.seek(p_position)


func put_data(p_data: PackedByteArray) -> void:
	if stream_peer_buffer.put_data(p_data) != OK:
		NetworkLogger.error("put_data returned an error!")


func put_ranged_data(p_data: PackedByteArray, p_position: int, p_length: int) -> void:
	if p_length > 0:
		var subarray: PackedByteArray = p_data.slice(p_position, p_position + p_length)
		if stream_peer_buffer.put_data(subarray) != OK:
			NetworkLogger.error("put_ranged_data returned an error!")


func put_writer(p_writer, p_size: int = 0) -> void:
	if p_size > 0:
		if p_writer.get_size() == p_size:
			put_data(p_writer.stream_peer_buffer.data_array)
		else:
			put_data(p_writer.stream_peer_buffer.data_array.slice(0, p_size))


func put_8(p_value: int) -> void:
	stream_peer_buffer.put_8(p_value)


func put_16(p_value: int) -> void:
	stream_peer_buffer.put_16(p_value)


func put_24(p_value: int) -> void:
	var value_buffer: PackedByteArray = encode_24_bit_value(p_value)
	if stream_peer_buffer.big_endian:
		value_buffer.reverse()
	put_data(value_buffer)


func put_32(p_value: int) -> void:
	stream_peer_buffer.put_32(p_value)


func put_64(p_value) -> void:
	stream_peer_buffer.put_64(p_value)


func put_u8(p_value: int) -> void:
	stream_peer_buffer.put_u8(p_value)


func put_u16(p_value: int) -> void:
	stream_peer_buffer.put_u16(p_value)


func put_u24(p_value: int) -> void:
	put_24(p_value)


func put_u32(p_value: int) -> void:
	stream_peer_buffer.put_u32(p_value)


func put_u64(p_value: int) -> void:
	stream_peer_buffer.put_u64(p_value)


func put_float(p_float: float) -> void:
	stream_peer_buffer.put_float(p_float)


func put_double(p_double: float) -> void:
	stream_peer_buffer.put_double(p_double)


func put_8bit_pascal_string(p_value: String, p_utf8: bool) -> void:
	var buffer: PackedByteArray = PackedByteArray()
	if p_utf8:
		buffer = p_value.to_utf8_buffer()
	else:
		buffer = p_value.to_ascii_buffer()

	if buffer.size() >= 255:
		NetworkLogger.error("Pascal string too long!")
		put_8(0)
	else:
		put_8(buffer.size())
		put_data(buffer)


func put_vector2(p_vector: Vector2) -> void:
	put_float(p_vector.x)
	put_float(p_vector.y)


func put_vector3(p_vector: Vector3) -> void:
	put_float(p_vector.x)
	put_float(p_vector.y)
	put_float(p_vector.z)


func put_rect2(p_rect: Rect2) -> void:
	put_float(p_rect.position.x)
	put_float(p_rect.position.y)
	put_float(p_rect.size.x)
	put_float(p_rect.size.y)


func put_quat(p_quat: Quaternion) -> void:
	put_float(p_quat.x)
	put_float(p_quat.y)
	put_float(p_quat.z)
	put_float(p_quat.w)


func put_basis(p_basis: Basis) -> void:
	put_vector3(p_basis.x)
	put_vector3(p_basis.y)
	put_vector3(p_basis.z)


func put_transform(p_transform: Transform3D) -> void:
	put_basis(p_transform.basis)
	put_vector3(p_transform.origin)


func put_var(p_var) -> void:
	stream_peer_buffer.put_var(p_var, false)


func _init(p_size: int = 0):
	if p_size > 0:
		stream_peer_buffer.resize(p_size)
