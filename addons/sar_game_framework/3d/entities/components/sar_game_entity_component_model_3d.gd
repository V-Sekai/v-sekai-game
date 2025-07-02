@tool
extends SarGameEntityComponent
class_name SarGameEntityComponentModel3D

## This component is responsible for tracking and changing a model
## representation of the entity via a PackedScene property.

var _model_node: SarModel3D = null

func _create_model_node() -> SarModel3D:
	return SarModel3D.new()
			
func _convert_node_to_valid_model_type(p_model_node: Node3D) -> void:
	if not p_model_node is SarModel3D:
		p_model_node.set_script(SarModel3D)
			
func _clear_model_node() -> void:
	if _model_node:
		_model_node.queue_free()
		_model_node = null
			
func _set_model_node(p_model_node: Node3D) -> void:
	if p_model_node:
		_convert_node_to_valid_model_type(p_model_node)
		p_model_node.setup_model(p_model_node)
		
	_model_pre_change(p_model_node)
	
	_clear_model_node()
	
	if p_model_node:
		_model_node = p_model_node
		model_parent_node.add_child(_model_node)
		_model_changed()
		
func _nodes_scene_reimported(p_nodes: Array[Node]) -> void:
	if _model_node:
		for node: Node in p_nodes:
			if node.is_ancestor_of(_model_node):
				_update_model_from_scene()
		
func _model_pre_change(p_new_model_node: SarModel3D) -> void:
	model_pre_change.emit(p_new_model_node)
		
func _model_changed() -> void:
	model_changed.emit(_model_node)
	
func _model_instantiated(_node: Node3D) -> void:
	pass
		
func _update_model_from_scene() -> void:
	if is_node_ready():
		if model_parent_node:
			var instance: Node3D = null
			if model_scene:
				if use_asynchronous_instantiation and not Engine.is_editor_hint():
					# This probably needs to be made more robust with
					# a queue or custom thread pool to avoid collisions.
					var container: Array[Node3D] = [null]  # Single-element array to hold the result
					var instantiation_lambda = func(p_model_scene: PackedScene) -> void:
						var node: Node3D = p_model_scene.instantiate() as Node3D
						if node:
							container[0] = node
					
					var instantiation_task_id: int = WorkerThreadPool.add_task(instantiation_lambda.bind(model_scene), false, "")
					while not WorkerThreadPool.is_task_completed(instantiation_task_id):
						await get_tree().process_frame
						
					if container[0]:
						_model_instantiated(container[0])
					instance = container[0]
				else:
					instance = model_scene.instantiate() as Node3D
				
				instance.set_multiplayer_authority(model_parent_node.get_multiplayer_authority())
			_model_instantiated(instance)
			_set_model_node(instance)
		else:
			push_error("%s does not have a model container node assigned." % get_name())
	
func _ready() -> void:
	set_physics_process(not Engine.is_editor_hint())
	
func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray
	
	if model_parent_node == null:
		warnings.push_back("This component has no model parent node assigned.")
		
	return warnings
	
###

## Emitted when the model has changed.
signal model_changed(p_new_model: SarModel3D)
## Emitted before the model has changed.
signal model_pre_change(p_new_model: SarModel3D)

## Sets the PackedScene representing the model want to instantiate. The
## the model will then be instantiated and parented to model_parent_node.
func set_model_scene(p_model_scene: PackedScene) -> void:
	if model_scene != p_model_scene:
		model_scene = p_model_scene
		if not is_node_ready():
			await ready
		_update_model_from_scene()

## A PackedScene representing the model want to instantiate. The
## the model will then be instantiated and parented to model_parent_node.
@export var model_scene: PackedScene = null:
	set = set_model_scene

## If this is set to true, attempt to load the entity's model in a background
## thread, but not in the editor.
@export var use_asynchronous_instantiation: bool = false

## Sets the node that the model node should be parented to.
@export var model_parent_node: Node3D = null:
	set(p_model_parent_node):
		model_parent_node = p_model_parent_node
		_update_model_from_scene()
		update_configuration_warnings()

## Returns the skeleton node associated with the model if available.
func get_skeleton() -> Skeleton3D:
	if _model_node and _model_node.general_skeleton:
		return _model_node.general_skeleton
		
	return null

## Returns the motion scale value associated with model's skeleton if
## available. Otherwise, will return 1.0.
func get_motion_scale() -> float:
	var skeleton: Skeleton3D = get_skeleton()
	if skeleton:
		return skeleton.motion_scale
		
	return 1.0
	
## Returns the component's currently instantiated model node.
func get_model_node() -> SarModel3D:
	return _model_node
	
