@tool
extends EditorPlugin

var resource_import_plugin
var editor_scene_import_modifier

func _enter_tree():
	#direct import plugin for gltf, comment out if you don't want the custom Godot Subdiv Importer
	resource_import_plugin=load("res://addons/godot_subdiv/resource_import_plugin.gd").new()
	add_import_plugin(resource_import_plugin)
	
	#This adds custom options to scene importer, remove if you don't want subdivision options for every mesh
	editor_scene_import_modifier=load("res://addons/godot_subdiv/scene_import_modifier_plugin.gd").new()
	add_scene_post_import_plugin(editor_scene_import_modifier, true)

func _exit_tree():
	remove_import_plugin(resource_import_plugin)
	resource_import_plugin = null
	
	remove_scene_post_import_plugin(editor_scene_import_modifier)
	editor_scene_import_modifier=null
