@tool
extends EditorPlugin

const Utils = preload("res://addons/sketchfab/Utils.gd")
const MainPanel = preload("res://addons/sketchfab/Main.tscn")
var main_panel_instance

func _enter_tree():
	main_panel_instance = MainPanel.instantiate()
	
	main_panel_instance.editor_interface = get_editor_interface()
	# Add the main panel to the editor's main viewport.
	get_editor_interface().get_editor_main_screen().add_child(main_panel_instance)
	# Hide the main panel. Very much required.
	_make_visible(false)

func _exit_tree():
	if main_panel_instance:
		main_panel_instance.queue_free()

func _has_main_screen():
	return true

func _make_visible(visible):
	if main_panel_instance:
		main_panel_instance.visible = visible

func _get_plugin_name():
	return "Sketchfab"

func _get_plugin_icon():
	# Call _get_editor_scale() here as SceneTree is not instanced yet
	return load("res://addons/sketchfab/plugin-icon.png")
