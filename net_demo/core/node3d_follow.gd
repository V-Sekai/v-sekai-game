extends Node3D

@export_node_path(Node3D) var target = NodePath()

func _get_target_node() -> Node3D:
	return get_node(target)
