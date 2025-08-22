# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_game_shard_manager.gd
# SPDX-License-Identifier: MIT
@tool

extends Node
class_name VSKGameShardManager

signal public_shards_updated(p_public_server_shards: Array)
signal shard_created(p_shard_id: String, p_shard_data: Dictionary)
signal shard_updated(p_shard_id: String, p_shard_data: Dictionary)
signal shard_deleted(p_shard_id: String)

# Owned shards
var _active_shards: Dictionary = {}
var _active_heartbeat_timers: Dictionary = {}

# Not locally synced with '_active_shards'
var _public_server_shards: Array = []

var shard_heartbeat_frequency: float = 10.0 # Default value, in seconds

func create_shard(p_shard_data: Dictionary) -> Dictionary:
	var service: VSKGameServiceUro = _get_uro_service()
	var result: Dictionary = {}
	if service:
		var current_account_address: String = service.get_current_account_address()
		if current_account_address.is_empty():
			return result
		
		var address_dictionary: Dictionary = GodotUroHelper.get_username_and_domain_from_address(current_account_address)
		var _fetch_request = service.create_request(address_dictionary)
		var async_result: Dictionary = await service.create_shard(_fetch_request, p_shard_data)
		
		if GodotUroHelper.requester_result_is_ok(async_result):
			var shard: Dictionary = async_result["output"]["data"]
			var shard_id: String = async_result["output"]["data"]["id"]
			_active_shards[shard_id] = shard
			if start_timer_update(shard_id) != OK:
				push_error("Heartbeat timer creation failed for shard: %s" % shard_id)
			shard_created.emit(shard_id, shard)
			result = shard
		else:
			push_error(
				(
					"Create shard returned with error %s"
					% GodotUroHelper.get_full_requester_error_string(async_result)
				)
			)
	return result

func update_shard(p_shard_id: String, p_shard_data: Dictionary) -> Dictionary:
	var service: VSKGameServiceUro = _get_uro_service()
	var result: Dictionary = {}
	if service:
		var current_account_address: String = service.get_current_account_address()
		if current_account_address.is_empty():
			return result
		
		var address_dictionary: Dictionary = GodotUroHelper.get_username_and_domain_from_address(current_account_address)
		var _fetch_request = service.create_request(address_dictionary)
		var async_result: Dictionary = await service.update_shard(_fetch_request, p_shard_id, p_shard_data)
		
		if GodotUroHelper.requester_result_is_ok(async_result):
			var shard: Dictionary = async_result["output"]["data"]
			var shard_id: String = async_result["output"]["data"]["id"]
			_active_shards[shard_id] = shard
			shard_updated.emit(shard_id, shard)
			result = shard
		else:
			push_error(
				(
					"Update shard returned with error %s"
					% GodotUroHelper.get_full_requester_error_string(async_result)
				)
			)
	return result

func delete_shard(p_shard_id: String, p_shard_data: Dictionary = {}) -> Dictionary:
	var service: VSKGameServiceUro = _get_uro_service()
	var result: Dictionary = {}
	if service:
		var current_account_address: String = service.get_current_account_address()
		if current_account_address.is_empty():
			return result
		
		var address_dictionary: Dictionary = GodotUroHelper.get_username_and_domain_from_address(current_account_address)
		var _fetch_request = service.create_request(address_dictionary)
		var async_result: Dictionary = await service.delete_shard(_fetch_request, p_shard_id, p_shard_data)
		
		if GodotUroHelper.requester_result_is_ok(async_result):
			var shard: Dictionary = async_result["output"]["data"]
			var shard_id: String = async_result["output"]["data"]["id"]
			if stop_timer_update(shard_id) != OK:
				push_error("Heartbeat timer destruction failed for shard: %s" % p_shard_id)
			_active_shards.erase(shard_id)
			shard_deleted.emit(shard_id)
			result = shard
		else:
			push_error(
				(
					"Delete shard returned with error %s"
					% GodotUroHelper.get_full_requester_error_string(async_result)
				)
			)
	return result

