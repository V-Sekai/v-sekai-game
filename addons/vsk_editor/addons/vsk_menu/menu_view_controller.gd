extends "res://addons/navigation_controller/view_controller.gd"

@export var default_focus: NodePath


func back_button_pressed():
	if has_navigation_controller():
		get_navigation_controller().pop_view_controller(true)
