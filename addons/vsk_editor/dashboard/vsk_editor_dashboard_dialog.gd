# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_editor_dashboard_dialog.gd
# SPDX-License-Identifier: MIT

@tool
extends VSKEditorDialog
class_name VSKEditorDashboardDialog

signal session_request_successful

var _toolbar_container: VSKEditorUroToolbarContainer = null

func _ready() -> void:
	super._ready()

###

@export var dashboard_dialog_control: VSKEditorDashboardDialogControl = null

func setup(p_toolbar_container: VSKEditorUroToolbarContainer) -> void:
	_toolbar_container = p_toolbar_container
	dashboard_dialog_control.setup(_toolbar_container)
