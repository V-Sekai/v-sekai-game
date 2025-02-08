# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# sar1_mocap_recording.gd
# SPDX-License-Identifier: MIT

@tool
class_name MocapRecording extends RefCounted

const mocap_constants_const = preload("sar1_mocap_constants.gd")

## Comically simple interchange binary format for mocap data for recording
## IK. Will likely be made more flexible and efficent in future revisions

##########
## Header #
##########
## 4 Bytes - Ident (MCP0)
## 4 Bytes - Recording FPS

## The rest of the body is an array of frames

##########
## Frame #
##########
## Number of transforms in frame, followed by respective number of transforms
## Usually is: root transform, head, left hand, right hand, left foot, right foot, hips

#############
## Transform #
#############
## 8 Bytes - origin.x
## 8 Bytes - origin.y
## 8 Bytes - origin.z
## 8 Bytes - quat.x
## 8 Bytes - quat.y
## 8 Bytes - quat.z
## 8 Bytes - quat.w

var file: FileAccess
var path: String = ""

var version: int = 0
var fps: int = 0
var frames: Array = []


func _init(p_path: String):
	path = p_path


func open_file_write() -> int:
	file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FAILED
	return OK


func open_file_read() -> int:
	file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return FAILED
	return OK


func close_file() -> void:
	if file:
		file.close()


func set_fps(p_fps: int) -> void:
	fps = p_fps


func set_version(p_version: int) -> void:
	version = p_version


func write_mocap_header() -> void:
	file.store_string(mocap_constants_const.HEADER)
	file.store_8(version)
	file.store_32(fps)


func read_mocap_header() -> bool:
	var buffer: PackedByteArray = file.get_buffer(mocap_constants_const.HEADER.length())
	var header: String = buffer.get_string_from_ascii()
	if header == mocap_constants_const.HEADER:
		version = file.get_8()
		fps = file.get_32()

		return true

	return false


func write_transform(p_transform: Transform3D) -> void:
	var origin: Vector3 = p_transform.origin
	file.store_real(origin.x)
	file.store_real(origin.y)
	file.store_real(origin.z)

	var quat: Quaternion = p_transform.basis.get_rotation_quaternion()
	file.store_real(quat.x)
	file.store_real(quat.y)
	file.store_real(quat.z)
	file.store_real(quat.w)


func write_transform_array(p_transform_array: Array) -> void:
	file.store_32(p_transform_array.size())
	for transform in p_transform_array:
		write_transform(transform)


func read_transform() -> Transform3D:
	var origin: Vector3 = Vector3()
	origin.x = file.get_real()
	origin.y = file.get_real()
	origin.z = file.get_real()

	var quat: Quaternion = Quaternion()
	quat.x = file.get_real()
	quat.y = file.get_real()
	quat.z = file.get_real()
	quat.w = file.get_real()

	return Transform3D(quat, origin)


func read_transform_array() -> Array:
	var count: int = file.get_32()
	var transform_array: Array = []

	for _i in range(0, count):
		var transform: Transform3D = read_transform()
		transform_array.push_back(transform)

	return transform_array


func parse_file() -> bool:
	if file:
		if read_mocap_header():
			frames = []
			while !file.eof_reached():
				var transform_array: Array = read_transform_array()
				frames.push_back(transform_array)
	return false
