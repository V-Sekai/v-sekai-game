# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_manager_plugin.gd
# SPDX-License-Identifier: MIT

@tool
extends EditorPlugin

var editor_interface: EditorInterface = null

var singleton_table = [
	{"singleton_name": "VSKUserPreferencesManager", "singleton_path": "res://addons/vsk_manager/vsk_user_preferences_manager.gd"},
	{"singleton_name": "VSKDebugManager", "singleton_path": "res://addons/vsk_manager/vsk_debug_manager.gd"},
	{"singleton_name": "VSKServiceManager", "singleton_path": "res://addons/vsk_manager/vsk_service_manager.gd"},
	{"singleton_name": "VSKCreditsManager", "singleton_path": "res://addons/vsk_manager/vsk_credits_manager.gd"},
	{"singleton_name": "VSKAccountManager", "singleton_path": "res://addons/vsk_manager/vsk_account_manager.gd"},
	{"singleton_name": "VSKAssetManager", "singleton_path": "res://addons/vsk_manager/vsk_asset_manager.gd"},
	{"singleton_name": "VSKResourceManager", "singleton_path": "res://addons/vsk_manager/vsk_resource_manager.gd"},
	{"singleton_name": "VSKAvatarManager", "singleton_path": "res://addons/vsk_manager/vsk_avatar_manager.gd"},
	{"singleton_name": "VSKMapManager", "singleton_path": "res://addons/vsk_manager/vsk_map_manager.gd"},
	{"singleton_name": "VSKPlayerManager", "singleton_path": "res://addons/vsk_manager/vsk_player_manager.gd"},
	{"singleton_name": "VSKShardManager", "singleton_path": "res://addons/vsk_manager/vsk_shard_manager.gd"},
	{"singleton_name": "VSKGameModeManager", "singleton_path": "res://addons/vsk_manager/vsk_game_mode_manager.gd"},
	{"singleton_name": "VSKMenuManager", "singleton_path": "res://addons/vsk_manager/vsk_menu_manager.gd"},
	{"singleton_name": "VSKNetworkManager", "singleton_path": "res://addons/vsk_manager/vsk_network_manager.gd"},
	{"singleton_name": "VSKGameFlowManager", "singleton_path": "res://addons/vsk_manager/vsk_game_flow_manager.gd"},
	{"singleton_name": "VSKFadeManager", "singleton_path": "res://addons/vsk_manager/vsk_fade_manager.gd"},
	{"singleton_name": "VSKAudioManager", "singleton_path": "res://addons/vsk_manager/vsk_audio_manager.gd"},
	{"singleton_name": "VSKPreloadManager", "singleton_path": "res://addons/vsk_manager/vsk_preload_manager.gd"},
	{"singleton_name": "VSKStartupManager", "singleton_path": "res://addons/vsk_manager/vsk_startup_manager.gd"},
]

var backup_singleton_table_original_order = [{"singleton_name": "VSKUserPreferencesManager", "singleton_path": "res://addons/vsk_manager/vsk_user_preferences_manager.gd"}, {"singleton_name": "VSKDebugManager", "singleton_path": "res://addons/vsk_manager/vsk_debug_manager.gd"}, {"singleton_name": "VSKAudioManager", "singleton_path": "res://addons/vsk_manager/vsk_audio_manager.gd"}, {"singleton_name": "VSKAssetManager", "singleton_path": "res://addons/vsk_manager/vsk_asset_manager.gd"}, {"singleton_name": "VSKAvatarManager", "singleton_path": "res://addons/vsk_manager/vsk_avatar_manager.gd"}, {"singleton_name": "VSKMenuManager", "singleton_path": "res://addons/vsk_manager/vsk_menu_manager.gd"}, {"singleton_name": "VSKNetworkManager", "singleton_path": "res://addons/vsk_manager/vsk_network_manager.gd"}, {"singleton_name": "VSKGameFlowManager", "singleton_path": "res://addons/vsk_manager/vsk_game_flow_manager.gd"}, {"singleton_name": "VSKMapManager", "singleton_path": "res://addons/vsk_manager/vsk_map_manager.gd"}, {"singleton_name": "VSKPlayerManager", "singleton_path": "res://addons/vsk_manager/vsk_player_manager.gd"}, {"singleton_name": "VSKGameModeManager", "singleton_path": "res://addons/vsk_manager/vsk_game_mode_manager.gd"}, {"singleton_name": "VSKStartupManager", "singleton_path": "res://addons/vsk_manager/vsk_startup_manager.gd"}, {"singleton_name": "VSKServiceManager", "singleton_path": "res://addons/vsk_manager/vsk_service_manager.gd"}, {"singleton_name": "VSKShardManager", "singleton_path": "res://addons/vsk_manager/vsk_shard_manager.gd"}, {"singleton_name": "VSKPreloadManager", "singleton_path": "res://addons/vsk_manager/vsk_preload_manager.gd"}, {"singleton_name": "VSKFadeManager", "singleton_path": "res://addons/vsk_manager/vsk_fade_manager.gd"}, {"singleton_name": "VSKResourceManager", "singleton_path": "res://addons/vsk_manager/vsk_resource_manager.gd"}, {"singleton_name": "VSKCreditsManager", "singleton_path": "res://addons/vsk_manager/vsk_credits_manager.gd"}, {"singleton_name": "VSKAccountManager", "singleton_path": "res://addons/vsk_manager/vsk_account_manager.gd"}]


func _init():
	print("Initialising VSKManager plugin")


func _notification(p_notification: int):
	match p_notification:
		NOTIFICATION_PREDELETE:
			print("Destroying VSKManager plugin")


func _get_plugin_name() -> String:
	return "VSKManager"


func _enter_tree() -> void:
	editor_interface = get_editor_interface()

	for singleton in singleton_table:
		add_autoload_singleton(singleton["singleton_name"], singleton["singleton_path"])


func _exit_tree() -> void:
	var sr: Array = singleton_table.duplicate()
	sr.reverse()
	for singleton in sr:
		remove_autoload_singleton(singleton["singleton_name"])
