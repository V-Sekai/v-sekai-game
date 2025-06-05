@tool
extends Node3D
class_name SarPlayerSimulationPlayspaceComponent3D

## Base class for controlling a camera system for the player's simulation space.

# Don't show the simulation node property in the
# inspector if we're the currently edited scene since
# its redunant.
func _validate_property(p_property: Dictionary) -> void:
	if Engine.is_editor_hint():
		if is_inside_tree():
			if owner != get_tree().edited_scene_root and p_property.name == "simulation":
				p_property.usage = PROPERTY_USAGE_NO_EDITOR

# Called to set the camera as current or not current depending on whether
# the simulation space is possessed or not.
func _on_vessel_possession_changed(p_soul: SarSoul) -> void:
	if not Engine.is_editor_hint():
		# If we're not ready yet, await until we're ready.
		if not is_node_ready():
			await ready
		
		if p_soul:
			camera.current = true
		else:
			camera.current = false
			
# Assign the camera as current only if we're possessed
func _ready() -> void:
	if not Engine.is_editor_hint():
		if is_multiplayer_authority():
			set_physics_process(true)
		else:
			set_physics_process(false)
		
		if simulation:
			if simulation.is_possessed():
				camera.current = true
			else:
				camera.current = false
	else:
		set_physics_process(false)
			
###

## Reference to the root simulation.
@export var simulation: SarSimulationVessel3D = null

## The camera associated with this playspace.
@export var camera: Camera3D = null

## Returns the yaw rotation derived from the camera's yaw.
func get_yaw_rotation() -> float:
	return camera.rotation.y
