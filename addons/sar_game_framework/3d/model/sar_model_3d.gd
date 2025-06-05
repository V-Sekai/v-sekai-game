@tool
extends Node3D
class_name SarModel3D

## This class is meant to be a base class for a type of scene instantated
## by a SarGameEntityComponentModel3D to provide visual representation of
## a SarGameEntity3D.

func _ready() -> void:
	if not Engine.is_editor_hint():
		setup_model(self)

###

## Virtual function meant to be called once the model has been
## instantiated.
func setup_model(_root_node: Node3D) -> void:
	return
