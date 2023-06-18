# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# sar1_mcp_importer.gd
# SPDX-License-Identifier: MIT

@tool
extends EditorImportPlugin
class_name MCPImporter

const mocap_functions_const = preload("sar1_mocap_functions.gd")
const mocap_constants_const = preload("sar1_mocap_constants.gd")


func _get_importer_name():
	return "mcp_importer"


func _get_import_order() -> int:
	return 0


func _get_visible_name() -> String:
	return "Mocap Data"


func _get_recognized_extensions() -> PackedStringArray:
	return PackedStringArray(["mcp"])


func _get_save_extension() -> String:
	return "scn"


func _get_resource_type() -> String:
	return "PackedScene"


func _get_preset_count() -> int:
	return 1


func _get_preset_name(i) -> String:
	return "Default"


func _get_import_options(option: String, i: int) -> Array:
	return []


func _get_priority() -> float:
	return 1.0


func _import(source_file, save_path, options, platform_variants, gen_files) -> Error:
	var mocap_recording = MocapRecording.new(source_file)
	if mocap_recording.open_file_read() == OK:
		mocap_recording.parse_file()
		mocap_recording.close_file()

		var packed_scene: PackedScene = mocap_functions_const.create_packed_scene_for_mocap_recording(mocap_recording)
		if packed_scene:
			var filename: String = save_path + "." + _get_save_extension()
			ResourceSaver.save(packed_scene, filename)
			return OK
	else:
		printerr("Could not open mocap file for reading")

	return FAILED
