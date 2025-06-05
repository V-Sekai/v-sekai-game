@tool
extends Node
class_name SarGameEntityComponentVesselPossession

## This component is responsible for keeping track of the possession state
## of a vessel type game entity. It will emit the possessed_by_soul when
## possessed with the possessing soul, or null is the soul was released.

## This is the soul which is currently assigned to this vesssel.
var _soul: SarSoul = null
		
func _ready() -> void:
	if _soul:
		possessed_by_soul.emit(_soul)
		
func _exit_tree() -> void:
	if _soul:
		_soul.unpossess()
		
###

## Emitted when possessed by a soul. Can be null.
signal possessed_by_soul(p_soul: SarSoul)

## Returns the vessel's currently active soul.
func get_soul() -> SarSoul:
	return _soul
	
## Assigns a soul to this vessel.
func set_soul(p_soul: SarSoul) -> bool:
	if p_soul != _soul:
		_soul = p_soul
		
		if is_node_ready():
			possessed_by_soul.emit(_soul)
	
		return true
	else:
		return false
