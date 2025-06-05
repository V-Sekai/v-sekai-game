@tool
extends Node
class_name SarSimulationComponentMenu

## Component for managing the state of a local player menu inside the
## the simulation space.

# Called to emit the corresponding signal for whether the menu is active
# or inactive.
func _emit_signals() -> void:
	if not Engine.is_editor_hint():
		if menu_active:
			menu_state_activated.emit()
		else:
			menu_state_deactivated.emit()

# Called to update whether or not we should pause the tree.
func _update_pause_state() -> void:
	pass
	# TODO: allow pausing when not multiplayer.
	#get_tree().paused = menu_active
	
func _ready() -> void:
	_emit_signals()
	_update_pause_state()
	
###

## Emitted when the menu state is activated.
signal menu_state_activated
## Emitted when the menu state is deactivated.
signal menu_state_deactivated

## The root simulation node.
@export var simulation: SarSimulationVessel3D = null

## Booleans controlling whether the menu is active or not.
@export var menu_active: bool = false:
	set = set_menu_active

func set_menu_active(p_menu_active: bool) -> void:
	if p_menu_active != menu_active:
		menu_active = p_menu_active
		_emit_signals()
		_update_pause_state()

## Method to toggle the menu on or off.
func menu_toggle() -> void:
	menu_active = !menu_active
