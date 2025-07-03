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
	if not SarUtils.assert_ok(resize_result, "SarFlagSnapshot.encode_snapshot: Could not resize PackedByteArray"):
		return null

	pba.encode_u8(0, value)
	
	var _result: Array = p_stream_peer.put_partial_data(pba)
	if not SarUtils.assert_ok(_result[0], "SarFlagSnapshot.encode_snapshot: Unexpected error while sending snapshot data."):
		return null
	if not SarUtils.assert_equal(_result[1], ceil(float(get_size()) / BITS), "SarFlagSnapshot.encode_snapshot: Did not send expected number of bytes in snapshot."):
		return null
	
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
