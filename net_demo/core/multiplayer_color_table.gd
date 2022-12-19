extends Node

signal color_table_updated

const FIXED_COLOR_TABLE_SIZE = 64
const color_functions_const = preload("color_functions.gd")

var pick_random_color: bool = true

var material_idx_accumulator: int = 0

var multiplayer_materials: Array = [] # Fixed size array of valid materials
var multiplayer_peer_to_material_idx_table: Dictionary = {}
	
# Loads all the multiplayer materials corresponding to the color table
func load_multiplayer_materials(p_color_table: PackedColorArray) -> void:
	multiplayer_materials = []
	
	for i in range(0, p_color_table.size()):
		var new_color: Color = p_color_table[i]
		var new_material: StandardMaterial3D = StandardMaterial3D.new()
		new_material.albedo_color = new_color
		multiplayer_materials.push_back(new_material)

# Returns the material for an index id
func get_material_for_index(p_index: int) -> Material:
	assert(p_index >= 0)
	assert(p_index < multiplayer_materials.size())
	
	return multiplayer_materials[p_index]

func assign_multiplayer_peer_to_material_id_table_entry(p_peer_id: int, p_material_id: int) -> void:
	multiplayer_peer_to_material_idx_table[p_peer_id] = p_material_id
	color_table_updated.emit()

# Clears the entire multiplayer color table
func clear_multiplayer_color_table() -> void:
	multiplayer_peer_to_material_idx_table.clear()
	material_idx_accumulator = 0

# Removes a peer id from the color table
func erase_multiplayer_peer_id(p_peer_id: int) -> void:
	var _erase_result: bool = multiplayer_peer_to_material_idx_table.erase(p_peer_id)

# Get the material index for a specific peer id. If one does not yet
# exist, a new one is added at random
func get_multiplayer_material_index_for_peer_id(p_peer_id: int, p_assign_if_missing: bool) -> int:
	var material_id: int = multiplayer_peer_to_material_idx_table.get(p_peer_id, -1)
	if material_id >= 0:
		return material_id
	elif p_assign_if_missing:
		var valid_multiplayer_material: Array = multiplayer_materials
		for val in multiplayer_peer_to_material_idx_table.values():
			valid_multiplayer_material.erase(val)
			
		if valid_multiplayer_material.size() > 0:
			if pick_random_color:
				material_id = randi_range(0, valid_multiplayer_material.size()-1)
			else:
				material_id = material_idx_accumulator
				
			assign_multiplayer_peer_to_material_id_table_entry(p_peer_id, material_id)
			
			material_idx_accumulator += 1
			if material_idx_accumulator >= valid_multiplayer_material.size():
				material_idx_accumulator = 0
			
			return material_id
		else:
			return -1
			
	return -1
			
func reset_colors():
	clear_multiplayer_color_table()
	load_multiplayer_materials(color_functions_const.get_list_of_colors(FIXED_COLOR_TABLE_SIZE))
