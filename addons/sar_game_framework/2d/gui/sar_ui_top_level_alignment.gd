@tool
extends Control
class_name SarUITopLevelAlignment

## This script forces its first child to become top-level
## and attempts to align it to this node's global rect.
## It is designed to workaround limitations with the clip_children
## feature, which currently does not allow recursive clipping.
## A more proper engine-oriented way to fix this would likely
## be to use the stencil buffer. If such a fix is applied,
## this script can be safely removed.

func _update() -> void:
	var child_control: Control = get_child(0)
	if child_control:
		child_control.top_level = true
		child_control.position = get_global_rect().position
		child_control.size = get_global_rect().size

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_TRANSFORM_CHANGED:
			_update()
		NOTIFICATION_TRANSLATION_CHANGED:
			_update()

func _on_sorted() -> void:
	_update()

func _ready() -> void:
	set_notify_transform(true)
	
	var child_control: Control = get_child(0)
	if child_control:
		child_control.top_level = true
