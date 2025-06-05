@tool
extends Area3D
class_name SarCharacterSimulationAreaDetectorComponent3D

signal teleported(p_offset)

### Liquids ###

var _liquid_count: int = 0

func entered_liquid() -> void:
	_liquid_count += 1
	print("entered_liquid")
	
func exited_liquid() -> void:
	_liquid_count -= 1
	print("exited_liquid")
	
### Zones ###

var _active_zones: Array[SarAreaZone3D]
var _active_zones_dirty: bool = true

#signal zone_list_changed(zones: Array[SarAreaZone3D])

func clear_active_zones_dirty_flag() -> void:
	_active_zones_dirty = false
	
func get_all_active_zones() -> Array[SarZone]:
	var zones_found: Array[SarZone]
	for zone_area: SarAreaZone3D in _active_zones:
		if not zones_found.has(zone_area.zone):
			zones_found.append(zone_area.zone)
			
	return zones_found
	
func get_highest_priority_active_zone() -> SarZone:
	var highest_priority_zone: SarZone = null
	var zones_found: Array[SarZone] = get_all_active_zones()
			
	for zone: SarZone in zones_found:
		if highest_priority_zone:
			if zone.priority >= highest_priority_zone.priority:
				highest_priority_zone = zone
		else:
			highest_priority_zone = zone
			
	return highest_priority_zone

func entered_zone(p_area: SarAreaZone3D) -> void:
	_active_zones.append(p_area)
	_active_zones_dirty = true
	
func exited_zone(p_area: SarAreaZone3D) -> void:
	_active_zones.erase(p_area)
	_active_zones_dirty = true
	
func is_active_zones_dirty_flag_set() -> bool:
	return _active_zones_dirty

### Teleport ###

func entered_teleport(p_area: SarAreaTeleport3D) -> void:
	if p_area.target_node.global_transform:
		var offset: Transform3D = get_parent().get_game_entity_interface().get_game_entity().global_transform.affine_inverse() * p_area.target_node.global_transform
		teleported.emit(offset)
	
func exited_teleport(_area: SarAreaTeleport3D) -> void:
	pass
