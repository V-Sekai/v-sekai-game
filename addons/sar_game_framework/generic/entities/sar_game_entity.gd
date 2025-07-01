@tool
extends Node
class_name SarGameEntity

## SarGameEntity is a base class representing a variety of self-contained nodes
## meant to exist in the game world including players, NPCs, interactable items,
## mirrors, and triggers. They are intended to structured in compositional fashion,
## with most logic being implemented via nodes and callbacks. They are also
## intended to compatible with thread groups, so should not directly access each
## other unless through an approved callback interface.

# Function to check if this node's packed scene inherits from a base scene.
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

func _get(property: StringName) -> Variant:
	match property:
		"game_entity_interface":
			if game_entity_interface:
				return game_entity_interface
			else:
				return NodePath()
		_:
			if property.begins_with("components/"):
				var interface: SarGameEntityInterface = get_game_entity_interface()
				if interface:
					for component: Node in interface.public_components:
						if component.get_script():
							var first_part: String = "components/" + component.get_script().get_global_name() + "/"
							if property.begins_with(first_part):
								return component.get(property.lstrip(first_part))
			
	return null
	
func _set(property: StringName, value: Variant) -> bool:
	match property:
		"game_entity_interface":
			game_entity_interface = value if value is SarGameEntityInterface3D else null
			return true
		_:
			if property.begins_with("components/"):
				var interface: SarGameEntityInterface = get_game_entity_interface()
				if interface:
					for component: Node in interface.public_components:
						if component.get_script():
							var first_part: String = "components/" + component.get_script().get_global_name() + "/"
							if property.begins_with(first_part):
								component.set(property.lstrip(first_part), value)
				
			
	return false
		
func _get_property_list() -> Array[Dictionary]:
	var properties: Array[Dictionary] = []

	var interface_path_usage: int = PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_SCRIPT_VARIABLE
	if Engine.is_editor_hint():
		var valid_path: String = get_game_entity_valid_scene_path()

		var editor_interface = Engine.get_singleton("EditorInterface")
		if not editor_interface:
			push_error("EditorInterface singleton is not available")
			return properties
		if not (editor_interface.get_edited_scene_root() == self and self.scene_file_path == valid_path):
			interface_path_usage = PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_SCRIPT_VARIABLE
		
	properties.append({
		"name": "game_entity_interface",
		"type": TYPE_OBJECT,
		"class_name":"SarGameEntityInterface",
		"hint": PROPERTY_HINT_NODE_TYPE,
		"hint_string": "SarGameEntityInterface",
		"usage":interface_path_usage
	})
	
	var interface: SarGameEntityInterface = get_game_entity_interface()
	if interface:
		for component: Node in interface.public_components:
			if component.get_script():
				var property_list: Array[Dictionary] = component.get_property_list()
				for property: Dictionary in property_list:
					if property["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE:
						if property["name"] != "game_entity":
							property["name"] = "components/" + component.get_script().get_global_name() + "/" + property["name"]
							properties.append(property)
	
	return properties
	
func _get_configuration_warnings() -> PackedStringArray:
	var string_array: PackedStringArray = PackedStringArray([])
	
	var valid_path: String = get_game_entity_valid_scene_path()
	if not _is_inherited_base_scene(self, valid_path):
		assert(string_array.append("The script for this GameEntity must be attached to scene derived from %s." % valid_path) == false)
		
	if not game_entity_interface:
		assert(string_array.append("Game Entity interface has not been assigned") == false)
		
	if not FileAccess.file_exists(get_game_entity_valid_scene_path()):
		assert(string_array.append("Entity file path %s does not exist." % get_game_entity_valid_scene_path()) == false)
		
	return string_array
	
func _physics_process(_delta: float) -> void:
	return
	
func _enter_tree() -> void:
	if not Engine.is_editor_hint():
		scene_file_path = get_game_entity_valid_scene_path()
		
func _ready() -> void:
	return
	
###

## Reference to the GameEntity's interface.
var game_entity_interface: SarGameEntityInterface = null

## Returns the game entity interface.
func get_game_entity_interface() -> SarGameEntityInterface:
	return game_entity_interface

## Returns a string containing a path to the PackedScene associated with this
## particular GameEntity.
func get_game_entity_valid_scene_path() -> String:
	return ""
