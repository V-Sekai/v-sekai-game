extends Node3D

@export var origin_nodepath: NodePath = NodePath()


func get_origin() -> XROrigin3D:
	var origin: XROrigin3D = get_node_or_null(origin_nodepath)
	if origin:
		return origin
	else:
		return null
