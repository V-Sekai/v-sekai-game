# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# loading_screen.gd
# SPDX-License-Identifier: MIT

extends "res://addons/vsk_menu/menu_view_controller.gd"  # menu_view_controller.gd

@export var progress_bar_path: NodePath = NodePath()
var progress_bar: ProgressBar = null

@export var loading_status_label_path: NodePath = NodePath()
var loading_status_label: Label = null

@export var peer_list_tree_path: NodePath = NodePath()
var peer_list_tree: Tree = null


class StateTypes:
	const NONE = 0
	const REGISTERING_SHARD = 1
	const EXCHANGING_SERVER_INFO = 2
	const EXCHANGING_SERVER_STATE = 3
	const NETWORK_DOWNLOAD = 4
	const RESOURCE_LOAD = 5
	const COMPLETE = 6


var state: int = StateTypes.NONE

var previous_data_progress: Dictionary = {}
var data_progress: Dictionary = {}


func _map_load_update(p_stage: int, p_stage_count: int) -> void:
	state = StateTypes.RESOURCE_LOAD

	if p_stage_count > 0:
		set_progress(VSKAssetManager.DOWNLOAD_PROGRESS_BAR_RATIO + (VSKAssetManager.BACKGROUND_LOAD_PROGRESS_BAR_RATIO * (float(p_stage) / float(p_stage_count))))
		set_loading_status("{loading_asset}: {stage}/{stage_count}".format({"loading_asset": tr("TR_MENU_LOADING_ASSET"), "stage": str(p_stage), "stage_count": str(p_stage_count)}))
	else:
		set_progress(0.0)
		set_loading_status("{loading_asset}: ERROR".format({"loading_asset": tr("TR_MENU_LOADING_ASSET")}))


func _map_load_callback(_callback: int, _callback_dictionary: Dictionary) -> void:
	pass


func _map_download_started() -> void:
	state = StateTypes.NETWORK_DOWNLOAD


func _registering_shard() -> void:
	state = StateTypes.REGISTERING_SHARD
	set_progress(0.0)
	loading_status_label.set_text(tr("TR_MENU_REGISTERING_SERVER"))


func _host_creating_server_info() -> void:
	state = StateTypes.EXCHANGING_SERVER_INFO
	set_progress(0.0)
	loading_status_label.set_text(tr("TR_MENU_CREATING_SERVER_INFO"))


func _host_creating_server_state() -> void:
	state = StateTypes.EXCHANGING_SERVER_STATE
	set_progress(0.0)
	loading_status_label.set_text(tr("TR_MENU_CREATING_SERVER_STATE"))


func _requesting_server_info() -> void:
	state = StateTypes.EXCHANGING_SERVER_INFO
	set_progress(0.0)
	loading_status_label.set_text(tr("TR_MENU_REQUESTING_SERVER_INFO"))


func _requesting_server_state() -> void:
	state = StateTypes.EXCHANGING_SERVER_STATE
	set_progress(0.0)
	loading_status_label.set_text(tr("TR_MENU_REQUESTING_SERVER_STATE"))


func _server_state_ready() -> void:
	state = StateTypes.COMPLETE
	set_progress(1.0)
	loading_status_label.set_text(tr("TR_MENU_SERVER_STATE_READY"))


func will_appear() -> void:
	if VSKMapManager.map_load_update.connect(self._map_load_update) != OK:
		printerr("Could not connect map_load_update!")

	if VSKMapManager.map_load_callback.connect(self._map_load_callback) != OK:
		printerr("Could not connect map_load_callback!")

	if VSKMapManager.map_download_started.connect(self._map_download_started) != OK:
		printerr("Could not connect map_download_started!")

	if VSKNetworkManager.registering_shard.connect(self._registering_shard) != OK:
		printerr("Could not connect registering_shard!")

	if VSKNetworkManager.requesting_server_info.connect(self._requesting_server_info) != OK:
		printerr("Could not connect requesting_server_info")

	if VSKNetworkManager.requesting_server_state.connect(self._requesting_server_state) != OK:
		printerr("Could not connect requesting_server_state")

	if VSKNetworkManager.host_creating_server_info.connect(self._host_creating_server_info) != OK:
		printerr("Could not connect host_creating_server_info")

	if VSKNetworkManager.host_creating_server_state.connect(self._host_creating_server_state) != OK:
		printerr("Could not connect host_creating_server_state")

	if VSKNetworkManager.server_state_ready.connect(self._server_state_ready) != OK:
		printerr("Could not connect server_state_ready")


