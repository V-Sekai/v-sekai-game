# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_authentication.gd
# SPDX-License-Identifier: MIT

@tool
extends SarGameSessionAuthentication
class_name VSKGameSessionAuthentication

# Unique 4-byte identifier used during the authentication stage to
# determine that this is a V-Sekai multiplayer game session.
const VSK_IDENTIFIER: String = "VSKG"
# Bump this every time we change something compat breaking with the protocol.
# This should remove the risk of users connecting with out-of-date clients.
const VSK_VERSION: int = 0
