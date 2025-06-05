@tool
extends SarGameEntityComponentAvatar3D
class_name VSKGameEntityComponentAvatar3D
		
func _convert_node_to_valid_model_type(p_model_node: Node3D) -> void:
	if not p_model_node is VSKAvatar3D:
		p_model_node.set_script(VSKAvatar3D)

func _model_instantiated(p_node: Node3D) -> void:
	super._model_instantiated(p_node)

	if p_node:
		var visual_instances: Array[Node] = p_node.find_children("*", "VisualInstance3D", true)
		for instance: Node in visual_instances:
			var vi: VisualInstance3D = instance as VisualInstance3D
			if vi:
				# If we have the first-person layer assign, assign it to the third-person layer
				# for other peers.
				if not is_multiplayer_authority():
					if vi.get_layer_mask_value(3):
						vi.set_layer_mask_value(2, true)
						
				# Make sure all the geometry instances have GI mode disabled.
				if vi is GeometryInstance3D:
					(vi as GeometryInstance3D).gi_mode = GeometryInstance3D.GI_MODE_DISABLED
						
		# Disable all collision objects in the avatar for both authority and peers.
		var collision_object_instances: Array[Node] = p_node.find_children("*", "CollisionObject3D", true)
		for instance: Node in collision_object_instances:
			var co: CollisionObject3D = instance as CollisionObject3D
			if co:
				co.disable_mode = CollisionObject3D.DISABLE_MODE_REMOVE
				co.process_mode = Node.PROCESS_MODE_DISABLED
	