func will_disappear() -> void:
	if VSKMapManager.map_load_update.is_connected(self._map_load_update):
		VSKMapManager.map_load_update.disconnect(self._map_load_update)

	if VSKMapManager.map_load_callback.is_connected(self._map_load_callback):
		VSKMapManager.map_load_callback.disconnect(self._map_load_callback)

	if VSKMapManager.map_download_started.is_connected(self._map_download_started):
		VSKMapManager.map_download_started.disconnect(self._map_download_started)

	if VSKNetworkManager.registering_shard.is_connected(self._registering_shard):
		VSKNetworkManager.registering_shard.disconnect(self._registering_shard)

	if VSKNetworkManager.is_connected("requesting_server_info", Callable(self, "_requesting_server_info")):
		VSKNetworkManager.disconnect("requesting_server_info", Callable(self, "_requesting_server_info"))

	if VSKNetworkManager.is_connected("requesting_server_state", Callable(self, "_requesting_server_state")):
		VSKNetworkManager.disconnect("requesting_server_state", Callable(self, "_requesting_server_state"))

	if VSKNetworkManager.is_connected("host_creating_server_info", Callable(self, "_host_creating_server_info")):
		VSKNetworkManager.disconnect("host_creating_server_info", Callable(self, "_host_creating_server_info"))

	if VSKNetworkManager.is_connected("host_creating_server_state", Callable(self, "_host_creating_server_state")):
		VSKNetworkManager.disconnect("host_creating_server_state", Callable(self, "_host_creating_server_state"))

	if VSKNetworkManager.is_connected("server_state_ready", Callable(self, "_server_state_ready")):
		VSKNetworkManager.disconnect("server_state_ready", Callable(self, "_server_state_ready"))


func set_progress(p_progress: float) -> void:
	if progress_bar:
		var value: float = lerp(progress_bar.min_value, progress_bar.max_value, p_progress)
		progress_bar.set_value(value)


func set_loading_status(p_status_message: String) -> void:
	if loading_status_label:
		loading_status_label.set_text(p_status_message)


func peer_list_changed() -> void:
	if !NetworkManager.has_active_peer():
		peer_list_tree.clear()
		return

	var players = NetworkManager.get_peer_list()

	if peer_list_tree:
		peer_list_tree.clear()
		var root = peer_list_tree.create_item()
		peer_list_tree.set_hide_root(true)

		var myself = peer_list_tree.create_item(root)

		myself.set_text(0, "{peer}_{current_peer_id} (me)".format({"peer": tr("TR_MENU_PEER"), "current_peer_id": str(NetworkManager.get_current_peer_id())}))

		for peer_id in players:
			var child = peer_list_tree.create_item(root)
			child.set_text(0, "Peer_{peer_id}".format({"peer_id": str(peer_id)}))


func _on_Disconnect_pressed() -> void:
	VSKGameFlowManager.cancel_map_load()
	var skipped: bool = await VSKFadeManager.execute_fade(false).fade_complete
	await VSKGameFlowManager.go_to_title(skipped)


func _update_data_progress() -> void:
	previous_data_progress = data_progress
	data_progress = VSKMapManager.get_request_data_progress()

	if previous_data_progress.is_empty():
		previous_data_progress = VSKMapManager.get_request_data_progress()

	var downloaded_bytes: int = 0
	var body_size: int = 0

	if !data_progress.is_empty():
		downloaded_bytes = data_progress["downloaded_bytes"]
		body_size = data_progress["body_size"]

	var download_progress_string: String = VSKAssetManager.get_download_progress_string(downloaded_bytes, body_size)

	if body_size != 0:
		set_progress((float(downloaded_bytes) / float(body_size)) * VSKAssetManager.DOWNLOAD_PROGRESS_BAR_RATIO)
	else:
		set_progress(0.0)

	set_loading_status("{downloading_map}: {download_progress_string}".format({"downloading_map": tr("TR_MENU_DOWNLOADING_MAP"), "download_progress_string": download_progress_string}))


func _process(_delta: float) -> void:
	if state == StateTypes.NETWORK_DOWNLOAD:
		_update_data_progress()


func _ready() -> void:
	if has_node(progress_bar_path):
		progress_bar = get_node(progress_bar_path)

	if has_node(loading_status_label_path):
		loading_status_label = get_node(loading_status_label_path)

	if has_node(peer_list_tree_path):
		peer_list_tree = get_node(peer_list_tree_path)
