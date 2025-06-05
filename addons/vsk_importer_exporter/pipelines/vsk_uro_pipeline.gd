# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_uro_pipeline.gd
# SPDX-License-Identifier: MIT

extends VSKPipeline  # vsk_pipeline.gd
class_name VSKUroPipeline

@export var database_id: String = ""


func _init(p_database_id: String):
	database_id = p_database_id
