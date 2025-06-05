@tool
extends Control

const MIN_X_SCALE = 128.0

func _update() -> void:
	var parent_size: Vector2 = get_parent().size
	if parent_size.x < MIN_X_SCALE:
		scale.x = parent_size.x / MIN_X_SCALE
	else:
		scale.x = 1.0

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
