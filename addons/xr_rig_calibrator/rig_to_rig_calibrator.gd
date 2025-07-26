@tool
extends Node3D

const calibrated_tracker_script := preload("./calibrated_tracker.gd")

@export var source_skel: Skeleton3D
@export var target_skel: Skeleton3D

@export var lock_calibration: bool

@export var src_tracker_root: Node3D
@export var src_trackers: Array[Node3D]

@export var aux_hip_tracker: Node3D

@export var allow_head_offset: bool = true
@export var allow_source_rotation: bool = true
@export var apply_target_scale: bool = true
@export var follow_target_position: bool = true
@export var follow_target_rotation: bool = false
@export var follow_target_scale: bool = true

@export var fudge_spine_taut := 0.15
@export var fudge_scale := 0.89

@export var stilts_offset_adjust := Vector3.ZERO

var src_trackers_by_name: Dictionary
var src_trackers_to_name: Dictionary

const MAX_CALIBRATION_PAIR_DISTANCE := 1.234

signal tracker_disabled(tracker_node: calibrated_tracker_script)
signal tracker_changed(tracker_node: calibrated_tracker_script)
signal tracker_enabled(tracker_node: calibrated_tracker_script)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func find_src_trackers() -> void:
	src_trackers_by_name.clear()
	src_trackers_to_name.clear()
	if source_skel == null or target_skel == null:
		return
	if src_tracker_root != null:
		var matched = 0
		for n in src_trackers:
			if n.get_parent() == src_tracker_root:
				matched += 1
		if matched != src_tracker_root.get_child_count():
			src_trackers.clear()
			for n in src_tracker_root.get_children():
				if n is Node3D:
					src_trackers.append(n)
	for n in src_trackers:
		if target_skel.find_bone(n.name) == -1 and not source_skel.find_bone(n.name) == -1:
			continue
		if n.visible:
			src_trackers_by_name[n.name] = n
			src_trackers_to_name[n] = n.name


