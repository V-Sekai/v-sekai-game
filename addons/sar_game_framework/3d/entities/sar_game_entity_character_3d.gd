@tool
extends SarGameEntityVessel3D
class_name SarGameEntityCharacter3D

## Base class for mobile entities with full CharacterBody3D physics.
##
## SarGameEntityCharacter3D is a class which is designed with the baseline
## functionality for an extension of SarGameEntityVessel3D in the context of
## the game's 3D simulation. At minimum, a character should contain an avatar
## and animation controller. Further functionality, should be provided by
## anything which is subclassed.

# Copies the avatar scene from this node to the avatar controller.
func _update_model_from_scene() -> void:
	if is_node_ready():
		var character_interface: SarGameEntityInterfaceCharacter3D = get_game_entity_interface() as SarGameEntityInterfaceCharacter3D
		if character_interface:
			var model_component: SarGameEntityComponentModel3D = character_interface.get_model_component()
			if model_component:
				model_component.model_scene = model_scene
		else:
			printerr("Game entity character interface is missing.")

func _nodes_scene_reimported(p_nodes: Array) -> void:
	for node: Node in p_nodes:
		if model_scene:
			if model_scene.resource_path == node.scene_file_path:
				model_scene = ResourceLoader.load(node.scene_file_path, "", ResourceLoader.CACHE_MODE_REPLACE)
				_update_model_from_scene()

func _ready() -> void:
	super._ready()

	_update_model_from_scene()
	
###

## Returns a string containing a path to the PackedScene associated with this
## particular GameEntity.
func get_game_entity_valid_scene_path() -> String:
	return "res://addons/sar_game_framework/3d/entities/sar_game_entity_character_3d.tscn"

## Reference the vessel's currently active model node.
var model_node: SarModel3D = null

## A PackedScene which can function as a compatible Galmodel node.
@export var model_scene: PackedScene = null:
	set(p_model_scene):
		model_scene = p_model_scene
		_update_model_from_scene()
