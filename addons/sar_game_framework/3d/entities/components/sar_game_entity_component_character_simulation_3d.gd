@tool
extends SarGameEntityComponent
class_name SarGameEntityComponentCharacterSimulation3D
	
var _simulation_node: SarSimulationCharacter3D = null
	
func _bind_simulation_node() -> void:
	if _simulation_node:
		_simulation_node.assign_game_entity_interface(game_entity_interface)
		
		if not game_entity.transform_changed.is_connected(_simulation_node._on_game_entity_transform_changed):
			if not SarUtils.assert_ok(game_entity.transform_changed.connect(_simulation_node._on_game_entity_transform_changed),
				"Could not connect signal 'game_entity.transform_changed' to '_simulation_node._on_game_entity_transform_changed'"):
				return
		if not game_entity.transform_pre_update.is_connected(_simulation_node._on_game_entity_transform_pre_update):
			if not SarUtils.assert_ok(game_entity.transform_pre_update.connect(_simulation_node._on_game_entity_transform_pre_update),
				"Could not connect signal 'game_entity.transform_pre_update' to '_simulation_node._on_game_entity_transform_pre_update'"):
				return
		if not game_entity.transform_post_update.is_connected(_simulation_node._on_game_entity_transform_post_update):
			if not SarUtils.assert_ok(game_entity.transform_post_update.connect(_simulation_node._on_game_entity_transform_post_update),
				"Could not connect signal 'game_entity.transform_post_update' to '_simulation_node._on_game_entity_transform_post_update'"):
				return
		
		if not model_component.model_changed.is_connected(_simulation_node._on_character_model_component_model_changed):
			if not SarUtils.assert_ok(model_component.model_changed.connect(_simulation_node._on_character_model_component_model_changed),
				"Could not connect signal 'model_component.model_changed' to '_simulation_node._on_character_model_component_model_changed'"):
				return
		if not model_component.model_pre_change.is_connected(_simulation_node._on_character_model_component_pre_model_changed):
			if not SarUtils.assert_ok(model_component.model_pre_change.connect(_simulation_node._on_character_model_component_pre_model_changed),
				"Could not connect signal 'model_component.model_pre_change' to '_simulation_node._on_character_model_component_pre_model_changed'"):
				return
		if not vessel_movement_component.pre_movement.is_connected(_simulation_node._on_vessel_movement_component_pre_movement):
			if not SarUtils.assert_ok(vessel_movement_component.pre_movement.connect(_simulation_node._on_vessel_movement_component_pre_movement),
				"Could not connect signal 'vessel_movement_component.pre_movement' to '_simulation_node._on_vessel_movement_component_pre_movement'"):
				return
		
		if not vessel_movement_component.post_movement.is_connected(_simulation_node._on_vessel_movement_component_post_movement):
			if not SarUtils.assert_ok(vessel_movement_component.post_movement.connect(_simulation_node._on_vessel_movement_component_post_movement),
				"Could not connect signal 'vessel_movement_component.post_movement' to '_simulation_node._on_vessel_movement_component_post_movement'"):
				return
		if not vessel_movement_component.movement_complete.is_connected(_simulation_node._on_vessel_movement_component_movement_complete):
			if not SarUtils.assert_ok(vessel_movement_component.movement_complete.connect(_simulation_node._on_vessel_movement_component_movement_complete),
				"Could not connect signal 'vessel_movement_component.movement_complete' to '_simulation_node._on_vessel_movement_component_movement_complete'"):
				return
		if not vessel_posession_component.possessed_by_soul.is_connected(_simulation_node._on_vessel_possession_component_soul_changed):
			if not SarUtils.assert_ok(vessel_posession_component.possessed_by_soul.connect(_simulation_node._on_vessel_possession_component_soul_changed),
				"Could not connect signal 'vessel_posession_component.possessed_by_soul' to '_simulation_node._on_vessel_possession_component_soul_changed'"):
				return
	
