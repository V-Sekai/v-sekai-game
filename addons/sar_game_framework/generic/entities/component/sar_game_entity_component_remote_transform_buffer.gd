@tool
extends SarGameEntityComponent
class_name SarGameEntityComponentRemoteTransformBuffer

## This class is designed to be a container for position transforms
## received from the MultiplayerSynchronizers which can be stored
## in a queued buffer and interpolated. Currently unfinished.

var _current_transform: Transform3D = Transform3D()

func _on_transform_snapshot_transform_updated(p_transform: Transform3D) -> void:
	_current_transform = p_transform
	
func _reset_transform(p_transform: Transform3D) -> void:
	_current_transform = p_transform
	
func _update_entity_transform() -> void:
	movement_component.set_physics_position(_current_transform.origin)
	game_entity.transform = _current_transform
	
# Only run on remote peers.
func _physics_process(_delta: float) -> void:
	_update_entity_transform()
	
func _ready() -> void:
	_current_transform = game_entity.transform
	if not Engine.is_editor_hint() and not is_multiplayer_authority():
		set_physics_process(true)
	else:
		set_physics_process(false)

###

## Reference to the movement component.
@export var movement_component: SarGameEntityComponentVesselMovement3D = null
