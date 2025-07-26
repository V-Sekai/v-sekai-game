@tool
extends Node3D

const calibrated_tracker_script := preload("./calibrated_tracker.gd")

@export var skel: Skeleton3D

@export var calibration: bool = false
@export var calibrate_once: bool = false
@export var override_xr_active: bool = true
@export var use_xr_camera_node: bool = false
@export var force_enable: bool = false
@export var attach_by_name: bool = false
@export var disable_calibration: bool = false

@export var raw_tracker_root: Node3D
@export var replace_tracker_root: NodePath
@export var raw_trackers: Array[Node3D]

var full_body_trackers: Dictionary[String, Node3D]

@export var eye_offset: Vector3 = Vector3(0.0, -0.04, 0.04)
# @export var height

const BUILTIN_XR_TRACKERS := {
	&"left_hand": "LeftHand",
	&"right_hand": "RightHand",
	&"head": "Head",
	&"/user/hand_tracker/left": "",
	&"/user/hand_tracker/right": "",
}

const MAX_CALIBRATION_PAIR_DISTANCE := 1.234

signal tracker_disabled(tracker_node: calibrated_tracker_script)
signal tracker_changed(tracker_node: calibrated_tracker_script)
signal tracker_enabled(tracker_node: calibrated_tracker_script)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func find_raw_trackers() -> Array[Node3D]:
	if skel == null:
		return []
	if raw_tracker_root != null:
		var matched := 0
		for n in raw_trackers:
			if n == null:
				continue
			if n.get_parent() == raw_tracker_root:
				matched += 1
		if matched != raw_tracker_root.get_child_count():
			raw_trackers.clear()
			for n in raw_tracker_root.get_children():
				if n == null:
					continue
				if n is Node3D:
					if (n as Node3D).visible or force_enable:
						raw_trackers.append(n)

	return raw_trackers

func connect_builtin_trackers(raw_trackers: Array[Node3D]) -> Dictionary[String, Node3D]:

	# exclude hands and head from whitelist for now. those are automatic.
	var connected_tracked_bones: Dictionary[String, Node3D] # bone -> tracker

	#print("find cal " + str(connection_points))

	for tracker in raw_trackers:
		if not force_enable and not tracker.visible:
			continue
		var builtin_bone_name: String = ""
		if tracker.position.is_zero_approx():
			continue # Desktop camera is 0,0,0; and VR hardware may report 0,0,0 if tracking fails.
		var xr_node := tracker as XRNode3D
		if xr_node != null:
			if not xr_node.get_is_active() and not override_xr_active:
				continue
			if xr_node.pose != &"grip": # FIXME: Which pose is correct for hand position?
				continue
			if BUILTIN_XR_TRACKERS.has(xr_node.tracker):
				builtin_bone_name = BUILTIN_XR_TRACKERS[xr_node.tracker]
				if builtin_bone_name.is_empty():
					continue
		elif attach_by_name:
			builtin_bone_name = tracker.name
		var xr_camera = tracker as XRCamera3D
		if use_xr_camera_node and xr_camera or tracker.name == "XRCamera3D":
			builtin_bone_name = "Head"
		if not builtin_bone_name.is_empty() and connected_tracked_bones.get(builtin_bone_name) == null:
			connected_tracked_bones[builtin_bone_name] = tracker

	return connected_tracked_bones

