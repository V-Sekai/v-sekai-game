# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# network_logger.gd
# SPDX-License-Identifier: MIT

@tool
extends Node

var message_printl_func: Callable = Callable()
var message_error_func: Callable = Callable()


func assign_printl_func(p_instance: Object, p_function: String) -> void:
	message_printl_func = Callable(p_instance, p_function)


func assign_error_func(p_instance: Object, p_function: String) -> void:
	message_error_func = Callable(p_instance, p_function)


func printl(p_text) -> void:
	if message_printl_func.is_valid():
		message_printl_func.call("NetworkLogger: %s" % p_text)
	else:
		print(p_text)


func error(p_text) -> void:
	if message_error_func.is_valid():
		message_error_func.call("NetworkLogger: %s" % p_text)
	else:
		push_error(p_text)
