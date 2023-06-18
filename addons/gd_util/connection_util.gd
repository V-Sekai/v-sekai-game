# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# connection_util.gd
# SPDX-License-Identifier: MIT

@tool
extends Node


static func connect_signal_table(p_signal_table: Array, p_target: Object) -> void:
	for current_signal in p_signal_table:
		var node: Node = p_target.get_node_or_null(NodePath("/root/%s" % current_signal.singleton))
		if node:
			if node.connect(current_signal["signal"], Callable(p_target, current_signal["method"])) != OK:
				printerr("{singleton}: {signal} could not be connected!".format({"singleton": str(current_signal["singleton"]), "signal": str(current_signal["signal"])}))
		else:
			printerr("{singleton}: {signal} could not be found!".format({"singleton": str(current_signal["singleton"]), "signal": str(current_signal["signal"])}))


static func disconnect_signal_table(p_signal_table: Array, p_target: Object) -> void:
	for current_signal in p_signal_table:
		var node: Node = p_target.get_node_or_null(NodePath("/root/%s" % current_signal.singleton))
		if node:
			if node.is_connected(current_signal["signal"], Callable(p_target, current_signal["method"])):
				node.disconnect(current_signal["signal"], Callable(p_target, current_signal["method"]))
		else:
			printerr("{singleton}: {signal} could not be found!".format({"singleton": str(current_signal["singleton"]), "signal": str(current_signal["signal"])}))
