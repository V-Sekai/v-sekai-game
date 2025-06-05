@tool
extends SarUIViewController
class_name SarUINavigationController

# Whether input events are currently being blocked (for transitions between views)
var _blocked_input_counter: int = 0

func _update_filter() -> void:
	if _is_input_disabled():
		mouse_filter = Control.MOUSE_FILTER_STOP
	else:
		mouse_filter = Control.MOUSE_FILTER_PASS

func _is_input_disabled() -> bool:
	return _blocked_input_counter > 0

# The stack of view controllers which we can push and pop to.
var _view_controller_stack: Array[SarUIViewController] = []

func _input(_event: InputEvent) -> void:
	if _is_input_disabled():
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PREDELETE:
			for view_controller in _view_controller_stack:
				if is_instance_valid(view_controller):
					view_controller.queue_free()
	
func _clear_content(p_delete: bool) -> void:
	if content:
		for child in content.get_children():
			if p_delete:
				child.queue_free()
			content.remove_child(child)
			
func _add_view_controller_to_content(p_view_controller: SarUIViewController) -> void:
	if content:
		content.add_child(p_view_controller, true)
	
###

@export var content: Control = null

func get_top_view_controller() -> SarUIViewController:
	return _view_controller_stack.front()


func push_view_controller(p_view_controller: SarUIViewController, _animated: bool) -> void:
	if p_view_controller.is_inside_tree():
		p_view_controller.get_parent().remove_child(p_view_controller)
	
	if _animated:
		pass

	if get_top_view_controller():
		get_top_view_controller().will_disappear()

	_view_controller_stack.push_front(p_view_controller)

	_clear_content(false)

	p_view_controller.will_appear()
	
	_add_view_controller_to_content(get_top_view_controller())


func pop_view_controller(_animated: bool) -> void:
	if _animated:
		pass

	if get_top_view_controller():
		get_top_view_controller().will_disappear()

	_clear_content(true)

	if !_view_controller_stack.is_empty():
		_view_controller_stack.pop_front()
		if !_view_controller_stack.is_empty():
			_add_view_controller_to_content(get_top_view_controller())
	else:
		push_error("Tried to pop root view controller.")


func clear_view_controller_stack() -> void:
	while !_view_controller_stack.is_empty():
		pop_view_controller(false)

func get_view_controllers() -> Array:
	return _view_controller_stack
	
func block_input() -> void:
	_blocked_input_counter += 1
	
	_update_filter()
	
func unblock_input() -> void:
	if _blocked_input_counter > 0:
		_blocked_input_counter -= 1
		
	_update_filter()
