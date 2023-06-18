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
var _loading_thread: Thread = null

signal thread_started
signal thread_ended

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
	return _loading_tasks.is_empty()


func get_loading_active() -> bool:
	var _mutex_lock = mutex_lock_const.new(_loading_tasks_mutex)
	return _loading_active


func set_loading_active(p_bool: bool) -> void:
	var _mutex_lock = mutex_lock_const.new(_loading_tasks_mutex)
	_loading_active = p_bool


func request_loading_task(p_path: String, p_external_path_whitelist: Dictionary, p_type_whitelist: Dictionary, p_type_hint: String = "") -> bool:
	var new_loading_task: LoadingTask = LoadingTask.new(p_type_hint)
	new_loading_task.bypass_whitelist = false
	new_loading_task.external_path_whitelist = p_external_path_whitelist
	new_loading_task.type_whitelist = p_type_whitelist
	return _request_loading_task_internal(p_path, new_loading_task)


func request_loading_task_bypass_whitelist(p_path: String, p_type_hint: String = "") -> bool:
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

	if !_loading_thread.is_started():
		if _loading_active:
			_start_loading_thread()

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
	var loading_tasks: Dictionary = {}

	for key in _loading_tasks.keys():
		loading_tasks[key] = _loading_tasks[key].cancelled

	return loading_tasks


func _task_cancelled(p_task: String) -> void:
	print_debug("background_loader_task_cancelled: {task}".format({"task": str(p_task)}))


func _task_done(p_task: String, p_err: int, p_resource: Resource) -> void:
	print_debug("background_loader_task_done: {task}, error: {err} resource_path: {resource_path}".format({"task": str(p_task), "err": str(p_err), "resource_path": str(p_resource.resource_path) if p_resource else ""}))
	task_done.emit(p_task, p_err, p_resource)


func _task_set_loading_stage(p_task: String, p_stage: int) -> void:
	task_set_stage.emit(p_task, p_stage)


func _task_set_loading_stage_count(p_task: String, p_stage_count: int) -> void:
	task_set_stage_count.emit(p_task, p_stage_count)


func _attempt_to_start_loading_thread() -> void:
	var _mutex_lock = mutex_lock_const.new(_loading_tasks_mutex)
	var loading_tasks: Dictionary = _get_loading_task_paths()
	if loading_tasks.keys().size() > 0:
		if !_loading_thread.is_started():
			_start_loading_thread()


func _threaded_loading_complete() -> void:
	_loading_thread.wait_to_finish()
	print_debug("background_loader_thread_ended (success)")
	thread_ended.emit()

	_attempt_to_start_loading_thread()


func _threaded_loading_method() -> void:
	while get_loading_active() and !is_loading_task_queue_empty():
		var tasks: Dictionary = _get_loading_task_paths()
		if tasks.size() == 0:
			continue

		for task_path in tasks.keys():
			var loading_task: LoadingTask = _loading_tasks[task_path]

			if loading_task.load_path == "":
				if loading_task.bypass_whitelist:
					print("Load " + str(task_path) + " of type " + str(loading_task.type_hint) + " **skip whitelist**")
					ResourceLoader.load_threaded_request(task_path, loading_task.type_hint)
				else:
					print("Load " + str(task_path) + " of type " + str(loading_task.type_hint) + " with " + str(loading_task.external_path_whitelist) + " and " + str(loading_task.type_whitelist))
					ResourceLoader.load_threaded_request_whitelisted(task_path, loading_task.external_path_whitelist, loading_task.type_whitelist, loading_task.type_hint)

				loading_task.load_path = task_path if task_path else ""
				if loading_task.load_path != "":
					Callable(self, "_task_set_loading_stage_count").call_deferred(task_path, 100)
				else:
					Callable(self, "_task_done").call_deferred(task_path, ERR_FILE_UNRECOGNIZED, null)
					_destroy_loading_task(task_path)

			if loading_task.load_path.is_empty():
				continue

			if !tasks[task_path]:
				var err = ResourceLoader.load_threaded_get_status(loading_task.load_path, [])
				if err == ResourceLoader.THREAD_LOAD_LOADED:
					Callable(self, "_task_done").call_deferred(task_path, OK, ResourceLoader.load_threaded_get(loading_task.load_path))
					_destroy_loading_task(task_path)
				elif err != ResourceLoader.THREAD_LOAD_IN_PROGRESS:
					Callable(self, "_task_done").call_deferred(task_path, FAILED, null)
					_destroy_loading_task(task_path)
			else:
				Callable(self, "_task_cancelled").call_deferred(task_path)
				_destroy_loading_task(task_path)

	Callable(self, "_threaded_loading_complete").call_deferred()


func is_quitting() -> void:
	set_loading_active(false)


func _start_loading_thread() -> void:
	print_debug("background_loader_thread_started")
	thread_started.emit()
	var callable: Callable = Callable(self, "_threaded_loading_method")
	var err: int = _loading_thread.start(callable)
	if err != OK:
		printerr("_start_loading_thread (failure)" + str(err))
		thread_ended.emit()


func _ready() -> void:
	_loading_thread = Thread.new()
	set_process(true)