func refresh_shards_list() -> Error:
	var service: VSKGameServiceUro = _get_uro_service()
	var result: Error = FAILED
	if service:
		var current_account_address: String = service.get_current_account_address()
		if current_account_address.is_empty():
			return result
		
		var address_dictionary: Dictionary = GodotUroHelper.get_username_and_domain_from_address(current_account_address)
		var _fetch_request = service.create_request(address_dictionary)
		var async_result: Dictionary = await service.get_public_shards(_fetch_request)
		_fetch_request = null
		
		if GodotUroHelper.requester_result_is_ok(async_result):
			var shards_list: Array = async_result["output"]["data"]["shards"]
			_public_server_shards = shards_list
			public_shards_updated.emit(shards_list)
			result = OK
		else:
			push_error(
				(
					"Get shards returned with error %s"
					% GodotUroHelper.get_full_requester_error_string(async_result)
				)
			)
	return result

func start_timer_update(p_shard_id: String) -> Error:
	var old_timer: Timer = _active_heartbeat_timers.get(p_shard_id, null)
	if not old_timer:
		var callback: Callable = Callable(self, "_shard_heartbeat").bind(p_shard_id)
		var timer: Timer = Timer.new()
		timer.wait_time = shard_heartbeat_frequency
		timer.one_shot = false
		timer.autostart = true
		timer.timeout.connect(callback)
		add_child(timer)

		_active_heartbeat_timers[p_shard_id] = timer
		return OK
	else:
		push_error("Timer already exist for shard: %s" % p_shard_id)
		return ERR_INVALID_PARAMETER

func stop_timer_update(p_shard_id: String) -> Error:
	var timer: Timer = _active_heartbeat_timers.get(p_shard_id, null)
	if timer:
		timer.stop()
		remove_child(timer)
		timer.queue_free()
		_active_heartbeat_timers.erase(p_shard_id)
		return OK
	else:
		push_error("Timer does not exist for shard: %s" % p_shard_id)
		return ERR_INVALID_PARAMETER

func reset_timer_update(p_shard_id: String) -> Error:
	var timer: Timer = _active_heartbeat_timers.get(p_shard_id, null)
	if stop_timer_update(p_shard_id) == OK:
		if start_timer_update(p_shard_id) == OK:
			return OK
	return FAILED

func get_public_server_shards() -> Array:
	return _public_server_shards

func get_public_server_shard_from_id(p_shard_id: String) -> Dictionary:
	var public_shards: Array = get_public_server_shards()
	var result: Dictionary = {}
	for shard in public_shards:
		if (shard.has("id") and shard["id"] == p_shard_id):
			result = shard
			break
	return result

func get_active_shards() -> Dictionary:
	return _active_shards

# Update current player count
func update_shard_current_users(p_shard_id: String, p_current_users: int) -> Dictionary:
	var shard: Dictionary = await update_shard(
		p_shard_id, {"current_users": p_current_users}
	)
	return shard

func _shard_heartbeat(p_shard_id: String) -> void:
	var shard: Dictionary = await update_shard(p_shard_id, {})
	return

func _get_uro_service() -> VSKGameServiceUro:
	var service_manager: VSKGameServiceManager = get_tree().get_first_node_in_group("game_service_managers")
	if service_manager:
		var game_service: VSKGameServiceUro = service_manager.get_service("Uro")
		return game_service
		
	return null

func _process(_delta: float):
	if not Engine.is_editor_hint():
		pass

func _ready():
	if not Engine.is_editor_hint():
		if ProjectSettings.has_setting("game/session/shard_heartbeat_frequency"):
			shard_heartbeat_frequency = ProjectSettings.get_setting("game/session/shard_heartbeat_frequency")

func setup() -> void:
	pass
