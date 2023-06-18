# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_map_entity_instance_record.gd
# SPDX-License-Identifier: MIT

extends Resource
class_name VSKMapEntityInstanceRecord

@export var parent_id: int = -1
@export var scene_id: int = -1
@export var properties_id: int = -1
@export var transform: Transform3D = Transform3D()
