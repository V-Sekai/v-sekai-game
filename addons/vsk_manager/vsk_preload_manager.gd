# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_preload_manager.gd
# SPDX-License-Identifier: MIT

extends Node

## V-Sekai Preload Manager

##
## The preload manager is class responsible for handling resources which need
## to be loaded at startup.
##

var managers_requiring_preloading: Array = [VSKMenuManager, VSKNetworkManager]

signal all_preloading_done

##
## This flag is set if preloading encountered a problem
##
var preloading_failed_flag: bool = false
##
## This contains all the active preloading tasks
##
var preloading_tasks: Dictionary = {}


##
## Called once all the preloading tasks are complete. Disconnects the
## BackgroundLoader signals, disables processing, and then emits the
## all_preloading_done_signal.
##
func _all_preloading_done() -> void:
	BackgroundLoader.task_done.disconnect(self._preloading_task_done)

	set_process(false)

	all_preloading_done.emit()


##
## Called to request the next preloading task to be run
##
func _next_preloading_task() -> void:
	if preloading_tasks.size() > 0:
		if BackgroundLoader.request_loading_task_bypass_whitelist(preloading_tasks.keys()[0]) == false:
			push_error("request_loading_task failed!")
	else:
		push_error("Preloading task queue underflow!")


##
## Called to set a flag if something went wrong during the preloading stage.
##
func _preloading_failed() -> void:
	preloading_failed_flag = true


##
## This method is called once a preloading task is completed with the
## task_done signal being emitted from the BackgroundLoader. It will call
## the method on the target objects contained within the task.
## p_task is the name of the task which was finished.
## p_err is the response code.
## p_resource is the resource which was loaded by this task.
##
func _preloading_task_done(p_task: String, p_err: int, p_resource: Resource) -> void:
	if p_err != OK:
		printerr("_preloading_task_done: task '{task}' failed with the error code '{error}'!".format({"task": p_task, "error": str(p_err)}))
		_preloading_failed()
		return
	if preloading_tasks.has(p_task):
		var callback_array: Array = preloading_tasks[p_task]
		if callback_array.is_empty():
			printerr("_preloading_task_done: no callback data for task '%s'!" % p_task)
			_preloading_failed()
			return

		for callback in callback_array:
			if callback:
				if !callback.has("target"):
					printerr("_preloading_task_done: no target data for task '%s'!" % p_task)
					_preloading_failed()
					return
				if !callback.has("method"):
					printerr("_preloading_task_done: no method data for task '%s'!" % p_task)
					_preloading_failed()
					return
				if !callback.has("args"):
					printerr("_preloading_task_done: no args data for task '%s'!" % p_task)
					_preloading_failed()
					return

				var target: Object = callback.target
				if target:
					var method: String = callback.method
					var args: Array = callback.args

					if target.has_method(method):
						target.callv(method, [p_resource] + args)
					else:
						_preloading_failed()
						printerr("_preloading_task_done: no valid method for task '%s'!" % p_task)
						return
			else:
				_preloading_failed()
				printerr("_preloading_task_done: no callback data for task '%s'!" % p_task)
				return
		if not preloading_tasks.erase(p_task):
			printerr("_preloading_task_done: failed to erase task '%s'!" % p_task)
			_preloading_failed()
			return
	else:
		_preloading_failed()
		printerr("_preloading_task_done: invalid task '%s'!" % p_task)
		return

	if preloading_tasks.is_empty():
		_all_preloading_done()
	else:
		_next_preloading_task()


##
## This method is called by request_preloading_tasks, and dispatches the task to
## the BackgroundLoader.
## p_task is the name of the task
## p_callback_target is the object the callback method should be called on.
## p_callback_method is the name of the method which should be called up completion.
## p_callback_arguments is an array of arguments which should be called with the method.
##
func _request_preloading_task(p_task: String, p_callback_target: Object, p_callback_method: String, p_callback_arguments: Array) -> void:
	if !preloading_tasks.has(p_task):
		preloading_tasks[p_task] = []

	preloading_tasks[p_task].push_back({"target": p_callback_target, "method": p_callback_method, "args": p_callback_arguments})


##
## This method is called by the startup function and polls various VSK subsystems
## for dictionaries containing preloading tasks. It then calls _request_preloading_task
## which then dispatches them to the background loader. Once all the preloading is done
## calls _all_preloading_done.
## Returns false is a BackgroundLoader signal failed to connect, otherwise returns true
##
func request_preloading_tasks() -> bool:
	set_process(true)

	if BackgroundLoader.task_done.connect(self._preloading_task_done) != OK:
		return false

	for manager in managers_requiring_preloading:
		# Place preloading tasks here!
		var manager_preload_tasks: Dictionary = manager.get_preload_tasks()
		for task in manager_preload_tasks.keys():
			_request_preloading_task(task, manager_preload_tasks[task]["target"], manager_preload_tasks[task].method, manager_preload_tasks[task]["args"])
	if preloading_tasks.is_empty():
		_all_preloading_done()
	else:
		_next_preloading_task()

	return true


func _process(_delta: float) -> void:
	if preloading_failed_flag:
		push_error("preloading failure flag triggered!")
		return


func setup() -> void:
	pass
