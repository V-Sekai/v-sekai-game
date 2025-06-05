@tool
extends Node
class_name SarSimulationComponentMouseMode

## Component for managing the state of the mouse mode inside the
## the player's simulation space.

# The current soul assigned by the simulation space.
var _current_soul: SarSoul = null

# This method checks if we are running in XR mode or not.
func _is_xr_enabled() -> bool:
	return XRServer.primary_interface != null

# This method is called when the preferred mouse mode is changed.
# It will first check if we are in XR mode, and then attempt to request
# the assigned SarSoul to change the actual mouse mode, which it may
# or may not do depending on what type of privileges this soul has.
func _update_mouse_mode() -> void:
	if not Engine.is_editor_hint():
		if _is_xr_enabled():
			if _current_soul:
				_current_soul.request_new_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			if _current_soul:
				_current_soul.request_new_mouse_mode(preferred_mouse_mode)

# Should be called when the soul possession has changed any may require the
# mouse mode to be updated. It will first attempt to reset the mouse mode
# on the currently assigned soul to visible, and then once the new soul
# soul has been assigned, call the _update_mouse_mode method.
func _on_possession_changed(p_soul: SarSoul) -> void:
	if not Engine.is_editor_hint():
		if not is_node_ready():
			await ready
	
		if _current_soul:
			_current_soul.request_new_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	_current_soul = p_soul
	
	if not Engine.is_editor_hint():
		_update_mouse_mode()

func _on_shutdown() -> void:
	if not Engine.is_editor_hint():
		if _current_soul:
			_current_soul.request_new_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _ready() -> void:
	if not Engine.is_editor_hint():
		assert(simulation)
		_current_soul = simulation.get_game_entity_interface().get_possession_component().get_soul()
		if not Engine.is_editor_hint():
			_update_mouse_mode()

# I'm not sure how we can detect when the signal state has changed.
func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = SarConnectionUtilities.get_warnings_for_missing_incoming_connections(self, [_on_possession_changed])
		
	return warnings

###

## Method to assign the preferred mouse mode to be used by this
## simulation space.
func set_preferred_mouse_mode(p_mouse_mode: Input.MouseMode) -> void:
	if preferred_mouse_mode != p_mouse_mode:
		preferred_mouse_mode = p_mouse_mode
		_update_mouse_mode()
		
## The root simulation node.
@export var simulation: SarSimulationVessel3D = null

## The perferred Input.MouseMode which should be used by this
## simulation space.
@export var preferred_mouse_mode: Input.MouseMode:
	set = set_preferred_mouse_mode
