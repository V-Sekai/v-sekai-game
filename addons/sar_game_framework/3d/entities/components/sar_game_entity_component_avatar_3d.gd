@tool
extends SarGameEntityComponentModel3D
class_name SarGameEntityComponentAvatar3D

## This component is subclasses the SarGameEntityComponentModel3D with
## that the SarModel3D it uses will actually be a SarAvatar3D.

## Returns the skeleton node associated with the avatar if available.
func get_skeleton() -> Skeleton3D:
	var avatar_node: SarAvatar3D = _model_node as SarAvatar3D
	if avatar_node and avatar_node.general_skeleton:
		return avatar_node.general_skeleton
		
	return null

## Returns the motion scale value associated with the avatar if
## available. Otherwise, will return 1.0.
func get_motion_scale() -> float:
	var skeleton: Skeleton3D = get_skeleton()
	if skeleton:
		return skeleton.motion_scale
		
	return 1.0
	
## Returns the component's currently instantiated avatar node.
func get_avatar_node() -> SarAvatar3D:
	return _model_node
