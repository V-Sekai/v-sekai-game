extends MultiplayerSpawner

const PLAYER_SCENE_PATH : String = "res://net_demo/core/player_controller.tscn"
const PLAYER_SCENE : PackedScene = preload(PLAYER_SCENE_PATH)

const quantization_const = preload("quantization.gd")

func get_player_spawn_buffer(p_authority: int, p_transform: Transform3D) -> PackedByteArray:
	var buf: PackedByteArray = PackedByteArray()
	var _resize_result: int = buf.resize(13)
	buf.encode_u32(0, p_authority)
	buf.encode_half(4, p_transform.origin.x)
	buf.encode_half(6, p_transform.origin.y)
	buf.encode_half(8, p_transform.origin.z)
	buf.encode_s16(10, quantization_const.quantize_euler_angle_to_s16_angle(p_transform.basis.get_euler().y))
	var color_id: int = MultiplayerColorTable.get_multiplayer_material_index_for_peer_id(p_authority, true)
	assert(color_id != -1)
	buf.encode_u8(12, color_id)
	
	return buf

func _spawn_custom(data: Variant) -> Node:
	if typeof(data) != TYPE_PACKED_BYTE_ARRAY:
		return null
	if data.size() != (13):
		return null
		
	var multiplayer_authority_id: int = data.decode_u32(0)
		
	# We should never have a duplicate player controller, but if there is one, something has gone wrong.
	var spawn_node: Node = get_node(spawn_path)
	assert(spawn_node.get_node_or_null("PlayerController_" + str(multiplayer_authority_id)) == null)
		
	var new_origin: Vector3 = Vector3(data.decode_half(4), data.decode_half(6), data.decode_half(8))
	var y_rotation: float = quantization_const.dequantize_s16_angle_to_euler_angle(data.decode_s16(10))
	var new_player_scene : Node3D = PLAYER_SCENE.instantiate()
	new_player_scene.name = "PlayerController_" + str(multiplayer_authority_id)
	new_player_scene.transform.origin = new_origin
	new_player_scene.y_rotation = y_rotation
	
	var multiplayer_color_id: int = data.decode_u8(12)
	MultiplayerColorTable.assign_multiplayer_peer_to_material_id_table_entry(multiplayer_authority_id, multiplayer_color_id)
	
	new_player_scene.multiplayer_color_id = multiplayer_color_id
	new_player_scene.set_multiplayer_authority(multiplayer_authority_id)
	
	get_node("/root/GameManager/").add_player_to_list(multiplayer_authority_id)
	
	return new_player_scene
