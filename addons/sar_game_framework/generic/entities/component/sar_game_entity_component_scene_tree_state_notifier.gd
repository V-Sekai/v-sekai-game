@tool
extends SarGameEntityComponent
class_name SarGameEntityComponentSceneTreeStateNotifier

## This component is responsible for informing nodes in [group_name] when this
## node enter or exits the scene tree, and when it is ready.

func _enter_tree() -> void:
	get_tree().call_group(group_name, "_scene_tree_state_notifier_entered", game_entity)
	
func _exit_tree() -> void:
	get_tree().call_group(group_name, "_scene_tree_state_notifier_exited", game_entity)
	
func _ready() -> void:
	get_tree().call_group(group_name, "_scene_tree_state_notifier_ready", game_entity)

###

## The name of the groups which should be notified that this node has
## entered or exited the scene.
@export var group_name: String = ""
