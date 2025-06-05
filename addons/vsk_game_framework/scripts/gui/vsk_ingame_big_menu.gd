extends Control
class_name VSKIngameBigMenu


func _on_ingame_quick_menu_avatar_menu_requested() -> void:
	show()

func _on_ingame_quick_menu_explore_menu_requested() -> void:
	show()

func _request_new_avatar(p_path: String) -> void:
	var gei: VSKGameEntityInterfacePlayer3D = simulation.get_game_entity_interface()
	if gei:
		if gei.get_avatar_sync_component():
			gei.get_avatar_sync_component().requested_avatar_path = p_path

func _on_avatar_url_selected(p_url: String) -> void:
	if menu_compoent:
		menu_compoent.set_menu_active(false)
	
	_request_new_avatar(p_url)

###

@export var simulation: SarSimulationVessel3D = null
@export var controller: VSKUIViewControllerBigMenu = null
@export var menu_compoent: SarSimulationComponentMenu = null
