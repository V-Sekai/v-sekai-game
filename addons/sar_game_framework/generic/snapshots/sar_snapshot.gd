extends Node
class_name SarSnapshot

const BITS: int = 8
const QUARTER_VALUE_SIZE: int = 1
const HALF_VALUE_SIZE: int = 2
const FULL_VALUE_SIZE: int = 4

func get_size() -> int:
	var size: int = 0
	for child: Node in get_children():
		if child is SarSnapshot:
			size += (child as SarSnapshot).get_size()
	return size

# Encodes and quantizes a snapshot into a byte array
func encode_snapshot(p_stream_peer: StreamPeer, _bit_offset: int) -> StreamPeer:
	return p_stream_peer
	
# Decodes and dequantizes a snapshot from a byte array
func decode_snapshot(p_stream_peer: StreamPeer, _bit_offset: int) -> StreamPeer:
	return p_stream_peer
	
