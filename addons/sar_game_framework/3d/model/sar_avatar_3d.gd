@tool
extends SarModel3D
class_name SarAvatar3D

## This class is an extension of SarModel3D implementing the expectation
## of a model having both a uniquely named skeleton and an AnimationTreeDriver
## (although these are not a hard requirements). Subclass this further to
## include additional game-specific requirements or automated setup stages
## in the absence of these requirements.

var general_skeleton: Skeleton3D = null

func _find_avatar_skeleton(p_node: Node) -> Skeleton3D:
	var new_skeleton: Skeleton3D = p_node.get_node_or_null("%GeneralSkeleton")
	if new_skeleton:
		return new_skeleton
	else:
		for child in p_node.get_children():
			new_skeleton = _find_avatar_skeleton(child)
			if new_skeleton:
				return new_skeleton
				
	return null
		
func _ready() -> void:
	if not Engine.is_editor_hint():
		setup_model(self)

###

## Reference to the node responsible for managing the parameters in
## an AnimationTree.
@export var animation_tree_driver: AnimationTreeDriver = null

## Subclassed virtual method which will now attempt cache a uniquely
## named Skeleton3D class when the avatar is instantiated.
func setup_model(p_root_node: Node3D) -> void:
	super.setup_model(p_root_node)
	
	if not general_skeleton:
		general_skeleton = _find_avatar_skeleton(p_root_node)
