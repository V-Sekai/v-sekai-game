# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_asset_manager.gd
# SPDX-License-Identifier: MIT

@tool
extends SarGameSettingsManager
class_name VSKGameSettingsManager

func _write_custom_config(p_default_cfg: ConfigFile, p_custom_cfg: ConfigFile) -> void:
	super._write_custom_config(p_default_cfg, p_custom_cfg)
