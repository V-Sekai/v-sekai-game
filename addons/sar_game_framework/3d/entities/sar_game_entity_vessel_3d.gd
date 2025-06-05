@tool
extends SarGameEntity3D
class_name SarGameEntityVessel3D


## Base class for mobile entities intended to be controlled by Souls
## (player/NPC controllers). Handles transform synchronization
## between visual representation and physics simulation.
##
## The vessel has several built-in functionalities over the base entity type
## built in as standard: physics-aware movement through SarMovementComponent,
## top-level transform independence, bidirectional transform sync between
## graphics and physics, and a soul possession system.

## Signal emitted when the vessel's transform changes from direct manipulation. Outside
## of the regular movement integration phase.
signal transform_changed(p_transform)

## Signal emitted before the transform is about to change by the
## movement component.
signal transform_pre_update(p_transform)

## Signal emitted after the transform is changed by the movement component.
signal transform_post_update(p_transform)


# Synchronizes visual transform with physics simulation results. Called after
# physics calculations complete to update visible position/orientation.
func _update_transform() -> void:
	if not Engine.is_editor_hint():
		# Safely access character-specific interface
		
		transform_pre_update.emit(transform)
		
		var character_interface: SarGameEntityInterfaceCharacter3D = (get_game_entity_interface() as SarGameEntityInterfaceCharacter3D)
		if character_interface:
			if character_interface.get_movement_component():
				# Match visual position to physics simulation result
				transform.origin = character_interface.get_movement_component().get_physics_transform().origin
		else:
			printerr("Game entity interface is missing.")
			
		transform_post_update.emit(transform)

# Handles completion of physics-based movement calculations. Temporarily
# disables transform notifications to prevent recursive feedback loops.
func _on_movement_controller_movement_complete(_delta: float) -> void:
	set_notify_transform(false)
	_update_transform()
	set_notify_transform(true)

func _update_physics() -> void:
	# Update physics simulation when transform is manually modified
	var character_interface: SarGameEntityInterfaceCharacter3D = (get_game_entity_interface() as SarGameEntityInterfaceCharacter3D)
	if character_interface:
		var movement_component: SarGameEntityComponentVesselMovement3D = character_interface.get_movement_component()
		if movement_component:
			# Sync physics position with visual transform
			movement_component.set_physics_position(global_transform.origin)
			movement_component.previous_physics_position = global_transform.origin
	else:
		printerr("Game entity interface is missing.")
	
	# Alert external systems about transform changes
	transform_changed.emit(global_transform)

func _notification(p_what: int) -> void:
	match p_what:
		# I don't think these are called immediately, but rather at the end
		# of the frame, which would render their usage redundant.
		NOTIFICATION_TRANSFORM_CHANGED:
			if not Engine.is_editor_hint():
				_update_physics()
		NOTIFICATION_LOCAL_TRANSFORM_CHANGED:
			if not Engine.is_editor_hint():
				_update_physics()
			

func _ready() -> void:
	if not Engine.is_editor_hint():
		# Run in top-level mode to maintain independent transform hierarchy
		top_level = true
		# Enable transform change tracking for physics synchronization
		game_entity_interface.get_game_entity().set_notify_transform(true)
		
###

# See base class for implementation information.
func get_game_entity_valid_scene_path() -> String:
	return "res://addons/sar_game_framework/3d/entities/sar_game_entity_vessel_3d.tscn"
