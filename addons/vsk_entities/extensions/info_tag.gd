# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# info_tag.gd
# SPDX-License-Identifier: MIT

@tool
extends Node3D

@export var nametag_label_nodepath: NodePath = NodePath()
# Remains for backwards compatiblity 2022-12-01 @fire
@export var progress_container_nodepath: NodePath = NodePath()
@export var progress_bar_nodepath: NodePath = NodePath()
@export var progress_label_nodepath: NodePath = NodePath()

@export var nametag: String = "V_SEKAI_PLAYER_NAMETAG_V_SEKAI_PLAYER_NAMETAG_V_SEKAI_PLAYER_NAMETAG_V_SEKAI_PLAYER_NAMETAG_V_SEKAI_PLAYER_NAMETAG_WITH_128_CHAR":
	set = set_nametag


func set_nametag(p_name: String) -> void:
	nametag = p_name
	var nametag_label: Label3D = get_node_or_null(nametag_label_nodepath)
	if nametag_label:
		nametag_label.set_text(nametag)


func show_nametag(p_show_show: bool) -> void:
	var nametag_label: Label3D = get_node_or_null(nametag_label_nodepath)
	if nametag_label:
		if p_show_show:
			nametag_label.show()
		else:
			nametag_label.hide()


func show_progress(p_should_show: bool) -> void:
	var progress_container: Control = get_node_or_null(progress_container_nodepath)
	if progress_container:
		if p_should_show:
			progress_container.show()
		else:
			progress_container.hide()


func _set_progress(p_progress: float) -> void:
	var progress_bar: ProgressBar = get_node_or_null(progress_bar_nodepath)
	if progress_bar:
		progress_bar.value = p_progress


func set_background_load_stage(p_stage: int, p_stage_count: int) -> void:
	var ratio: float = float(p_stage) / float(p_stage_count)

	_set_progress(VSKAssetManager.DOWNLOAD_PROGRESS_BAR_RATIO + (VSKAssetManager.BACKGROUND_LOAD_PROGRESS_BAR_RATIO * ratio))

	var progress_label: Label3D = get_node_or_null(progress_label_nodepath)
	if progress_label:
		progress_label.set_text("%s/%s" % [str(p_stage), str(p_stage_count)])


func set_download_progress(p_downloaded_bytes: int, p_body_size: int) -> void:
	if p_body_size != 0:
		_set_progress((float(p_downloaded_bytes) / float(p_body_size)) * VSKAssetManager.DOWNLOAD_PROGRESS_BAR_RATIO)
	else:
		_set_progress(0.0)

	var progress_label: Label3D = get_node_or_null(progress_label_nodepath)
	if progress_label:
		progress_label.set_text(VSKAssetManager.get_download_progress_string(p_downloaded_bytes, p_body_size))
