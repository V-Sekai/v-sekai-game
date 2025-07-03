@tool
extends Node3D
class_name SarGameEntity3D

## Base class for game entities which gain their functionality
## from child nodes acting as components. Entities should be instantiated from
## PackedScene files derived from the base scene path.

# Cleans the node hierarchy for editor preview purposes. Replaces non-visual nodes
# with basic Node3D instances while preserving transforms and visibility. This ensures
# previews only show renderable geometry without triggering game logic.
static func _clean_preview_node(p_node: Node) -> Node:
	# Handle non-Node3D root case
	var node_3d: Node3D = p_node as Node3D
	if (node_3d == null):
		# Replace incompatible root with empty Node3D
		var replacement_node: Node3D = Node3D.new()
		replacement_node.set_name(p_node.get_name())
		p_node.replace_by(replacement_node)
		p_node.free()
		p_node = replacement_node
	else:
		# Replace Node3D if it doesn't provide visual representation
		var visual_instance: VisualInstance3D = node_3d as VisualInstance3D
		if visual_instance == null:
			# Preserve transform properties when replacing
			var replacement_node: Node3D = Node3D.new()
			replacement_node.set_name(node_3d.get_name())
			replacement_node.set_visible(node_3d.is_visible())
			replacement_node.set_transform(node_3d.get_transform())
			replacement_node.set_rotation_edit_mode(node_3d.get_rotation_edit_mode())
			replacement_node.set_rotation_order(node_3d.get_rotation_order())
			replacement_node.set_as_top_level(node_3d.is_set_as_top_level())
			p_node.replace_by(replacement_node)
			p_node.free()
			p_node = replacement_node
	
	# Recursively process children
	for i: int in range(0, p_node.get_child_count()):
		var _cleaned_node: Node = _clean_preview_node(p_node.get_child(i))
		
	return p_node

# Validates scene inheritance by checking if this node's scene ultimately inherits
# from the specified base scene path. Used to enforce proper scene setup.
static func _is_inherited_base_scene(p_node: Node, p_base_scene_path: String) -> bool:
	if p_node.scene_file_path == "":
		return false
	
	var node_scene: PackedScene = load(p_node.scene_file_path)
	while node_scene != null:
		if node_scene.resource_path == p_base_scene_path:
			return true
		
		var scene_state: SceneState = node_scene.get_state()
		node_scene = scene_state.get_node_instance(0)

	return false

# Custom property getter supporting component property namespacing.
# Format: "components/[ComponentType]/[PropertyName]"
func _get(property: StringName) -> Variant:
	match property:
		"game_entity_interface":
			if game_entity_interface:
				return game_entity_interface
			else:
				return NodePath()
		_:
			if property.begins_with("components/"):
				var interface: SarGameEntityInterface3D = get_game_entity_interface()
				if interface:
					for component: Node in interface.public_components:
						if component.get_script():
							var first_part: String = "components/" + component.get_script().get_global_name() + "/"
							if property.begins_with(first_part):
								return component.get(property.lstrip(first_part))
			
	return null
	
# Custom property setter handling component property namespacing.
func _set(property: StringName, value: Variant) -> bool:
	match property:
		"game_entity_interface":
			game_entity_interface = value if value is SarGameEntityInterface3D else null
			return true
		_:
			if property.begins_with("components/"):
				var interface: SarGameEntityInterface3D = get_game_entity_interface()
				if interface:
					for component: Node in interface.public_components:
						if component.get_script():
							var first_part: String = "components/" + component.get_script().get_global_name() + "/"
							if property.begins_with(first_part):
								component.set(property.lstrip(first_part), value)
			
	return false
		
# Dynamically generates property list for editor inspection by combining:
# 1. The interface reference
# 2. All exposed component properties (namespaced)
func _get_property_list() -> Array[Dictionary]:
	var properties: Array[Dictionary] = []

	var interface_path_usage: int = PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_SCRIPT_VARIABLE
	if Engine.is_editor_hint():
		var valid_path: String = get_game_entity_valid_scene_path()
		
		if not valid_path.is_empty():
			if not (EditorInterface.get_edited_scene_root() == self and self.scene_file_path == valid_path):
				interface_path_usage = PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_SCRIPT_VARIABLE
		
	# Add interface reference property
	properties.append({
		"name": "game_entity_interface",
		"type": TYPE_OBJECT,
		"class_name":"SarGameEntityInterface3D",
		"hint": PROPERTY_HINT_NODE_TYPE,
		"hint_string": "SarGameEntityInterface3D",
		"usage":interface_path_usage
	})
	
	var interface: SarGameEntityInterface3D = get_game_entity_interface()
	if interface:
		# Get additional properties from the public components as defined in
		# the interface.
		for component: Node in interface.public_components:
			if component.get_script():
				var property_list: Array[Dictionary] = component.get_property_list()
				for property: Dictionary in property_list:
					if property["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE:
						if property["name"] != "game_entity":
							property["name"] = "components/" + component.get_script().get_global_name() + "/" + property["name"]
							properties.append(property)
	
	return properties
	
# Generates editor warnings for common setup issues
func _get_configuration_warnings() -> PackedStringArray:
	var string_array: PackedStringArray = PackedStringArray([])
	
	# Scene inheritance validation
	var valid_path: String = get_game_entity_valid_scene_path()
	if not valid_path.is_empty():
		if not _is_inherited_base_scene(self, valid_path):
			SarUtils.assert_equal(string_array.append("The script for this GameEntity must be attached to scene derived from %s." % valid_path),
			false)

		if not FileAccess.file_exists(get_game_entity_valid_scene_path()):
			SarUtils.assert_equal(string_array.append("Entity file path %s does not exist." % get_game_entity_valid_scene_path()),
			false)

	# Interface assignment check
	if not game_entity_interface:
		SarUtils.assert_equal(string_array.append("Game Entity interface has not been assigned"),
		false)
		
	return string_array
	
# Ensures correct scene path is set at runtime
func _enter_tree() -> void:
	if not Engine.is_editor_hint():
		scene_file_path = get_game_entity_valid_scene_path()

###

## Emitted when the entity is teleported.
signal teleported(p_transform: Transform3D)

## Subclasses must override to return the correct base scene path.
## This requirement is designed to allow inherited variations of defined
## entity types for game worlds. If this path does not match the scene's
## path, during multiplayer, the scene path will be forced to match
## its parent type, which will allow the game engine to treat it merely
## as a variation of the base type, potentially with parameter customization,
## rather than wholly new entity type. Godot's multiplayer requires the list
## of spawnable scenes to be more or less hard-defined. 
func get_game_entity_valid_scene_path() -> String:
	return ""
	
## Composition interface that manages this entity's components. The interface node
## should be set up in the inherited scene to provide component functionality.
var game_entity_interface: SarGameEntityInterface3D = null

## Returns the composition interface for this entity. Used by components to access
## shared functionality and other components.
func get_game_entity_interface() -> SarGameEntityInterface3D:
	return game_entity_interface

## Will set the position of the entity while also resetting its
## interpolation and emitting the teleported signal.
@rpc("authority", "call_local", "unreliable_ordered")
func teleport(p_transform: Transform3D) -> void:
	transform = p_transform
	reset_physics_interpolation()
	teleported.emit(transform)

## Cleanly removes entity from scene tree and memory. Prefer this over direct free().
func kill() -> void:
	if is_inside_tree():
		get_parent().remove_child(self)
		queue_free()
