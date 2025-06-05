class_name SarFixedSizeSnapshot
extends SarSnapshot

signal updated()

@export var fixed_buffer_size: int = 0

func get_size() -> int:
	return fixed_buffer_size

func encode_snapshot(p_stream_peer: StreamPeer, p_bit_offset: int) -> StreamPeer:
	p_stream_peer = super.encode_snapshot(p_stream_peer, p_bit_offset)
	
	var pba: PackedByteArray
	var resize_result: int = pba.resize(ceil(float(get_size()) / BITS))
	assert(resize_result == 0)
	
	var parameter_stream_peer: StreamPeerBuffer = StreamPeerBuffer.new()
	parameter_stream_peer.data_array = pba
	parameter_stream_peer.seek(0)
	for child in get_children():
		if child is SarSnapshot:
			parameter_stream_peer = child.encode_snapshot(parameter_stream_peer, p_bit_offset)
		
	var _result: Array = p_stream_peer.put_partial_data(parameter_stream_peer.data_array)
	assert(_result[0] == OK)
	assert(_result[1] == ceil(float(get_size()) / BITS))
	
	return p_stream_peer
	
func decode_snapshot(p_stream_peer: StreamPeer, p_bit_offset: int) -> StreamPeer:
	p_stream_peer = super.decode_snapshot(p_stream_peer, p_bit_offset)
	
	var _result: Array = p_stream_peer.get_partial_data(ceil(float(get_size()) / BITS))
	if _result[0] == OK:
		var pba: PackedByteArray = _result[1]
		
		var parameter_stream_peer: StreamPeerBuffer = StreamPeerBuffer.new()
		parameter_stream_peer.data_array = pba
		for child in get_children():
			if child is SarSnapshot:
				parameter_stream_peer = child.decode_snapshot(parameter_stream_peer, p_bit_offset)
		
	updated.emit()
		
	return p_stream_peer
	
func _on_synchronized() -> void:
	if not is_multiplayer_authority():
		pass
			
func _ready() -> void:
	pass
