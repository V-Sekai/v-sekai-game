@tool
class_name VSKMainScene
extends Node3D

## The VSKMainScene is intended to be the default main scene used by V-Sekai
## when the game is started without using a custom scene.
## 
## By default, it is intended to load the VSKStartupScene via a threaded
## load request while displaying some kind of indication that an operation
## is pending. It does this so that the application can become responsive
## as early as possible.

func _ready() -> void:
	if not Engine.is_editor_hint():
		var packed_scene: PackedScene = null
		if not startup_scene_path.is_empty():
			var error: Error = ResourceLoader.load_threaded_request(startup_scene_path, "PackedScene", true)
			
			if error == OK:
				while ResourceLoader.load_threaded_get_status(startup_scene_path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
					await get_tree().process_frame
					
					packed_scene = ResourceLoader.load_threaded_get(startup_scene_path)
				
		if packed_scene:
			get_tree().change_scene_to_packed(packed_scene)
		else:
			OS.alert("Failed to load startup scene.")
			get_tree().quit(1)

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray
	
	if startup_scene_path.is_empty():
		warnings.append("Path to startup scene is empty.")
	else:
		if not ResourceLoader.exists(startup_scene_path):
			warnings.append("The startup scene path does not point to a valid resource.")
		else:
			var startup_scene_local_path: String = ResourceUID.get_id_path(ResourceLoader.get_resource_uid(startup_scene_path))
			
			if startup_scene_path == get_scene_file_path() or \
			startup_scene_local_path == get_scene_file_path():
				warnings.append("The startup scene is set up recursively.")
	
	return warnings

###

## The path to the default scene intended to be loaded when initialized
## from a cold start.
@export_file('*.tscn') var startup_scene_path: String = "":
	set(p_startup_scene_path):
		startup_scene_path = p_startup_scene_path
		update_configuration_warnings()
