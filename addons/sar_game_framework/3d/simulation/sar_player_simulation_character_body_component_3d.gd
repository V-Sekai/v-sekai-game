@tool
extends Node
class_name SarSimulationComponentCharacterBodyConfiguration3D

# Floor
var _backup_floor_max_angle: float = deg_to_rad(45.0)
var _backup_floor_snap_length: float = 0.1

# Collision
var _backup_safe_margin: float = 0.001

@export_group("Floor", "floor_")
@export_range(0, 180, 0.1, "radians_as_degrees") var floor_max_angle: float = deg_to_rad(45.0)
@export_range(0, 32, 0.1, "or_greater", "suffix:px") var floor_snap_length: float = 0.1

@export_group("Colliison", "")
@export_range(0.001, 256, 0.001, "suffix:px") var safe_margin: float = 0.001

func _ready() -> void:
	if not Engine.is_editor_hint():
		if simulation:
			var movement_component: SarGameEntityComponentVesselMovementCharacter3D = simulation.get_game_entity_interface().get_movement_component()
			if movement_component:
				var character_body_3d: CharacterBody3D = movement_component.character_body_3d
				if character_body_3d:
					_backup_floor_max_angle = character_body_3d.floor_max_angle
					character_body_3d.floor_max_angle = floor_max_angle
					
					_backup_floor_snap_length = character_body_3d.floor_snap_length
					character_body_3d.floor_snap_length = floor_snap_length
					
					_backup_safe_margin = character_body_3d.safe_margin
					character_body_3d.safe_margin = safe_margin
			
func _on_simulation_shutdown() -> void:
	if not Engine.is_editor_hint():
		if simulation:
			var movement_component: SarGameEntityComponentVesselMovementCharacter3D = simulation.get_game_entity_interface().get_movement_component()
			if movement_component:
				var character_body_3d: CharacterBody3D = movement_component.character_body_3d
				if character_body_3d:
					character_body_3d.floor_max_angle = _backup_floor_max_angle
					character_body_3d.floor_snap_length = _backup_floor_snap_length
					character_body_3d.safe_margin = _backup_safe_margin

## Reference to the root simulation.
@export var simulation: SarSimulationVessel3D = null
