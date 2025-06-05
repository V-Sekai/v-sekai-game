@tool
extends Control
class_name VSKIngameMenu

signal avatar_menu_requested
signal explore_menu_requested

@export var simulation: SarSimulationVessel3D = null

func _on_quick_menu_avatar_menu_requested() -> void:
	avatar_menu_requested.emit()
	hide()

func _on_quick_menu_explore_menu_requested() -> void:
	explore_menu_requested.emit()
	hide()