func calculate_align_pose_adjustment(connected_tracked_bones: Dictionary[String, Node3D]) -> Transform3D:
	var body_align_pose_adjustment := Transform3D()

	if "Head" in connected_tracked_bones:
		var ref_head_pose: Transform3D = skel.get_bone_global_pose(skel.find_bone("Head"))
		var ref_eye_position := ref_head_pose.origin # + eye_offset
		var ref_head_forward := ((ref_head_pose.basis * Vector3(0,0,1)) * Vector3(1,0,1)).normalized()

		var eye_tracker: Node3D = connected_tracked_bones["Head"]
		var eye_pose: Transform3D = (eye_tracker.transform) * Transform3D(Basis.IDENTITY, eye_offset)
		var head_forward := ((eye_pose.basis * Vector3(0,0,-1)) * Vector3(1,0,1)).normalized()
		var skel_rotation := Quaternion.IDENTITY
		var head_dot := head_forward.dot(ref_head_forward)
		if head_dot < -0.99999:
			skel_rotation = Quaternion(0,1,0,0) # Exact 180 degree rotation
		elif head_dot < 0.99999:
			skel_rotation = Quaternion(head_forward, ref_head_forward).normalized()
		var rotated_eye_pos: Vector3 = skel_rotation * eye_pose.origin
		var head_normalized_adjustment := Transform3D(skel_rotation, Vector3(0,1,0) * (ref_eye_position - rotated_eye_pos))
		body_align_pose_adjustment = head_normalized_adjustment # * skel.transform.affine_inverse()
	return body_align_pose_adjustment

