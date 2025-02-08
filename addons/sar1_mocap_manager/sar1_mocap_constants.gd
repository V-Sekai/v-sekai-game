# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# sar1_mocap_constants.gd
# SPDX-License-Identifier: MIT

@tool
class_name MocapConstants

const MOCAP_VERSION = 0
const MOCAP_DIR = "mocap"

const HEADER = "MCP"

const MOCAP_EXT = ".mcp"
const HAND_EXT = ".hnd"
const EXP_EXT = ".exp"

const MAX_INCREMENTAL_FILES = 99999
const INCREMENTAL_DIGET_LENGTH = 5

const TRACKER_POINT_NAMES: Array = ["head", "left_hand", "right_hand", "left_foot", "right_foot", "hips"]
