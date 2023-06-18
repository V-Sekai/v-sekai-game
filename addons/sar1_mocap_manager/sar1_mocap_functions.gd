# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# sar1_mocap_functions.gd
# SPDX-License-Identifier: MIT

@tool
class_name MocapFunctions

const mocap_constants_const = preload("sar1_mocap_constants.gd")


static func _get_mocap_path_and_prefix(p_mocap_directory: String) -> String:
	return "%s/mocap_" % p_mocap_directory


static func _incremental_mocap_file_path(p_info: Dictionary) -> Dictionary:
	var err: int = OK
	var path: String = ""

	var mocap_directory: String = p_info["mocap_directory"]

	var mocap_number: int = 0
	var mocap_path_and_prefix: String = _get_mocap_path_and_prefix(mocap_directory)
	var file: FileAccess = FileAccess.open(mocap_path_and_prefix + str(mocap_number).pad_zeros(mocap_constants_const.INCREMENTAL_DIGET_LENGTH) + mocap_constants_const.MOCAP_EXT, FileAccess.READ)
	while file:
		mocap_number += 1
		file = (FileAccess.open(mocap_path_and_prefix + str(mocap_number).pad_zeros(mocap_constants_const.INCREMENTAL_DIGET_LENGTH) + mocap_constants_const.MOCAP_EXT, FileAccess.READ))

	if mocap_number <= mocap_constants_const.MAX_INCREMENTAL_FILES:
		path = (mocap_path_and_prefix + str(mocap_number).pad_zeros(mocap_constants_const.INCREMENTAL_DIGET_LENGTH) + mocap_constants_const.MOCAP_EXT)
	else:
		err = FAILED

	return {"error": err, "path": path}


static func create_scene_for_mocap_recording(p_mocap_recording: MocapRecording) -> Node3D:
	var mocap_scene: Node3D = Node3D.new()
	mocap_scene.set_name("MocapScene")

	# Setup animation player
	var animation_player: AnimationPlayer = AnimationPlayer.new()
	animation_player.set_name("AnimationPlayer")
	mocap_scene.add_child(animation_player, true)
	animation_player.set_owner(mocap_scene)

	# Setup animation root
	var root: Node3D = Node3D.new()
	root.set_name("Root")
	mocap_scene.add_child(root, true)
	root.set_owner(mocap_scene)

	animation_player.root_node = animation_player.get_path_to(root)

	# Setup animation
	var animation: Animation = Animation.new()
	if animation_player.has_animation_library(""):
		var animation_library: AnimationLibrary = animation_player.get_animation_library("")
		animation_library.add_animation("MocapAnimation", animation)
	else:
		var animation_library: AnimationLibrary = AnimationLibrary.new()
		animation_library.add_animation("MocapAnimation", animation)
		animation_player.add_animation_library("", animation_library)

	animation.set_name("MocapAnimation")
	var root_track_id_position: int = animation.add_track(Animation.TYPE_POSITION_3D)
	var root_track_id_rotation: int = animation.add_track(Animation.TYPE_ROTATION_3D)
	#var root_track_id_scale: int = animation.add_track(Animation.TYPE_SCALE_3D)
	animation.track_set_path(root_track_id_position, root.get_path_to(root))
	animation.track_set_path(root_track_id_rotation, root.get_path_to(root))
	#animation.track_set_path(root_track_id_scale, root.get_path_to(root))

	# Add tracks for tracker data
	for tracker_point_name in mocap_constants_const.TRACKER_POINT_NAMES:
		var tracker: Marker3D = Marker3D.new()
		tracker.set_name(tracker_point_name)
		root.add_child(tracker, true)
		tracker.set_owner(mocap_scene)

		var track_id_position: int = animation.add_track(Animation.TYPE_POSITION_3D)
		var track_id_rotation: int = animation.add_track(Animation.TYPE_ROTATION_3D)
		#var track_id_scale: int = animation.add_track(Animation.TYPE_SCALE_3D)
		animation.track_set_path(track_id_position, root.get_path_to(tracker))
		animation.track_set_path(track_id_rotation, root.get_path_to(tracker))
		#animation.track_set_path(track_id_scale, root.get_path_to(tracker))

	# Setup timestep based on mocap data's FPS
	var timestep: float = 1.0 / p_mocap_recording.fps
	var current_time: float = 0.0

	animation.step = timestep

	# Write the mocap data to the animation file
	for frame in p_mocap_recording.frames:
		var current_idx: int = 0

		for transform in frame:
			if current_idx < animation.get_track_count():
				var _pos_key_idx: int = animation.position_track_insert_key(current_idx, current_time, transform.origin)
				current_idx += 1
				# Error
				var quat: Quaternion = transform.basis.orthonormalized().get_rotation_quaternion()
				var _rot_key_idx: int = animation.rotation_track_insert_key(current_idx, current_time, quat)
				#current_idx += 1
				#var _sca_key_idx: int = animation.scale_track_insert_key(current_idx, current_time, Vector3(1.0, 1.0, 1.0))
				current_idx += 1
			else:
				printerr("Animation mocap data track mismatch")

		current_time += timestep

	animation.length = current_time

	return mocap_scene


static func create_packed_scene_for_mocap_recording(p_mocap_recording: MocapRecording) -> PackedScene:
	var mocap_scene: Node3D = create_scene_for_mocap_recording(p_mocap_recording)
	if mocap_scene:
		var packed_scene: PackedScene = PackedScene.new()
		var result: int = packed_scene.pack(mocap_scene)
		if result == OK:
			return packed_scene

	return null


static func save_packed_scene_for_mocap_recording_at_path(p_save_path: String, p_mocap_recording: MocapRecording) -> int:
	var packed_scene: PackedScene = create_packed_scene_for_mocap_recording(p_mocap_recording)
	if packed_scene:
		var err: int = ResourceSaver.save(packed_scene, p_save_path)
		return err

	return FAILED
