@tool
extends Node
class_name SarSoul

## A soul represents the controller or "mind" of a vessel, such as a player or AI.
## It is responsible for managing the logic and behavior of a physical entity (vessel)
## without being tied to its visual or physical representation.
##
## Souls can be used for players, NPCs, or any entity requiring control logic.
## Vessels can be possessed or unpossessed at runtime, enabling gameplay mechanics
## like character switching or AI takeovers.

# Initializes possession if a vessel is assigned in the editor.
# Automatically attempts to possess the assigned vessel on game start.
func _ready() -> void:
	if not Engine.is_editor_hint():
		if possessed_vessel:
			possess(possessed_vessel)
	
# Don't show the possessed_vessel property if the node is the root
# of the edited scene.
func _validate_property(p_property: Dictionary) -> void:
	if Engine.is_editor_hint():
		if is_inside_tree():
			if owner != get_tree().edited_scene_root and p_property.name == "possessed_vessel":
				p_property.usage = PROPERTY_USAGE_NO_EDITOR

###

## Signal emitted when this soul successfully possesses a vessel.
## Provides the possessed vessel as a parameter for event handling.
signal possessed(p_vessel: SarGameEntityVessel3D)

## Signal emitted when the mouse capture mode is requested to be changed.
## Should be wired up for player souls, but not for AI souls.
signal mouse_mode_requested(p_mouse_capture_mode: Input.MouseMode)

## Reference to the currently possessed vessel. This represents the physical
## entity being controlled by this soul. Set in the editor for initial possession
## or dynamically at runtime.
@export var possessed_vessel: SarGameEntityVessel3D = null


## Attempts to possess a target vessel, transferring control to this soul.
## Returns true if possession was successful, false otherwise.
func possess(p_vessel: SarGameEntityVessel3D) -> bool:
	if p_vessel.get_multiplayer_authority() == get_multiplayer_authority():
		var interface: SarGameEntityInterfaceVessel3D = p_vessel.get_game_entity_interface() as SarGameEntityInterfaceVessel3D
		if interface:
			if interface.get_possession_component().get_soul() == null:
				if interface.get_possession_component().set_soul(self):
					possessed_vessel = p_vessel
					possessed.emit(possessed_vessel)
					return true
				else:
					printerr("Failed to possess vessel %s." % p_vessel.name)
			else:
				printerr("Tried to possess a %s which is already possessed by another soul." % p_vessel.name)
		else:
			printerr("Could not acquire valid entity interface for vessel %s." % p_vessel.name)
	else:
		printerr("Tried to possess vessel %s which this soul does not currently have authority over." % p_vessel.name)
		
	return false
	
## Releases control of the currently possessed vessel, if any.
## Clears the possession state and detaches from the vessel.
func unpossess() -> void:
	if possessed_vessel:
		var interface: SarGameEntityInterfaceVessel3D = possessed_vessel.get_game_entity_interface() as SarGameEntityInterfaceVessel3D
		if interface:
			if interface.get_possession_component().set_soul(null):
				possessed_vessel = null
			else:
				printerr("Failed to unpossess vessel %s." % possessed_vessel.name)
		else:
			printerr("Invalid interface when attempting to unpossess vessel %s." % possessed_vessel.name)

### Returns the currently possessed vessel, or null if no vessel is possessed.
func get_possessed_vessel() -> SarGameEntityVessel3D:
	return possessed_vessel

## Checks if this soul is currently possessing a vessel.
## Returns true if a vessel is possessed, false otherwise.
func is_possessing_vessel() -> bool:
	return true if get_possessed_vessel() else false
	
## Emits a signal indicating that the desired mouse mode should be changed.
func request_new_mouse_mode(p_mouse_mode: Input.MouseMode) -> void:
	mouse_mode_requested.emit(p_mouse_mode)
