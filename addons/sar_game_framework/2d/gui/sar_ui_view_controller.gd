@tool
extends Control
class_name SarUIViewController

func _ready() -> void:
	if not Engine.is_editor_hint():
		update_navigation_controller()
		if navigation_controller:
			set_anchors_and_offsets_preset(PRESET_FULL_RECT, PRESET_MODE_MINSIZE)
			
		# If we're the direct desendent of a NavigationController,
		# we should assign ourself to it.
		var parent = get_parent()
		if parent is SarUINavigationController:
			get_navigation_controller().push_view_controller.call_deferred(self, false)

###

func set_title(p_title: String) -> void:
	title = p_title

func get_title() -> String:
	return title

@export var title: String = "":
	get = get_title,
	set = set_title

var navigation_controller: SarUINavigationController = null:
	set = set_navigation_controller,
	get = get_navigation_controller


static func is_navigation_controller() -> bool:
	return false


func will_appear() -> void:
	pass


func will_disappear() -> void:
	pass

func set_navigation_controller(p_navigation_controller: SarUINavigationController) -> void:
	navigation_controller = p_navigation_controller


func get_navigation_controller() -> SarUINavigationController:
	return navigation_controller


func has_navigation_controller() -> bool:
	return navigation_controller != null


func update_navigation_controller() -> void:
	var control: Control = self
	while control:
		if control != self:
			if control is SarUINavigationController:
				set_navigation_controller(control)
				break

		control = control.get_parent() as Control
