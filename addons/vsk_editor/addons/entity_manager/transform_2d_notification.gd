extends Node2D

signal transform_changed


func _notification(p_notification: int) -> void:
	match p_notification:
		NOTIFICATION_TRANSFORM_CHANGED:
			transform_changed.emit()


func _ready() -> void:
	set_notify_transform(true)
