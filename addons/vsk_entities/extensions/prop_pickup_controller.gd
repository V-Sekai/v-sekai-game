extends Node

@export var _entity_node_path: NodePath = NodePath()
@onready var _entity_node: Node = get_node_or_null(_entity_node_path)


func _on_attempt_grab(p_args: Dictionary) -> void:
	_entity_node.request_to_become_master()

	#var grabber_network_id: int = p_args["grabber_network_id"]
	var grabber_entity: EntityRef = p_args["grabber_entity_ref"]
	var grabber_transform: Transform3D = p_args["grabber_transform"]

	_entity_node.set_global_transform(grabber_transform)
	_entity_node.hierarchy_component_node.request_reparent_entity(
		p_args["grabber_entity_ref"], p_args["grabber_attachment_id"]
	)
	_entity_node.send_entity_message(
		grabber_entity, "pickup_grab_callback", {"entity_ref": _entity_node.get_entity_ref()}
	)


func _on_attempt_drop(p_args: Dictionary) -> void:
	var grabber_entity: EntityRef = p_args["grabber_entity_ref"]

	_entity_node.hierarchy_component_node.request_reparent_entity(null, 0)
	_entity_node.send_entity_message(
		grabber_entity, "pickup_drop_callback", {"entity_ref": _entity_node.get_entity_ref()}
	)


func _on_entity_message(p_message, p_args) -> void:
	match p_message:
		"attempting_grab":
			_on_attempt_grab(p_args)
		"attempting_drop":
			_on_attempt_drop(p_args)
