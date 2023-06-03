# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_service_manager.gd
# SPDX-License-Identifier: MIT

@tool
extends Node

var services: PackedStringArray = []
var required_host_notify_services: PackedStringArray = []

var loaded_services: Array = []


func setup_configuration() -> void:
	if !ProjectSettings.has_setting("services/services/services"):
		ProjectSettings.set_setting("services/services/services", services)
	else:
		services = ProjectSettings.get_setting("services/services/services")

	if !ProjectSettings.has_setting("services/services/required_host_notify_services"):
		ProjectSettings.set_setting("services/services/required_host_notify_services", required_host_notify_services)
	else:
		required_host_notify_services = ProjectSettings.get_setting("services/services/required_host_notify_services")


func is_required_host_notify_service(p_service: String) -> bool:
	for service in required_host_notify_services:
		if service == p_service:
			return true

	return false


func find_service_by_name(p_name: String) -> RefCounted:
	for service in loaded_services:
		if service.service_get_name() == p_name:
			return service

	return null


func install_services() -> void:
	for service_path in services:
		if ResourceLoader.exists(service_path):
			var required_host_notify: bool = is_required_host_notify_service(service_path)
			var service_script = ResourceLoader.load(service_path)
			var service = service_script.new()
			if service.load_scripts():
				print("Installing service: %s" % service.service_get_name())
				loaded_services.push_back(service)
			else:
				print("Could not install service: %s" % service.service_get_name())
			service.required_host_notify = required_host_notify


func setup_services() -> void:
	if Engine.is_editor_hint():
		for service in loaded_services:
			service.service_setup_editor()
	else:
		for service in loaded_services:
			service.service_setup_game()


func shutdown_services() -> void:
	if Engine.is_editor_hint():
		for service in loaded_services:
			service.service_shutdown_editor()
	else:
		for service in loaded_services:
			service.service_shutdown_game()

	loaded_services = []


func _process(p_delta: float) -> void:
	if Engine.is_editor_hint():
		for service in loaded_services:
			service.service_update_editor(p_delta)
	else:
		for service in loaded_services:
			service.service_update_game(p_delta)


func _exit_tree():
	shutdown_services()


func setup() -> void:
	setup_configuration()

	install_services()
	setup_services()


func _ready():
	set_process(true)
