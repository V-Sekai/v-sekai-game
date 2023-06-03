# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# transform_2d_notification.gd
# SPDX-License-Identifier: MIT

extends Node2D

signal transform_changed


func _notification(p_notification: int) -> void:
	match p_notification:
		NOTIFICATION_TRANSFORM_CHANGED:
			transform_changed.emit()


func _ready() -> void:
	set_notify_transform(true)
