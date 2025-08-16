# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# godot_request_api.gd
# SPDX-License-Identifier: MIT

@tool
extends RefCounted
class_name GodotRequestAPI

var _godot_request_service: GodotRequestService = null

func cancel(p_requester: GodotRequester) -> void:
	p_requester.cancel()


static func _handle_result(result: RefCounted) -> Dictionary:
	var result_dict: Dictionary = {
		"requester_code": -1, "generic_code": -1, "response_code": -1, "output": {}
	}

	if result:
		result_dict["requester_code"] = result.requester_code
		result_dict["generic_code"] = result.generic_code
		result_dict["response_code"] = result.response_code
		result_dict["response_headers"] = result.response_headers
		result_dict["output"] = result.data

	return result_dict


func _init(p_godot_request_service):
	_godot_request_service = p_godot_request_service
