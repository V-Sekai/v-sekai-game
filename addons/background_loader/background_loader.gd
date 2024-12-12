# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# background_loader.gd
# SPDX-License-Identifier: MIT

@tool
extends Node

const mutex_lock_const = preload("res://addons/gd_util/mutex_lock.gd")

var _loading_tasks_mutex: Mutex = Mutex.new()
var _loading_active: bool = true
var _loading_tasks: Dictionary = {}

signal task_set_stage(p_task_name, p_stage)
signal task_set_stage_count(p_task_name, p_stage_count)
signal task_done(p_task_name, p_err, p_resource)


class LoadingTask:
	extends RefCounted
	var load_path: String  # the path is how you request status.
	var type_hint: String
	var bypass_whitelist: bool
	var external_path_whitelist: Dictionary
	var type_whitelist: Dictionary
	var cancelled: bool = false

	func _init(p_type_hint: String):
		type_hint = p_type_hint


func is_loading_task_queue_empty() -> bool:
	var _mutex_lock = mutex_lock_const.new(_loading_tasks_mutex)
	print_verbose("Checking if loading task queue is empty")
	return _loading_tasks.is_empty()


func get_loading_active() -> bool:
	var _mutex_lock = mutex_lock_const.new(_loading_tasks_mutex)
	print_verbose("Getting loading active status")
	return _loading_active


func set_loading_active(p_bool: bool) -> void:
	var _mutex_lock = mutex_lock_const.new(_loading_tasks_mutex)
	print_verbose("Setting loading active status to %s" % [str(p_bool)])
	_loading_active = p_bool


func request_loading_task(p_path: String, p_external_path_whitelist: Dictionary, p_type_whitelist: Dictionary, p_type_hint: String = "") -> bool:
	print_verbose("Requesting loading task for path: %s" % [p_path])
	var new_loading_task: LoadingTask = LoadingTask.new(p_type_hint)
	new_loading_task.bypass_whitelist = false
	new_loading_task.external_path_whitelist = p_external_path_whitelist
	new_loading_task.type_whitelist = p_type_whitelist
	return _request_loading_task_internal(p_path, new_loading_task)


func request_loading_task_bypass_whitelist(p_path: String, p_type_hint: String = "") -> bool:
	print_verbose("Requesting loading task bypass whitelist for path: %s" % [p_path])
	var new_loading_task: LoadingTask = LoadingTask.new(p_type_hint)
	new_loading_task.bypass_whitelist = true
	return _request_loading_task_internal(p_path, new_loading_task)


func _request_loading_task_internal(p_path: String, p_new_loading_task: LoadingTask) -> bool:
	var _mutex_lock = mutex_lock_const.new(_loading_tasks_mutex)

	print_debug("background_load_path_request_loading_task: {path}".format({"path": str(p_path)}))

	if _loading_tasks.has(p_path):
		if _loading_tasks[p_path].cancelled:
			_loading_tasks[p_path].cancelled = false
	else:
		if p_new_loading_task:
			_loading_tasks[p_path] = p_new_loading_task
		else:
			return false

	if _loading_active:
		_start_loading_task(p_path)

	return true


func cancel_loading_task(p_path) -> void:
	var _mutex_lock = mutex_lock_const.new(_loading_tasks_mutex)

	print_debug("background_loader_cancel_loading_task: {path}".format({"path": str(p_path)}))

	if _loading_tasks.has(p_path):
		_loading_tasks[p_path].cancelled = true


# Only call this from loading thread!
func _destroy_loading_task(p_path) -> void:
	var _mutex_lock = mutex_lock_const.new(_loading_tasks_mutex)

	print_debug("background_loader_destroy_loading_task: {path}".format({"path": str(p_path)}))

	if _loading_tasks.has(p_path):
		if not _loading_tasks.erase(p_path):
			push_error("Failed to erase loading task: {path}".format({"path": str(p_path)}))
			return
	else:
		printerr("background_loader_destroy_loading_task: could not destroy loading task {path}".format({"path": str(p_path)}))


func _get_loading_task_paths() -> Dictionary:
	var _mutex_lock = mutex_lock_const.new(_loading_tasks_mutex)
	print_verbose("Getting loading task paths")
	var loading_tasks: Dictionary = {}

	for key in _loading_tasks.keys():
		loading_tasks[key] = _loading_tasks[key].cancelled

	return loading_tasks