func calibrate() -> void:
	# Which bones are allowed? Answer: for now, whitelist 6pt in find_src_trackers()
	# Calculate which trackers map to which skeleton points
	find_src_trackers() # bone -> tracker
	if src_trackers_by_name.is_empty():
		return

	if target_skel == null or target_skel.get_parent_node_3d() == null:
		return

	# Then, map those to existing trackers (found / disconnected trackers)
	# Then, disable (did not delete) any found / disconnected that didn't match
	var existing_tracker_nodes_by_name: Dictionary
	for chld in get_children():
		var calibrated_tracker := chld as calibrated_tracker_script
		if calibrated_tracker and calibrated_tracker.visible and not src_trackers_by_name.has(calibrated_tracker.name):
			print("rig_to_rig_calibrator: Disable child " + str(chld.name) + " " + str(calibrated_tracker))
			calibrated_tracker.visible = false
			tracker_disabled.emit(calibrated_tracker)
		elif src_trackers_by_name.has(chld.name):
			if calibrated_tracker:
				existing_tracker_nodes_by_name[chld.name] = calibrated_tracker
				calibrated_tracker.raw_tracker_node = null
				if not calibrated_tracker.visible:
					print("rig_to_rig_calibrator: Enable existing child " + str(chld.name) + " " + str(calibrated_tracker))
					#print(connected_tracked_bones)
					#print(existing_tracker_nodes_by_name)
					calibrated_tracker.visible = true
			else:
				if not chld.name.begins_with("_"):
					chld.name = "_" + chld.name

	# Finally, add any new trackers we discovered.
	for tracked_bone in src_trackers_by_name:
		if not existing_tracker_nodes_by_name.has(tracked_bone):
			print(existing_tracker_nodes_by_name)
			# Add any new trackers.
			var chld3d := Marker3D.new()
			# Child node names should be based on the calibrated bone name (LeftFoot, Head)
			# (not the source tracker name such as VIVE_1234 or LeftController)
			chld3d.name = tracked_bone
			chld3d.set_script(calibrated_tracker_script)
			# TODO: Set default position?
			add_child(chld3d)
			chld3d.owner = self if owner == null else owner
			print("rig_to_rig_calibrator: Add child " + str(tracked_bone) + " " + str(chld3d))
			#print(connected_tracked_bones)
			#print(existing_tracker_nodes_by_name)
			existing_tracker_nodes_by_name[tracked_bone] = chld3d
		var calibrated_tracker := existing_tracker_nodes_by_name[tracked_bone] as calibrated_tracker_script
		if calibrated_tracker.raw_tracker_node != src_trackers_by_name[tracked_bone]:
			#print("MISMATCH " + str(calibrated_tracker.name) + " " + str(calibrated_tracker.raw_tracker_node) + " " + str(src_trackers_by_name[tracked_bone]))
			var was_null: bool = calibrated_tracker.raw_tracker_node == null
			calibrated_tracker.raw_tracker_node = src_trackers_by_name[tracked_bone]
			if was_null:
				tracker_enabled.emit(calibrated_tracker)
			else:
				tracker_changed.emit(calibrated_tracker)

	var source_armspan := source_skel.get_bone_global_rest(source_skel.find_bone("LeftHand")).origin.distance_to(source_skel.get_bone_global_rest(source_skel.find_bone("RightHand")).origin)
	var target_armspan := target_skel.get_bone_global_rest(target_skel.find_bone("LeftHand")).origin.distance_to(target_skel.get_bone_global_rest(target_skel.find_bone("RightHand")).origin)
	var source_spine_len := source_skel.get_bone_global_rest(source_skel.find_bone("Hips")).origin.distance_to(source_skel.get_bone_global_rest(source_skel.find_bone("Head")).origin)
	var target_spine_len := target_skel.get_bone_global_rest(target_skel.find_bone("Hips")).origin.distance_to(target_skel.get_bone_global_rest(target_skel.find_bone("Head")).origin)
	var source_hip_height := source_skel.get_bone_global_rest(source_skel.find_bone("Hips")).origin.y
	var target_hip_height := target_skel.get_bone_global_rest(target_skel.find_bone("Hips")).origin.y
	var chest_spine_hack: bool = target_skel.find_bone("UpperChest") == -1 and source_skel.find_bone("UpperChest") != -1

	var relative_scale := target_armspan / source_armspan

	var target_look_offset := target_skel.get_node_or_null(^"Head/LookOffset") as Node3D
	var look_offset := Vector3.ZERO
	if target_look_offset != null and target_look_offset.position != Vector3.ZERO:
		look_offset = Vector3(0, 0.0, -0.04) - target_look_offset.position
	var spine_offset_add := (target_spine_len - (source_spine_len) * relative_scale + fudge_spine_taut - look_offset.y)

	relative_scale *= fudge_scale

	var head_tracker := existing_tracker_nodes_by_name.get("Head") as calibrated_tracker_script
	if head_tracker != null and get_child(0) != head_tracker:
		move_child(head_tracker, 0)
	var hips_tracker := existing_tracker_nodes_by_name.get("Hips") as calibrated_tracker_script
	if hips_tracker != null and get_child(1) != hips_tracker:
		move_child(hips_tracker, 1)

	var floor_offset_ratio: float = 1.0
	if head_tracker != null:
		floor_offset_ratio = clampf(head_tracker.raw_tracker_node.position.y / source_skel.get_bone_global_rest(source_skel.find_bone("Head")).origin.y, 0.0, 1.0)
	var feet_offset_mul := lerpf(1.0, target_hip_height / (source_hip_height * relative_scale - floor_offset_ratio * spine_offset_add*0.5), 1.0)

	var src_skel_head_rest: Transform3D = ((source_skel.get_bone_global_rest(source_skel.find_bone("Head"))).scaled(Vector3.ONE * 1.0 / source_skel.motion_scale))
	var dst_skel_head_rest: Transform3D = ((target_skel.get_bone_global_rest(target_skel.find_bone("Head"))).scaled(Vector3.ONE * 1.0 / target_skel.motion_scale))

	var head_calibrated: calibrated_tracker_script = head_tracker.raw_tracker_node as calibrated_tracker_script

	var source_transform := target_skel.global_transform
	if not follow_target_rotation:
		source_transform *= Transform3D(target_skel.get_parent_node_3d().global_basis.inverse().orthonormalized())
	if not follow_target_scale:
		source_transform = source_transform.orthonormalized()
	if not follow_target_position:
		source_transform.origin = Vector3.ZERO

	if head_calibrated != null:
		source_transform *= Transform3D(Basis.IDENTITY, stilts_offset_adjust * floor_offset_ratio)
		if allow_source_rotation:
			source_transform *= Transform3D(Basis(Vector3(0,1,0), head_tracker.raw_tracker_node.rotation.y))
		if allow_source_rotation and head_tracker.raw_tracker_node.get_parent_node_3d() != null:
			source_transform *= Transform3D(head_tracker.raw_tracker_node.get_parent_node_3d().global_basis.orthonormalized())
		if apply_target_scale:
			target_skel.basis = Basis.from_scale((target_skel.get_parent_node_3d().global_basis.inverse() * Basis.from_scale(head_calibrated.global_basis.get_scale() / relative_scale)).get_scale())

	global_transform = source_transform
	var head_quat : Basis
	head_quat = head_calibrated.global_basis.orthonormalized() # source_transform.basis.orthonormalized()

	head_quat = Basis.looking_at((Vector3(1,0,1) * (head_quat * Vector3(0,0,1))).normalized())
	head_quat = target_skel.global_basis.orthonormalized() * head_quat
	var abs_look_offset := head_quat * look_offset

	for bone_name in existing_tracker_nodes_by_name:
		var calibrated_tracker := existing_tracker_nodes_by_name[bone_name] as calibrated_tracker_script
		if calibrated_tracker == null:
			continue
		var raw_tracker_node: Node3D = calibrated_tracker.raw_tracker_node
		if raw_tracker_node == null:
			continue

		var target_bone_name: String = bone_name
		if chest_spine_hack and bone_name == "Chest":
			target_bone_name = "Spine"

		var src_skel_bone_rest: Transform3D = ((source_skel.get_bone_global_rest(source_skel.find_bone(bone_name))).scaled(Vector3.ONE * 1.0 / source_skel.motion_scale))
		var dst_skel_bone_rest: Transform3D = ((target_skel.get_bone_global_rest(target_skel.find_bone(target_bone_name))).scaled(Vector3.ONE * 1.0 / target_skel.motion_scale))

		calibrated_tracker.position_offset = Vector3.ZERO

		calibrated_tracker.outer_position_offset = Vector3.ZERO # abs_look_offset
		calibrated_tracker.outer_basis = Basis.IDENTITY

		if bone_name == "Head":
			#source_transform *= Transform3D(Basis.IDENTITY, -(head_calibrated.raw_tracker_node.position * Vector3(1,0,1)*relative_scale))
			calibrated_tracker.outer_position_offset = Vector3(0, abs_look_offset.y, 0)
			calibrated_tracker.position_offset = look_offset - Vector3(0, look_offset.y, 0)
	
		# calibrated_tracker.outer_position_offset -= stilts_offset_adjust
	
		if allow_head_offset and not ["LeftFoot","RightFoot","Hips"].has(bone_name):
			calibrated_tracker.outer_position_offset += -(head_calibrated.raw_tracker_node.position * Vector3(1,0,1)*relative_scale)
			
			#calibrated_tracker.position_offset.y -= src_tracker_root.eye_offset.y * relative_scale
		var quat_offset: Quaternion = dst_skel_bone_rest.basis.get_rotation_quaternion().inverse() * src_skel_bone_rest.basis.get_rotation_quaternion()
		calibrated_tracker.rotation_euler_offset = quat_offset.get_euler()
		var skel_ratio: float = target_skel.global_transform.basis.get_scale().x
		var gscale: float = 1.0 # src_tracker_root.global_transform.basis.get_scale().x
		calibrated_tracker.relative_scale = relative_scale # * skel_ratio / gscale
		
		calibrated_tracker.relative_motion_source = null # src_tracker_root # head_tracker.raw_tracker_node
		calibrated_tracker.tracking_mode = calibrated_tracker.TrackingMode.RELATIVE

		if bone_name == "LeftFoot" or bone_name == "RightFoot":
			if hips_tracker != null or aux_hip_tracker != null:
				calibrated_tracker.bone_extension_target = hips_tracker
				calibrated_tracker.bone_extension = feet_offset_mul
				calibrated_tracker.bone_extension_add_mode = false
		elif bone_name == "Hips":
			if head_tracker != null:
				calibrated_tracker.bone_extension_target = head_tracker
				calibrated_tracker.bone_extension = spine_offset_add
				calibrated_tracker.bone_extension_add_mode = true
		else:
			pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not lock_calibration:
		calibrate()
