# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# player_info_tag_controller.gd
# SPDX-License-Identifier: MIT

extends Node

var logic_node: Node = null

@export var _player_info_tag_path: NodePath = NodePath()
var _player_info_tag: Node = null

@export var _camera_controller_path: NodePath = NodePath()
var _camera_controller: Node = null

const LOAD_STAGE_DONE = 0
const LOAD_STAGE_DOWNLOADING = 1
const LOAD_STAGE_BACKGROUND_LOADING = 2

# This should be used to talk to the VSKAvatarManager to get information
# for the progress bar
var avatar_url: String = ""

# Callback for what stage an avatar is in.
# LOAD_STAGE_DONE: tells us not to display the progress bar
# LOAD_STAGE_DOWNLOADING: tells us we should check the current download progress
# LOAD_STAGE_BACKGROUND_LOADING: stop checking the download progress and instead
# update based on the load stage callbacks
var load_stage: int = LOAD_STAGE_DONE


func _player_info_tag_visibility_updated() -> void:
	if _player_info_tag:
		if (VSKAvatarManager.show_nametags or load_stage != LOAD_STAGE_DONE) and (!logic_node.is_entity_master() or (_camera_controller.camera_mode == _camera_controller.CAMERA_THIRD_PERSON)):
			_player_info_tag.show()
		else:
			_player_info_tag.hide()

		_player_info_tag.show_nametag(VSKAvatarManager.show_nametags)
		_player_info_tag.show_progress(load_stage != LOAD_STAGE_DONE)


func _player_display_name_updated(p_network_id: int, p_name: String) -> void:
	if p_network_id == get_multiplayer_authority():
		if _player_info_tag:
			_player_info_tag.set_nametag(p_name)

			_player_info_tag_visibility_updated()


func _player_name_changed(p_name: String) -> void:
	_player_display_name_updated(get_multiplayer_authority(), p_name)


func _camera_mode_changed(_camera_mode: int) -> void:
	_player_info_tag_visibility_updated()


func _master_setup() -> void:
	# Nametag
	assert(VSKPlayerManager.display_name_changed.connect(self._player_name_changed) == OK)
	assert(_camera_controller.camera_mode_changed.connect(self._camera_mode_changed) == OK)

	_player_display_name_updated(get_multiplayer_authority(), VSKPlayerManager.display_name)
	###


func _puppet_setup() -> void:
	### Nametag ###
	assert(VSKNetworkManager.player_display_name_updated.connect(self._player_display_name_updated) == OK)

	if VSKNetworkManager.player_display_names.has(get_multiplayer_authority()):
		_player_display_name_updated(get_multiplayer_authority(), VSKNetworkManager.player_display_names[get_multiplayer_authority()])
	###


func setup(p_logic_node: Node) -> void:
	logic_node = p_logic_node

	_player_info_tag = get_node_or_null(_player_info_tag_path)
	_camera_controller = get_node_or_null(_camera_controller_path)

	# State machine
	if !logic_node.is_entity_master():
		_puppet_setup()
	else:
		_master_setup()

	assert(VSKAvatarManager.nametag_visibility_updated.connect(self._player_info_tag_visibility_updated) == OK)


func _update_download_progress() -> void:
	var data_progress: Dictionary = VSKAvatarManager.get_request_data_progress(avatar_url)

	var downloaded_bytes: int = 0
	var body_size: int = 0

	if !data_progress.is_empty():
		downloaded_bytes = data_progress["downloaded_bytes"]
		body_size = data_progress["body_size"]

	_player_info_tag.set_download_progress(downloaded_bytes, body_size)


func _process(_delta):
	if load_stage == LOAD_STAGE_DOWNLOADING:
		_update_download_progress()


func _on_avatar_download_started(p_url: String):
	load_stage = LOAD_STAGE_DOWNLOADING
	avatar_url = p_url

	_update_download_progress()
	_player_info_tag_visibility_updated()

	set_process(true)


func _on_avatar_load_stage(p_stage, p_stage_count):
	if p_stage == p_stage_count:
		load_stage = LOAD_STAGE_DONE
	else:
		load_stage = LOAD_STAGE_BACKGROUND_LOADING

	_player_info_tag.set_background_load_stage(p_stage, p_stage_count)

	_player_info_tag_visibility_updated()

	set_process(false)