func assign_nearby_trackers(raw_trackers: Array[Node3D], connected_tracked_bones: Dictionary[String, Node3D],
		body_align_pose_adjustment: Transform3D) -> void:
	var connection_points: PackedVector3Array

	var exclude_trackers: Dictionary[Node3D, bool]
	for tracker in raw_trackers:
		var xr_node := tracker as XRNode3D
		if xr_node != null:
			if BUILTIN_XR_TRACKERS.has(xr_node.tracker):
				exclude_trackers[tracker] = true
		var xr_camera = tracker as XRCamera3D
		if xr_camera or tracker.name == "XRCamera3D":
			exclude_trackers[tracker] = true

	full_body_trackers.clear();

	var connected_trackers: Dictionary[Node3D, String] # tracker -> bone
	for builtin_bone_name in connected_tracked_bones:
		connected_trackers[connected_tracked_bones[builtin_bone_name]] = builtin_bone_name
	var connection_bones := PackedStringArray(["LeftFoot", "RightFoot", "Hips", "Chest", "LeftLowerArm", "LeftLowerLeg", "RightLowerArm", "RightLowerLeg"])
	var promote_trackers := {
		"Chest": ["Hips"],
		"LeftLowerLeg": ["LeftFoot", "Hips"],
		"RightLowerLeg": ["RightFoot", "Hips"],
	}

	for bone_name in connection_bones:
		connection_points.append(skel.get_bone_global_pose(skel.find_bone(bone_name)).origin)

	# minimize distance(bone, tracker) for all combinations of bone, tracker.
	# then, apply the delta transform.
	if not calibration:
		print(connected_tracked_bones)
	var raw_tracker_to_bone_idx_dist_sq: Dictionary
	for tracker in raw_trackers:
		if exclude_trackers.has(tracker):
			continue
		if tracker == null:
			continue
		if not force_enable and not tracker.visible:
			continue
		if tracker.position.is_zero_approx():
			continue
		var xr_node := tracker as XRNode3D
		if xr_node != null:
			if not xr_node.get_is_active() and not override_xr_active:
				continue
		if connected_trackers.has(tracker):
			continue
		var pos: Vector3 = body_align_pose_adjustment * (tracker.position)
		var candidate_bones: PackedVector2Array
		for j in range(len(connection_points)):
			if connected_tracked_bones.has(connection_bones[j]):
				continue
			var point: Vector3 = connection_points[j]
			if attach_by_name and connected_tracked_bones.has(tracker.name):
				candidate_bones = PackedVector2Array([Vector2(0, j)])
				break
			var dist_sq: float = point.distance_squared_to(pos)
			if dist_sq < MAX_CALIBRATION_PAIR_DISTANCE * 5:
				candidate_bones.append(Vector2(dist_sq, j))
		candidate_bones.sort()
		if not calibration:
			print("Candidates for tracker " + str(tracker.name) + ": " + str(candidate_bones))
		if len(candidate_bones) != 0:
			raw_tracker_to_bone_idx_dist_sq[tracker] = candidate_bones
	var candidate_bone_to_raw_tracker: Array[Node3D]
	candidate_bone_to_raw_tracker.resize(len(connection_points))
	var raw_tracker_to_bone_idx_dist_sq_queue: Array = raw_tracker_to_bone_idx_dist_sq.keys()
	var raw_tracker_idx: int = 0
	while raw_tracker_idx < len(raw_tracker_to_bone_idx_dist_sq_queue):
		var raw_tracker: Node3D = raw_tracker_to_bone_idx_dist_sq_queue[raw_tracker_idx]
		raw_tracker_idx += 1
		var found_match: bool = false
		var candidates: PackedVector2Array = raw_tracker_to_bone_idx_dist_sq[raw_tracker]
		for cand_idx in range(len(candidates)):
			var bone_idx := int(candidates[cand_idx].y)
			if candidate_bone_to_raw_tracker[bone_idx] == null:
				if not calibration:
					print("Assigning bone " + connection_bones[bone_idx] + " for tracker " + raw_tracker.name)
				candidate_bone_to_raw_tracker[bone_idx] = raw_tracker
				found_match = true
				break
		if not found_match:
			var bone_idx := int(raw_tracker_to_bone_idx_dist_sq[raw_tracker][0].y)
			var steal_candidates: PackedVector2Array = raw_tracker_to_bone_idx_dist_sq[candidate_bone_to_raw_tracker[bone_idx]]
			if len(steal_candidates) > 1:
				for steal_idx in range(len(steal_candidates)):
					if int(steal_candidates[steal_idx].y) == bone_idx:
						steal_candidates.remove_at(steal_idx)
						break
				if not calibration:
					print("Tracker " + str(raw_tracker.name) + " stealing bone " + connection_bones[bone_idx] + " from tracker " + candidate_bone_to_raw_tracker[bone_idx].name)
				raw_tracker_to_bone_idx_dist_sq_queue.append(candidate_bone_to_raw_tracker[bone_idx])
				candidate_bone_to_raw_tracker[bone_idx] = raw_tracker

	for src_bone_name in promote_trackers:
		var src_idx: int = connection_bones.find(src_bone_name)
		if (src_idx == -1):
			push_error("Undefined promotion src tracker " + str(src_bone_name))
			continue
		for promotion in promote_trackers[src_bone_name]:
			var promotion_idx: int = connection_bones.find(promotion)
			if (promotion_idx == -1):
				push_error("Undefined promotion dst tracker " + str(promotion))
				continue
			var src_tracker: Node3D = candidate_bone_to_raw_tracker[src_idx]
			if candidate_bone_to_raw_tracker[promotion_idx] == null and src_tracker != null:
				if not calibration:
					print("Promote tracker " + str(src_tracker.name) + " from bone " + src_bone_name + " to " + promotion)
				candidate_bone_to_raw_tracker[promotion_idx] = src_tracker
				candidate_bone_to_raw_tracker[src_idx] = null

	for min_bone_idx in range(len(candidate_bone_to_raw_tracker)):
		var min_tracker: Node3D = candidate_bone_to_raw_tracker[min_bone_idx]
		if min_tracker == null:
			if not calibration:
				print("Bone not bound " + str(connection_bones[min_bone_idx]))
			continue
		var min_bone: String = connection_bones[min_bone_idx]
		if not calibration:
			print("Found a bone " + str(connection_bones[min_bone_idx]) + " " + str(min_tracker) + " distances " + str(raw_tracker_to_bone_idx_dist_sq[min_tracker]))
		connected_trackers[min_tracker] = min_bone
		connected_tracked_bones[min_bone] = min_tracker
		full_body_trackers[min_bone] = min_tracker

