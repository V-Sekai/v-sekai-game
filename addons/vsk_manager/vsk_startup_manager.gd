@tool
extends Node

const vsk_version_const = preload("res://addons/vsk_version/vsk_version.gd")
###########################
# V-Sekai Startup Manager #
###########################

##
## The startup manager is the entrypoint for VSK game-related stuff
##

const commandline_arguments_const = preload("commandline_arguments.gd")
var managers_requiring_preloading: Array = []

# Startup data...
var is_dedicated: bool = false
var is_public: bool = false
var map: String = ""
var game_mode: String = ""
# FIXME: hardcoding constants
var server_name: String = VSKNetworkManager.DEFAULT_SERVER_NAME
var ip: String = ""
var port: int = -1
var max_players: int = VSKNetworkManager.DEFAULT_MAX_PLAYERS
var max_retries: int = VSKNetworkManager.DEFAULT_MAX_RETRIES
var test_audio: String = ""
var headless_flag: bool = false
var display_name_override: String = ""


##
## Returns true if we are running as a headless server
##
func is_headless() -> bool:
	return headless_flag


##
## Called once all the startup function is complete. Sets up the ingame gui,
## then executes a crossfade and yields. After it's complete, it will either
## attempt to host a server if a map commandline argument was provided,
## join a server if an ip commandline argument was provided, or attempt
## to go the main menu
##
func _startup_complate() -> void:
	var _skipped: bool = await VSKFadeManager.execute_fade(false).fade_complete

	if not ip.is_empty():
		await VSKGameFlowManager.join_server(ip, port)
	else:
		if map.is_empty():
			map = VSKMapManager.get_default_map_path()

		if map:
			await VSKGameFlowManager.host_server(server_name, map, game_mode, port, max_players, is_dedicated, is_public, max_retries)
		else:
			VSKGameFlowManager.go_to_title(_skipped)


##
## This method is called by the startup method in order to explictly initalise,
## the other VSK Singletons
##
func setup_vsk_singletons() -> void:
	VSKUserPreferencesManager.setup()
	VSKDebugManager.setup()
	VSKGameFlowManager.setup()
	VSKMenuManager.setup()
	VSKNetworkManager.setup()
	VSKMapManager.setup()
	VSKPlayerManager.setup()
	if not display_name_override.is_empty():
		VSKPlayerManager.display_name = display_name_override
	VSKAssetManager.setup()
	VSKExporter.setup()
	VSKImporter.setup()
	VSKAudioManager.setup()
	VSKAvatarManager.setup()
	VSKServiceManager.setup()
	VSKShardManager.setup()
	VSKPreloadManager.setup()
	VSKFadeManager.setup()
	VSKResourceManager.setup()
	VSKCreditsManager.setup()
	VSKAccountManager.setup()


##
## This method is the entry-point for the gameplay logic, as called by the
## main_scenes root script as part of its _ready method. It first executes a fade,
## then the tells the gameflow manager to go the preload state, then requests
## the resource preloads
##
func startup() -> void:
	assert(VSKVersion != null)  # VSKVersion must be moved up before VSKStartupManager in Autoloads
	print("V-Sekai Build: %s" % vsk_version_const.get_build_label())

	setup_vsk_singletons()

	if !Engine.is_editor_hint():
		#var upnp_result : int = yield(ConnectionMediator.upnp_discover_async(), "completed")
		#print("UPNP_discoery result %s!" % ConnectionMediator.get_string_for_upnp_result(upnp_result))

		assert(VSKPreloadManager.all_preloading_done.connect(self._startup_complate, CONNECT_ONE_SHOT) == OK)

		VSKGameFlowManager.go_to_preloading()
		if !VSKPreloadManager.request_preloading_tasks():
			LogManager.fatal_error("Could not request preloading tasks!")

		var _skipped: bool = await VSKFadeManager.execute_fade(true).fade_complete


##
## This method takes the commandline arguments from the OS, passes them to the
## commandline arg parsing library, then sets the appropriate members in this
## class based on what it has parsed.
##
func parse_commandline_args() -> void:
	var commandline_argument_dictionary: Dictionary = commandline_arguments_const.parse_commandline_arguments(OS.get_cmdline_args())
	display_name_override = ""
	if !Engine.is_editor_hint():
		# Check if we're running in headless mode
		if is_headless():
			VSKGameFlowManager.autoquit = true

		if commandline_argument_dictionary.has("port"):
			if commandline_argument_dictionary["port"][0].is_valid_int():
				port = commandline_argument_dictionary["port"][0].to_int()

		if commandline_argument_dictionary.has("ip"):
			ip = commandline_argument_dictionary["ip"][0]
		if commandline_argument_dictionary.has("display_name"):
			display_name_override = commandline_argument_dictionary["display_name"]
		if commandline_argument_dictionary.has("use_flat"):
			VRManager.vr_user_preferences.vr_mode_override = VRManager.vr_user_preferences.vr_mode_override_enum.VR_MODE_USE_FLAT
		if commandline_argument_dictionary.has("use_vr"):
			VRManager.vr_user_preferences.vr_mode_override = VRManager.vr_user_preferences.vr_mode_override_enum.VR_MODE_USE_VR
		if commandline_argument_dictionary.has("dedicated"):
			is_dedicated = true
		if commandline_argument_dictionary.has("public"):
			is_public = true
		if commandline_argument_dictionary.has("map"):
			map = commandline_argument_dictionary["map"][0]
		if commandline_argument_dictionary.has("game_mode"):
			game_mode = commandline_argument_dictionary["game_mode"][0]

		if commandline_argument_dictionary.has("max_players"):
			if commandline_argument_dictionary["max_players"][0].is_valid_int():
				max_players = commandline_argument_dictionary["max_players"][0].to_int()
		if commandline_argument_dictionary.has("max_retries"):
			if commandline_argument_dictionary["max_retries"][0].is_valid_int():
				max_retries = commandline_argument_dictionary["max_retries"][0].to_int()

		if commandline_argument_dictionary.has("server_name"):
			server_name = commandline_argument_dictionary["server_name"][0]
		if commandline_argument_dictionary.has("test_audio"):
			test_audio = commandline_argument_dictionary["test_audio"][0]
		if commandline_argument_dictionary.has("autoquit"):
			VSKGameFlowManager.autoquit = true

		# Network Latency Simulator
		if commandline_argument_dictionary.has("simulate_network_conditions"):
			NetworkManager.network_flow_manager.simulate_network_conditions = true
		if commandline_argument_dictionary.has("min_latency"):
			NetworkManager.network_flow_manager.min_latency = commandline_argument_dictionary["min_latency"][0]
		if commandline_argument_dictionary.has("max_latency"):
			NetworkManager.network_flow_manager.max_latency = commandline_argument_dictionary["max_latency"][0]
		if commandline_argument_dictionary.has("drop_rate"):
			NetworkManager.network_flow_manager.drop_rate = commandline_argument_dictionary["drop_rate"][0]
		if commandline_argument_dictionary.has("dup_rate"):
			NetworkManager.network_flow_manager.dup_rate = commandline_argument_dictionary["dup_rate"][0]


func apply_project_settings() -> void:
	if Engine.is_editor_hint():
		if ProjectSettings.save() != OK:
			printerr("Could not save project settings!")


func get_project_settings() -> void:
	pass


func _ready() -> void:
	apply_project_settings()
	get_project_settings()


########
# Node #
########


# Startup script...
func _init():
	if !Engine.is_editor_hint():
		if OS.get_name() == "Server":
			headless_flag = true

		parse_commandline_args()

		managers_requiring_preloading = [VSKMenuManager, VSKNetworkManager]
