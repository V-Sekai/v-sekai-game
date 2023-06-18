# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# shard_button.gd
# SPDX-License-Identifier: MIT

extends Button

var address: String
var port: int
var map: String
var server_name: String
var current_users: int
var max_users: int


func _ready():
	$HBoxContainer/NameLabel.set_text("%s - %s" % [server_name, map.get_file()])
	$HBoxContainer/PlayerCountLabel.set_text(str(current_users) + "/" + str(max_users))
