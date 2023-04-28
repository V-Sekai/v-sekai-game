@tool
class_name ComponentNode extends Node

var entity_node: Node = null
@export var _entity_node_path: NodePath = NodePath()
var nodes_cached: bool = false


func nodes_are_cached() -> bool:
	return nodes_cached


func get_entity_node() -> Node:
	return entity_node


func cache_nodes() -> void:
	nodes_cached = true

	entity_node = get_node_or_null(_entity_node_path)
	if entity_node == self:
		entity_node = null


func _threaded_instance_setup(_instance_id: int, _network_reader: RefCounted) -> void:
	pass
