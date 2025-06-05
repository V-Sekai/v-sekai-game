@tool
extends SarUIViewController
class_name VSKUIViewControllerAccountAction

const _DOMAIN_SELECTOR_VIEW_CONTROLLER: PackedScene = preload("res://addons/vsk_ui/view_controllers/vsk_ui_view_controller_domain_selector.tscn")

func _domain_selected(p_url: String) -> void:
	view.set_domain(p_url)

func _on_view_pick_other_domain_selected() -> void:
	var view_controller: VSKUIViewControllerDomainSelector = _DOMAIN_SELECTOR_VIEW_CONTROLLER.instantiate()
	assert(view_controller.domain_selected.connect(_domain_selected) == OK)
	get_navigation_controller().push_view_controller(view_controller, true)
	view_controller.set_url(view.get_domain())

func _ready() -> void:
	super._ready()
	
	if not Engine.is_editor_hint():
		assert(view)
		
func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	if not view:
		warnings.push_back("View is not assigned.")
	
	return warnings
###

@export var view: VSKUIViewAccountAction = null:
	set(p_view):
		view = p_view
		update_configuration_warnings()
