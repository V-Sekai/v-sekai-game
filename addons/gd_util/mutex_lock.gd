extends RefCounted

var mutex: Mutex = null


func _init(p_mutex: Mutex):
	mutex = p_mutex
	mutex.lock()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PREDELETE:
			mutex.unlock()
