# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# godot_vroid_helper.gd
# SPDX-License-Identifier: MIT

@tool
extends GodotRequestHelper
class_name GodotVroidHelper

###

# enum VroidUserContentType { UNKNOWN, AVATAR }

const ROOT_PATH: String = "hub.vroid.com"
const API_VERSION: String = "11"
const API_PATH: String = "/api"
const PROFILE_PATH: String = "/account"
const UPLOADED_MODELS_PATH: String = "/account/character_models"
const MODEL_PATH: String = "/character_models" # character_models/{id}
const SEARCH_PATH: String = "/search/character_models"
const HEARTS_PATH: String = "/hearts"
const DOWNLOAD_LICENSE_PATH = "/download_licenses"
const STAFF_PICKS_PATH: String = "/staff_picks"
const DEFAULT_ACCOUNT_ID: String = "UNKNOWN_ID"
const DEFAULT_ACCOUNT_USERNAME: String = "UNKNOWN_USERNAME"

# Vroid Hub API App settings can override these filters
# to enforce Developer standards of use
# "disallow" is the least restricted filter
# "everyone" == avatar use allowed

const DEFAULT_MODEL_FILTER: Dictionary = {
	"is_downloadable": true,
	"characterization_allowed_user": "everyone",
	"violent_expression": "disallow",
	"sexual_expression": "disallow",
	"political_or_religious_usage": "disallow",
	"antisocial_or_hate_usage": "disallow",
	"modification": "disallow",
	"redistribution": "disallow",
	"credit": "default",
	"has_booth_items": false,
	"booth_part_categories": [],
	# These should be configured in Vroid Hub App console
	# It seems they are mutually exclusive?
	"corporate_commercial_use": "default",
	"personal_commercial_use": "default"
}

static func get_api_path() -> String:
	return "https://" + ROOT_PATH + API_PATH

static func get_api_header() -> String:
	return "X-Api-Version: " + API_VERSION

static func get_default_model_filter() -> Dictionary:
	return DEFAULT_MODEL_FILTER.duplicate(true)

static func get_domain() -> String:
	return ROOT_PATH

static func interpolate_default_model_filter(p_filter) -> Dictionary:
	var result : Dictionary = get_default_model_filter()

	if p_filter and not p_filter.is_empty():
		for key in result.keys():
			if p_filter.has(key):
				result[key] = p_filter[key]
	return result
