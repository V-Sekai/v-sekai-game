class_name SarVector3Snapshot
extends SarValueSnapshot

@export var value: Vector3 = Vector3()

func set_value(p_value: Variant) -> void:
	if p_value is Vector3:
		value = p_value
	
func get_value() -> Variant:
	return value

signal value_updated(p_new_value: Vector3)

func get_size() -> int:
	var packet_size: int = 0
	
	packet_size += FULL_VALUE_SIZE
	packet_size += FULL_VALUE_SIZE
	packet_size += FULL_VALUE_SIZE
		
	return packet_size * BITS

func encode_snapshot(p_stream_peer: StreamPeer, p_bit_offset: int) -> StreamPeer:
	p_stream_peer = super.encode_snapshot(p_stream_peer, p_bit_offset)
	
	var pba: PackedByteArray
	var resize_result: int = pba.resize(ceil(float(get_size()) / BITS))
	assert(resize_result == OK)

	var packet_idx: int = 0
		
	pba.encode_float(packet_idx, value.x)
	packet_idx += FULL_VALUE_SIZE
	pba.encode_float(packet_idx, value.y)
	packet_idx += FULL_VALUE_SIZE
	pba.encode_float(packet_idx, value.z)
	packet_idx += FULL_VALUE_SIZE
		
	var _result: Array = p_stream_peer.put_partial_data(pba)
	assert(_result[0] == OK)
	assert(_result[1] == ceil(float(get_size()) / BITS))
	
	return p_stream_peer
	
func decode_snapshot(p_stream_peer: StreamPeer, p_bit_offset: int) -> StreamPeer:
	p_stream_peer = super.decode_snapshot(p_stream_peer, p_bit_offset)
	
	var _result: Array = p_stream_peer.get_partial_data(ceil(float(get_size()) / BITS))
	if _result[0] == OK:
		var pba: PackedByteArray = _result[1]
		
		var packet_idx: int = 0
		
		value.x = pba.decode_float(packet_idx)
		packet_idx += FULL_VALUE_SIZE
		value.y = pba.decode_float(packet_idx)
		packet_idx += FULL_VALUE_SIZE
		value.z = pba.decode_float(packet_idx)
		packet_idx += FULL_VALUE_SIZE
		
	value_updated.emit(value)
		
	return p_stream_peer
