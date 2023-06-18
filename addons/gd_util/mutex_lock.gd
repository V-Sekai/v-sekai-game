# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# mutex_lock.gd
# SPDX-License-Identifier: MIT

extends RefCounted

var mutex: Mutex = null


func _init(p_mutex: Mutex):
	mutex = p_mutex
	mutex.lock()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PREDELETE:
			mutex.unlock()
