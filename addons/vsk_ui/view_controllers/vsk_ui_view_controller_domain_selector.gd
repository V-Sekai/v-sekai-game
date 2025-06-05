@tool
extends SarUIViewController
class_name VSKUIViewControllerDomainSelector

signal domain_selected(p_url: String)

func _on_domain_selector_view_url_selected(p_url: String) -> void:
	domain_selected.emit(p_url)
	
	get_navigation_controller().pop_view_controller(true)

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	if not view:
		warnings.push_back("View is not assigned.")
	
	return warnings

###

@export var view: VSKUIViewDomainSelector = null:
	set(p_view):
		view = p_view
		update_configuration_warnings()

func set_url(p_url: String) -> void:
	if view:
		view.set_url(p_url)