func calibrate(include_full_body: bool) -> void:
	# Which bones are allowed? Answer: for now, whitelist 6pt in find_raw_trackers()
	# Calculate which trackers map to which skeleton points
	global_basis = raw_tracker_root.global_basis.orthonormalized()
	global_position = raw_tracker_root.global_position
	var raw_trackers: Array[Node3D] = find_raw_trackers()
	var connected_tracked_bones: Dictionary[String, Node3D] = connect_builtin_trackers(raw_trackers) # bone -> tracker
	var body_align_pose_adjustment: Transform3D = calculate_align_pose_adjustment(connected_tracked_bones)
	var adjust_y: float = body_align_pose_adjustment.origin.y
	var adjust_xform := Transform3D(Basis.IDENTITY, Vector3(0, adjust_y, 0))
	position.y += adjust_y
	
	if include_full_body:
		assign_nearby_trackers(raw_trackers, connected_tracked_bones, body_align_pose_adjustment)

	body_align_pose_adjustment.origin.y = 0
	global_basis = raw_tracker_root.global_basis.orthonormalized() * body_align_pose_adjustment.basis

	if connected_tracked_bones.is_empty():
		return

	# Then, map those to existing trackers (found / disconnected trackers)
	# Then, disable (did not delete) any found / disconnected that didn't match
	var existing_tracker_nodes_by_name: Dictionary[String, Node3D]
	for chld in get_children():
		var calibrated_tracker := chld as calibrated_tracker_script
		if (calibrated_tracker and calibrated_tracker.visible and
				not connected_tracked_bones.has(calibrated_tracker.name) and
				not full_body_trackers.has(calibrated_tracker.name)):
			if not calibration:
				print("calibration_orchestrator: Disable child " + str(chld.name) + " " + str(calibrated_tracker))
			calibrated_tracker.visible = false
			calibrated_tracker.raw_tracker_node = null
			tracker_disabled.emit(calibrated_tracker)
		elif connected_tracked_bones.has(chld.name):
			if calibrated_tracker:
				existing_tracker_nodes_by_name[chld.name] = calibrated_tracker
				if not calibrated_tracker.visible:
					if not calibration:
						print("calibration_orchestrator: Enable existing child " + str(chld.name) + " " + str(calibrated_tracker))
					#print(connected_tracked_bones)
					#print(existing_tracker_nodes_by_name)
					calibrated_tracker.visible = true
			else:
				if not chld.name.begins_with("_"):
					chld.name = "_" + chld.name

	# Finally, add any new trackers we discovered.
	for tracked_bone in connected_tracked_bones:
		if not existing_tracker_nodes_by_name.has(tracked_bone):
			# Add any new trackers.
			var chld3d := Marker3D.new()
			# Child node names should be based on the calibrated bone name (LeftFoot, Head)
			# (not the source tracker name such as VIVE_1234 or LeftController)
			chld3d.name = tracked_bone
			chld3d.set_script(calibrated_tracker_script)
			# TODO: Set default position?
			add_child(chld3d)
			chld3d.owner = self if owner == null else owner
			if not calibration:
				print("calibration_orchestrator: Add child " + str(tracked_bone) + " " + str(chld3d))
			#print(connected_tracked_bones)
			#print(existing_tracker_nodes_by_name)
			existing_tracker_nodes_by_name[tracked_bone] = chld3d
		var calibrated_tracker := existing_tracker_nodes_by_name[tracked_bone] as calibrated_tracker_script
		calibrated_tracker.tracking_mode = calibrated_tracker.TrackingMode.RELATIVE
		calibrated_tracker.outer_position_offset = Vector3.ZERO

		var new_raw_tracker_node: Node3D = connected_tracked_bones[tracked_bone]
		if replace_tracker_root != NodePath():
			new_raw_tracker_node = get_node(NodePath(str(replace_tracker_root).path_join(new_raw_tracker_node.name))) as Node3D

		if calibrated_tracker.raw_tracker_node != new_raw_tracker_node:
			# print(str(calibrated_tracker) + " / " + str(calibrated_tracker.get_path()) + " RTN " + str(calibrated_tracker.raw_tracker_node) + " new " + str(new_raw_tracker_node))
			var was_null: bool = calibrated_tracker.raw_tracker_node == null
			calibrated_tracker.raw_tracker_node = new_raw_tracker_node
			if was_null:
				tracker_enabled.emit(calibrated_tracker)
			else:
				tracker_changed.emit(calibrated_tracker)

	if "Head" in existing_tracker_nodes_by_name:
		var calibrated_tracker := existing_tracker_nodes_by_name["Head"] as calibrated_tracker_script
		var ref_eye_position := -eye_offset
		var ref_head_forward := Quaternion(0,1,0,0) # 180 rotation about Y # Vector3(0,0,1).normalized()
		calibrated_tracker.position_offset = eye_offset
		calibrated_tracker.rotation_euler_offset = ref_head_forward.get_euler()
		calibrated_tracker.tracking_mode = calibrated_tracker.TrackingMode.RELATIVE
		for tracked_bone in connected_tracked_bones:
			var other_calibrated_tracker := existing_tracker_nodes_by_name[tracked_bone] as calibrated_tracker_script
			if other_calibrated_tracker != null:
				other_calibrated_tracker.relative_motion_position_scale = Vector3(1,0,1)
				other_calibrated_tracker.relative_motion_source = calibrated_tracker.raw_tracker_node
	if "LeftHand" in existing_tracker_nodes_by_name:
		var calibrated_tracker := existing_tracker_nodes_by_name["LeftHand"] as calibrated_tracker_script
		calibrated_tracker.position_offset = Vector3.ZERO
		calibrated_tracker.rotation_euler_offset = (Quaternion.from_euler(Vector3(PI, -PI/2, 0))).get_euler()
		calibrated_tracker.tracking_mode = calibrated_tracker.TrackingMode.RELATIVE
		disable_calibration
	if "RightHand" in existing_tracker_nodes_by_name:
		var calibrated_tracker := existing_tracker_nodes_by_name["RightHand"] as calibrated_tracker_script
		calibrated_tracker.position_offset = Vector3.ZERO
		calibrated_tracker.rotation_euler_offset = (Quaternion.from_euler(Vector3(PI, PI/2, 0))).get_euler()
		calibrated_tracker.tracking_mode = calibrated_tracker.TrackingMode.RELATIVE
		disable_calibration

	if include_full_body:
		for bone_name in full_body_trackers:
			var calibrated_tracker := existing_tracker_nodes_by_name[bone_name] as calibrated_tracker_script
			if calibrated_tracker == null:
				continue
			var raw_tracker_node: Node3D = calibrated_tracker.raw_tracker_node
			if raw_tracker_node == null:
				continue

			var skel_bone_position: Transform3D = (skel.get_bone_global_pose(skel.find_bone(bone_name)))

			var raw_tracker_transform := Transform3D.IDENTITY # body_align_pose_adjustment # Transform3D.IDENTITY
			raw_tracker_transform *= adjust_xform* raw_tracker_node.transform.orthonormalized()
			# Transform3D(Basis(Quaternion(0,1,0,0))) * 
			calibrated_tracker.position_offset = raw_tracker_transform.affine_inverse() * (Transform3D(body_align_pose_adjustment.basis.inverse()) * skel_bone_position.origin)
			var quat_offset: Quaternion = raw_tracker_transform.basis.get_rotation_quaternion().inverse() * body_align_pose_adjustment.basis.get_rotation_quaternion().inverse() * skel_bone_position.basis.get_rotation_quaternion()
			calibrated_tracker.rotation_euler_offset = quat_offset.get_euler()
			calibrated_tracker.tracking_mode = calibrated_tracker.TrackingMode.RELATIVE

func set_owner_recursive(n: Node, owner_: Node):
	n.owner = owner_
	n.scene_file_path = ""
	for chld in n.get_children():
		set_owner_recursive(chld, owner_)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if calibration or calibrate_once:
		calibrate(true)
	elif not disable_calibration:
		calibrate(false)
	if calibrate_once:
		calibrate_once = false
