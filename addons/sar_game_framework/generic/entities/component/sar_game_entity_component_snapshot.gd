@tool
extends SarGameEntityComponent
class_name SarGameEntityComponentSnapshot

## Helper component designed to build a custom PackedByteArray
## variable based on the composition of the child nodes.
## It is intended to be used by the MultiplayerSynchronizers
## to allow us to build custom packet layouts in a more compositional,
## precise, and compressed way.
	
var _first_received: bool = false
var _pending_snapshot_count: int = 0
	
func _on_multiplayer_synchronizer_sync_synchronized() -> void:
	# TODO: we need an engine method to determine how many packets were lost.
	# For now, lets just assume none were skipped.
	var lost_packet_count: int = 0
	
	if lost_packet_count > 0:
		print("skip_occured %s" % lost_packet_count)
	
	if _first_received:
		_pending_snapshot_count += (1 + lost_packet_count)
	else:
		_pending_snapshot_count = 0
		_first_received = true
	
func _physics_process(_delta: float) -> void:
	if _first_received:
		_pending_snapshot_count -= 1
			
func _ready() -> void:
	if not Engine.is_editor_hint() and not is_multiplayer_authority():
		set_physics_process(true)
	else:
		set_physics_process(false)
			
###

## Returns the size of this snapshot.
func get_size() -> int:
	var size: int = 0
	for child: Node in get_children():
		if child is SarSnapshot:
			size += (child as SarSnapshot).get_size()
	return size
	
## Called when reading the net state to encode a variable PackedByteArray.
func encode_snapshot(p_stream_peer: StreamPeer, p_bit_offset: int) -> StreamPeer:
	for child: Node in get_children():
		if child is SarSnapshot:
			p_stream_peer = (child as SarSnapshot).encode_snapshot(p_stream_peer, p_bit_offset)
			
	return p_stream_peer
	
## Called when writing the net state to decode a variable PackedByteArray.
func decode_snapshot(p_stream_peer: StreamPeer, p_bit_offset: int) -> StreamPeer:
	for child: Node in get_children():
		if child is SarSnapshot:
			p_stream_peer = (child as SarSnapshot).decode_snapshot(p_stream_peer, p_bit_offset)
	return p_stream_peer

## This value encodes/decodes the tree beneath it which composes a full
## snapshot.
@export var sync_net_state: PackedByteArray:
	get:
		var stream: StreamPeerBuffer = StreamPeerBuffer.new()
		if not Engine.is_editor_hint():
			var buf: PackedByteArray = PackedByteArray()
			var buf_size: int = get_size()
			var result: int = buf.resize(buf_size)
			assert(result == OK)
			
			stream.data_array = buf
			stream.seek(0)
		
			stream = encode_snapshot(stream, 0)
		
		return stream.data_array
		
	set(value):
		var stream: StreamPeerBuffer = StreamPeerBuffer.new()
		if not Engine.is_editor_hint():
			if typeof(value) != TYPE_PACKED_BYTE_ARRAY:
				return
				
			if multiplayer.has_multiplayer_peer() and not is_multiplayer_authority():
				stream.data_array = value
				
				stream = decode_snapshot(stream, 0)
