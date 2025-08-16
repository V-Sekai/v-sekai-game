# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# godot_uro_requester.gd
# SPDX-License-Identifier: MIT

@tool
extends GodotRequester
class_name GodotUroRequester

const BOUNDARY_STRING_PREFIX = "UroFileUpload"

const URO_DEFAULT_OPTIONS: Dictionary = {
	"method": HTTPClient.METHOD_GET,
	"encoding": "query",
	"multipart_boundary_prefix": BOUNDARY_STRING_PREFIX,
	"token": null,
	# Legacy Uro server uses "Authorization: Token"
	# Upgrade to "Authorization: Bearer Token"
	# "Bearer" scheme when server switch is done
	"auth_scheme": "",
	"extra_headers": null,
	"download_to": null,
}

func get_default_options() -> Dictionary:
	return URO_DEFAULT_OPTIONS