func _task_cancelled(p_task: String) -> void:
	print_debug("background_loader_task_cancelled: {task}".format({"task": str(p_task)}))


func _task_done(p_task: String, p_err: int, p_resource: Resource) -> void:
	var resource_path: String
	if p_resource != null:
		resource_path = p_resource.resource_path
	print_debug("background_loader_task_done: %s, error: %s resource_path: %s" % [str(p_task), error_string(p_err), resource_path])
	task_done.emit(p_task, p_err, p_resource)


func _task_set_loading_stage(p_task: String, p_stage: int) -> void:
	task_set_stage.emit(p_task, p_stage)


func _task_set_loading_stage_count(p_task: String, p_stage_count: int) -> void:
	task_set_stage_count.emit(p_task, p_stage_count)


func _start_loading_task(p_path: String) -> void:
	print_debug("background_loader_task_started %s" % p_path)
	_threaded_loading_method(p_path)


func _threaded_loading_method(_p_path: String) -> void:
	while get_loading_active() and !is_loading_task_queue_empty():
		var tasks: Dictionary = _get_loading_task_paths()
		if tasks.is_empty():
			continue

		for task_path in tasks.keys():
			var loading_task: LoadingTask = _loading_tasks[task_path]

			if !ResourceLoader.has_method("load_threaded_request_whitelisted"):
				print("Warning: load_threaded_request_whitelisted is not available in this build. All loading will bypass the whitelist.")
			loading_task.bypass_whitelist = true

			if loading_task.load_path.is_empty():
				if loading_task.bypass_whitelist:
					print("Load " + str(task_path) + " of type " + str(loading_task.type_hint) + " **skip whitelist**")
					ResourceLoader.call("load_threaded_request", task_path, loading_task.type_hint)
				else:
					print("Load " + str(task_path) + " of type " + str(loading_task.type_hint) + " with " + str(loading_task.external_path_whitelist) + " and " + str(loading_task.type_whitelist))
					ResourceLoader.call("load_threaded_request_whitelisted", task_path, loading_task.external_path_whitelist, loading_task.type_whitelist, loading_task.type_hint)

				loading_task.load_path = task_path if task_path else ""
				if !loading_task.load_path.is_empty():
					Callable(self, "_task_set_loading_stage_count").call_deferred(task_path, 100)
				else:
					print_stack()
					Callable(self, "_task_done").call_deferred(task_path, ERR_FILE_UNRECOGNIZED, null)
					_destroy_loading_task(task_path)

			if loading_task.load_path.is_empty():
				continue

			if tasks[task_path]:
				Callable(self, "_task_cancelled").call_deferred(task_path)
				_destroy_loading_task(task_path)
			else:
				var err = ResourceLoader.load_threaded_get_status(loading_task.load_path, [])
				match err:
					ResourceLoader.THREAD_LOAD_LOADED:
						var resource = ResourceLoader.load_threaded_get(loading_task.load_path)
						if resource:
							print_debug("Successfully loaded resource: %s" % loading_task.load_path)
							Callable(self, "_task_done").call_deferred(task_path, OK, resource)
						else:
							print_stack()
							printerr("Failed to get loaded resource: %s" % loading_task.load_path)
							Callable(self, "_task_done").call_deferred(task_path, FAILED, null)
						_destroy_loading_task(task_path)
					ResourceLoader.THREAD_LOAD_IN_PROGRESS:
						pass
					ResourceLoader.THREAD_LOAD_FAILED:
						if err == ERR_UNAVAILABLE:
							var resource = ResourceLoader.load_threaded_get(loading_task.load_path)
							Callable(self, "_task_done").call_deferred(task_path, OK, resource)
							break
						print_stack()
						printerr("Failed to load resource: %s, error: %s" % [loading_task.load_path, error_string(err)])
						Callable(self, "_task_done").call_deferred(task_path, FAILED, null)
						_destroy_loading_task(task_path)
					ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
						print_stack()
						printerr("Invalid resource: %s" % loading_task.load_path)
						Callable(self, "_task_done").call_deferred(task_path, ERR_FILE_UNRECOGNIZED, null)
						_destroy_loading_task(task_path)


func is_quitting() -> void:
	print_verbose("Setting loading active to false (quitting)")
	set_loading_active(false)


func _ready() -> void:
	print_verbose("Background loader ready")
	set_process(true)
