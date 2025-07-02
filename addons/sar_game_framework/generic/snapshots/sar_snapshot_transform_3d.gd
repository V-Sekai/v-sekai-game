class_name SarTransform3DSnapshot
extends SarSnapshot

# Reference to the root player node
@export var game_entity: SarGameEntity3D = null

const SYNC_FLAG_POSITION_X = 1 << 0
const SYNC_FLAG_POSITION_Y = 1 << 1
const SYNC_FLAG_POSITION_Z = 1 << 2
const SYNC_FLAG_ROTATION_X = 1 << 3
const SYNC_FLAG_ROTATION_Y = 1 << 4
const SYNC_FLAG_ROTATION_Z = 1 << 5

@export_flags(
	"Position X",
	"Position Y",
	"Position Z",
	"Rotation X",
	"Rotation Y",
	"Rotation Z") var sync_flags: int = SYNC_FLAG_POSITION_X | SYNC_FLAG_POSITION_Y | SYNC_FLAG_POSITION_Z | SYNC_FLAG_ROTATION_Y

@export var rotation_order: EulerOrder = EulerOrder.EULER_ORDER_YXZ

signal transform_updated(p_transform: Transform3D)

var transform: Transform3D = Transform3D()

func get_size() -> int:
	var packet_size: int = 0
	
	if sync_flags & SYNC_FLAG_POSITION_X:
		packet_size += HALF_VALUE_SIZE
	if sync_flags & SYNC_FLAG_POSITION_Y:
		packet_size += HALF_VALUE_SIZE
	if sync_flags & SYNC_FLAG_POSITION_Z:
		packet_size += HALF_VALUE_SIZE
	if sync_flags & SYNC_FLAG_ROTATION_X:
		packet_size += HALF_VALUE_SIZE
	if sync_flags & SYNC_FLAG_ROTATION_Y:
		packet_size += HALF_VALUE_SIZE
	if sync_flags & SYNC_FLAG_ROTATION_Z:
		packet_size += HALF_VALUE_SIZE
		
	return packet_size * BITS

func encode_snapshot(p_stream_peer: StreamPeer, p_bit_offset: int) -> StreamPeer:
	p_stream_peer = super.encode_snapshot(p_stream_peer, p_bit_offset)
	
	var pba: PackedByteArray
	var resize_result: int = pba.resize(ceil(float(get_size()) / BITS))
	if not SarUtils.assert_ok(resize_result, "SarTransform3DSnapshot: Could not resize PackedByteArray."):
		return null

	var packet_idx: int = 0
	
	if sync_flags & SYNC_FLAG_POSITION_X:
		pba.encode_half(packet_idx, transform.origin.x)
		packet_idx += HALF_VALUE_SIZE
	if sync_flags & SYNC_FLAG_POSITION_Y:
		pba.encode_half(packet_idx, transform.origin.y)
		packet_idx += HALF_VALUE_SIZE
	if sync_flags & SYNC_FLAG_POSITION_Z:
		pba.encode_half(packet_idx, transform.origin.z)
		packet_idx += HALF_VALUE_SIZE
	
	if sync_flags & SYNC_FLAG_ROTATION_X:
		var quantized_x_rotation: int = SarQuantizationUtilities.quantize_euler_angle_to_s16_angle(transform.basis.get_euler().x)
		pba.encode_s16(packet_idx, quantized_x_rotation)
		packet_idx += HALF_VALUE_SIZE
	if sync_flags & SYNC_FLAG_ROTATION_Y:
		var quantized_y_rotation: int = SarQuantizationUtilities.quantize_euler_angle_to_s16_angle(transform.basis.get_euler().y)
		pba.encode_s16(packet_idx, quantized_y_rotation)
		packet_idx += HALF_VALUE_SIZE
	if sync_flags & SYNC_FLAG_ROTATION_Z:
		var quantized_z_rotation: int = SarQuantizationUtilities.quantize_euler_angle_to_s16_angle(transform.basis.get_euler().z)
		pba.encode_s16(packet_idx, quantized_z_rotation)
		packet_idx += HALF_VALUE_SIZE
	
	var _result: Array = p_stream_peer.put_partial_data(pba)
	if not SarUtils.assert_ok(_result[0], "SarTransform3DSnapshot.encode_snapshot: Unexpected error while sending snapshot data."):
		return null
	if not SarUtils.assert_equal(_result[1], ceil(float(get_size()) / BITS), "SarTransform3DSnapshot.encode_snapshot: Did not send expected number of bytes in snapshot."):
		return null

	return p_stream_peer
	
func decode_snapshot(p_stream_peer: StreamPeer, p_bit_offset: int) -> StreamPeer:
	p_stream_peer = super.decode_snapshot(p_stream_peer, p_bit_offset)
	
	var _result: Array = p_stream_peer.get_partial_data(ceil(float(get_size()) / BITS))
	if _result[0] == OK:
		var pba: PackedByteArray = _result[1]
		
		var packet_idx: int = 0
		
		if sync_flags & SYNC_FLAG_POSITION_X:
			transform.origin.x = pba.decode_half(packet_idx)
			packet_idx += HALF_VALUE_SIZE
		if sync_flags & SYNC_FLAG_POSITION_Y:
			transform.origin.y = pba.decode_half(packet_idx)
			packet_idx += HALF_VALUE_SIZE
		if sync_flags & SYNC_FLAG_POSITION_Z:
			transform.origin.z = pba.decode_half(packet_idx)
			packet_idx += HALF_VALUE_SIZE
			
		var x_rotation: float = 0.0
		var y_rotation: float = 0.0
		var z_rotation: float = 0.0
			
		if sync_flags & SYNC_FLAG_ROTATION_X:
			var quanted_x_rotation: int = pba.decode_s16(packet_idx)
			x_rotation = SarQuantizationUtilities.dequantize_s16_angle_to_euler_angle(quanted_x_rotation)
			packet_idx += HALF_VALUE_SIZE
		if sync_flags & SYNC_FLAG_ROTATION_Y:
			var quanted_y_rotation: int = pba.decode_s16(packet_idx)
			y_rotation = SarQuantizationUtilities.dequantize_s16_angle_to_euler_angle(quanted_y_rotation)
			packet_idx += HALF_VALUE_SIZE
		if sync_flags & SYNC_FLAG_ROTATION_Z:
			var quanted_z_rotation: int = pba.decode_s16(packet_idx)
			z_rotation = SarQuantizationUtilities.dequantize_s16_angle_to_euler_angle(quanted_z_rotation)
			packet_idx += HALF_VALUE_SIZE
		
		transform.basis = Basis.from_euler(Vector3(x_rotation, y_rotation, z_rotation), rotation_order)
		
	return p_stream_peer

func _set_transform(p_transform: Transform3D) -> void:
	transform = p_transform

# Only run on local peers.
func _physics_process(_delta: float) -> void:
	_set_transform(game_entity.global_transform)
		
func _on_synchronized() -> void:
	if not is_multiplayer_authority():
		transform_updated.emit(transform)
			
func _ready() -> void:
	_set_transform(game_entity.global_transform)
	
	if not Engine.is_editor_hint() and is_multiplayer_authority():
		set_physics_process(true)
	else:
		set_physics_process(false)
