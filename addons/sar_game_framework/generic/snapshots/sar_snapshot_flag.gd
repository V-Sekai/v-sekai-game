class_name SarFlagSnapshot
extends SarValueSnapshot

@export var value: bool = false

func set_value(p_value: Variant) -> void:
	if p_value is bool:
		value = p_value
	
func get_value() -> Variant:
	return value

signal value_updated(p_new_value: Vector3)

func get_size() -> int:
	var packet_size: int = 0
	packet_size = BITS
	return packet_size * BITS

func encode_snapshot(p_stream_peer: StreamPeer, p_bit_offset: int) -> StreamPeer:
	p_stream_peer = super.encode_snapshot(p_stream_peer, p_bit_offset)
	
	var pba: PackedByteArray
	var resize_result: int = pba.resize(ceil(float(get_size()) / BITS))
	assert(resize_result == OK)

	pba.encode_u8(0, value)
	
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
		
		value = pba.decode_u8(packet_idx)
		
	value_updated.emit(value)
		
	return p_stream_peer
