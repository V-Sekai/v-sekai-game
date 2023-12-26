# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_startup_manager.gd
# SPDX-License-Identifier: MIT

@tool
extends Node

const vsk_version_const = preload("res://addons/vsk_version/vsk_version.gd")
const commandline_arguments_const = preload("commandline_arguments.gd")

var default_autohost = false

var is_dedicated = false
var is_public = false
var map = ""
var game_mode = ""

var server_name = VSKMultiplayerManager.DEFAULT_SERVER_NAME
var ip = ""
var port = -1
var max_players = VSKMultiplayerManager.DEFAULT_MAX_PLAYERS
var max_retries = VSKMultiplayerManager.DEFAULT_MAX_RETRIES
var test_audio = ""
var display_name_override = ""


func _startup_complete() -> void:
	await VSKPreloadManager.all_preloading_done

	if !ip.is_empty():
		await VSKGameFlowManager.join_server(ip, port)
	else:
		if map.is_empty() and default_autohost:
			map = VSKMapManager.get_default_map_path()

		if !map.is_empty():
			await VSKGameFlowManager.host_server(server_name, map, game_mode, port, max_players, is_dedicated, is_public, max_retries)
		else:
			var skipped_fade: bool = await VSKFadeManager.execute_fade(VSKFadeManager.FadeState.FADE_OUT).fade_complete
			VSKGameFlowManager.go_to_title(skipped_fade)


func setup_vsk_singletons() -> void:
	for singleton in [VSKUserPreferencesManager, VSKDebugManager, VSKGameFlowManager, VSKMenuManager, VSKNetworkManager, VSKMapManager, VSKMultiplayerManager, VSKPlayerManager, VSKAssetManager, VSKExporter, VSKImporter, VSKAudioManager, VSKAvatarManager, VSKServiceManager, VSKShardManager, VSKPreloadManager, VSKFadeManager, VSKResourceManager, VSKCreditsManager, VSKAccountManager]:
		singleton.setup()

	if !display_name_override.is_empty():
		VSKPlayerManager.display_name = display_name_override


func startup() -> void:
	if VSKVersion == null:
		printerr("VSKVersion must be moved up before VSKStartupManager in Autoloads")
		return

	print("V-Sekai Build: %s" % vsk_version_const.get_build_label())


func flow_preload() -> void:
	VSKGameFlowManager.go_to_preloading()
	if !VSKPreloadManager.request_preloading_tasks():
		printerr("Could not request preloading tasks!")


func execute_fade() -> void:
	await VSKFadeManager.execute_fade(VSKFadeManager.FadeState.FADE_IN).fade_complete


func parse_commandline_args() -> void:
	var commandline_argument_dictionary = commandline_arguments_const.parse_commandline_arguments(OS.get_cmdline_args())
	display_name_override = ""
	if Engine.is_editor_hint():
		return

	if !DisplayServer.window_can_draw():
		VSKGameFlowManager.autoquit = true

	if commandline_argument_dictionary.has("port"):
		port = commandline_argument_dictionary["port"][0].to_int()

	if commandline_argument_dictionary.has("ip"):
		ip = commandline_argument_dictionary["ip"][0]

	if commandline_argument_dictionary.has("display_name"):
		display_name_override = commandline_argument_dictionary["display_name"]

	if commandline_argument_dictionary.has("use_flat"):
		VRManager.vr_user_preferences.vr_mode_override = VRManager.vr_user_preferences.vr_mode_override_enum.VR_MODE_USE_FLAT

	if commandline_argument_dictionary.has("use_vr"):
		VRManager.vr_user_preferences.vr_mode_override = VRManager.vr_user_preferences.vr_mode_override_enum.VR_MODE_USE_VR

	is_dedicated = commandline_argument_dictionary.has("dedicated")
	is_public = commandline_argument_dictionary.has("public")

	if commandline_argument_dictionary.has("map"):
		map = commandline_argument_dictionary["map"]

	if commandline_argument_dictionary.has("game_mode"):
		game_mode = commandline_argument_dictionary["game_mode"]

	if commandline_argument_dictionary.has("max_players"):
		max_players = commandline_argument_dictionary["max_players"][0].to_int()

	if commandline_argument_dictionary.has("max_retries"):
		max_retries = commandline_argument_dictionary["max_retries"][0].to_int()

	if commandline_argument_dictionary.has("server_name"):
		server_name = commandline_argument_dictionary["server_name"][0]

	if commandline_argument_dictionary.has("test_audio"):
		test_audio = commandline_argument_dictionary["test_audio"][0]


func apply_project_settings() -> void:
	if Engine.is_editor_hint():
		if !ProjectSettings.has_setting("network/config/default_autohost"):
			ProjectSettings.set_setting("network/config/default_autohost", default_autohost)

		if ProjectSettings.save() != OK:
			printerr("Could not save project settings!")


func get_project_settings() -> void:
	default_autohost = ProjectSettings.get_setting("network/config/default_autohost")


func _ready() -> void:
	apply_project_settings()
	get_project_settings()


func _init():
	if Engine.is_editor_hint():
		return

	parse_commandline_args()