func _unbind_simulation_node() -> void:
	if _simulation_node:
		_simulation_node.notify_shutdown()
		
		if game_entity.transform_changed.is_connected(_simulation_node._on_game_entity_transform_changed):
			game_entity.transform_changed.disconnect(_simulation_node._on_game_entity_transform_changed) 
		if game_entity.transform_pre_update.is_connected(_simulation_node._on_game_entity_transform_pre_update):
			game_entity.transform_pre_update.disconnect(_simulation_node._on_game_entity_transform_pre_update)
		if game_entity.transform_post_update.is_connected(_simulation_node._on_game_entity_transform_post_update):
			game_entity.transform_post_update.disconnect(_simulation_node._on_game_entity_transform_post_update)
		
		if model_component.model_changed.is_connected(_simulation_node._on_character_model_component_model_changed):
			model_component.model_changed.disconnect(_simulation_node._on_character_model_component_model_changed)
		if model_component.model_pre_change.is_connected(_simulation_node._on_character_model_component_pre_model_changed):
			model_component.model_pre_change.disconnect(_simulation_node._on_character_model_component_pre_model_changed)
		
		if vessel_movement_component.pre_movement.is_connected(_simulation_node._on_vessel_movement_component_pre_movement):
			vessel_movement_component.pre_movement.disconnect(_simulation_node._on_vessel_movement_component_pre_movement)
		if vessel_movement_component.post_movement.is_connected(_simulation_node._on_vessel_movement_component_post_movement):
			vessel_movement_component.post_movement.disconnect(_simulation_node._on_vessel_movement_component_post_movement)
		if vessel_movement_component.movement_complete.is_connected(_simulation_node._on_vessel_movement_component_movement_complete):
			vessel_movement_component.movement_complete.disconnect(_simulation_node._on_vessel_movement_component_movement_complete)
		if vessel_posession_component.possessed_by_soul.is_connected(_simulation_node._on_vessel_possession_component_soul_changed):
			vessel_posession_component.possessed_by_soul.disconnect(_simulation_node._on_vessel_possession_component_soul_changed)
		
func _clear_simulation_node() -> void:
	if _simulation_node:
		_unbind_simulation_node()
		_simulation_node.queue_free()
		_simulation_node = null
		
func _set_simulation_node(p_simulation_node: SarSimulationCharacter3D) -> void:
	if p_simulation_node is SarSimulationCharacter3D:
		_simulation_node = p_simulation_node
		
		# Simulations are only assigned on local player authorities.
		if is_multiplayer_authority():
			# Do binding
			_bind_simulation_node()
			
			simulation_parent_container.add_child(_simulation_node)
			
			_simulation_node.notify_posession_changed(vessel_posession_component.get_soul())
	else:
		push_error("Attempted to assign invalid simulation node. Must inherit SarSimulationCharacter3D")
		
func _update_simulation_from_scene() -> void:
	if is_node_ready():
		# Clear the original model
		_clear_simulation_node()
		
		if simulation_scene:
			if simulation_parent_container:
				var instance: SarSimulationCharacter3D = simulation_scene.instantiate() as SarSimulationCharacter3D
				instance.set_multiplayer_authority(simulation_parent_container.get_multiplayer_authority())
				if instance:
					_set_simulation_node(instance)
				else:
					_set_simulation_node(null)
			else:
				push_error("%s does not have a simulation container node assigned." % get_name())
				
func _ready() -> void:
	if not SarUtils.assert_true(simulation_parent_container, "SarGameEntityComponentCharacterSimulation3D: simulation_parent_container is not available"):
		return
	
	_update_simulation_from_scene()
	
func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray
	
	if game_entity_interface == null:
		warnings.push_back("This component has no game entity interface assigned.")
	
	if simulation_parent_container == null:
		warnings.push_back("This component has no simulation parent node assigned.")

		
	return warnings

###

@export var game_entity_interface: SarGameEntityInterfaceCharacter3D = null:
	set(p_game_entity_interface):
		game_entity_interface = p_game_entity_interface
		if Engine.is_editor_hint():
			update_configuration_warnings()

@export var vessel_movement_component: SarGameEntityComponentVesselMovement3D = null:
	set(p_vessel_movement_component):
		vessel_movement_component = p_vessel_movement_component
		if Engine.is_editor_hint():
			update_configuration_warnings()
		
@export var vessel_posession_component: SarGameEntityComponentVesselPossession = null:
	set(p_vessel_posession_component):
		vessel_posession_component = p_vessel_posession_component
		if Engine.is_editor_hint():
			update_configuration_warnings()

@export var model_component: SarGameEntityComponentModel3D = null:
	set(p_model_component):
		model_component = p_model_component
		if Engine.is_editor_hint():
			update_configuration_warnings()

@export var simulation_parent_container: Node3D = null:
	set(p_simulation_parent_container):
		simulation_parent_container = p_simulation_parent_container
		if Engine.is_editor_hint():
			update_configuration_warnings()

@export var simulation_scene: PackedScene = null:
	set(p_simulation_scene):
		simulation_scene = p_simulation_scene
		if Engine.is_editor_hint():
			update_configuration_warnings()
