@tool
extends SarGameEntityComponent
class_name SarGameEntityEditorOnlyDisplayComponent3D

## A component which renders a scene to act as a helper visualization for
## SarGameEntity3D nodes in editor mode.

## The node which the instance should be parented to.
@export var visual_parent: Node3D = null
## A packed scene representing the visualization to use o
@export var packed_scene: PackedScene = null

func _setup_display_node(p_display_node: Node3D) -> void:
	for child in p_display_node.get_children():
		child.queue_free()
	
	var instance: Node = packed_scene.instantiate()
	p_display_node.add_child(instance)

func _ready() -> void:
	if Engine.is_editor_hint():
		if visual_parent:
			var display_node: Node3D = Node3D.new()
			
			_setup_display_node(display_node)
			
			visual_parent.add_child.call_deferred(display_node)
