@tool
extends EditorPlugin


func _init():
	print("Initialising ExtendedKinematicBody plugin")


func _notification(p_notification: int):
	match p_notification:
		NOTIFICATION_PREDELETE:
			print("Destroying ExtendedKinematicBody plugin")


func _get_plugin_name() -> String:
	return "ExtendedKinematicBody"


func _enter_tree() -> void:
	add_custom_type(
		"ExtendedKinematicBody",
		"KinematicBody3D",
		preload("./extended_kinematic_body.gd"),
		load("res://addons/extended_kinematic_body/icon_extended_kinematic_body.svg")
	)


func _exit_tree() -> void:
	remove_custom_type("ExtendedKinematicBody")
