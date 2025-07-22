@tool
class_name CopyBonesModifier3D
extends SkeletonModifier3D

@export var source_skeleton: Skeleton3D

func calculate_bone_pose_rotation(target_rotations: Array, skel: Skeleton3D, bone_idx: int) -> Quaternion:
	if bone_idx < 0:
		return Quaternion.IDENTITY
	if typeof(target_rotations[bone_idx]) == TYPE_NIL:
		target_rotations[bone_idx] = calculate_bone_pose_rotation(target_rotations, skel, skel.get_bone_parent(bone_idx)) * skel.get_bone_pose_rotation(bone_idx)
	return target_rotations[bone_idx]


# Called every frame. 'delta' is the elapsed time since the previous frame.
func do_process_modification() -> void:
	var skel := get_skeleton()
	if source_skeleton == null:
		return
	var hips_position: Vector3 = source_skeleton.get_bone_global_pose(source_skeleton.find_bone(&"Hips")).origin * skel.motion_scale / source_skeleton.motion_scale
	skel.reset_bone_poses()
	skel.set_bone_pose_position(skel.find_bone(&"Hips"), hips_position)
	var target_rotations: Array
	target_rotations.resize(skel.get_bone_count())
	var perform_upper_chest_fold: bool = skel.find_bone("UpperChest") == -1 and source_skeleton.find_bone("UpperChest") != -1
	for b in range(source_skeleton.get_bone_count()):
		var bone_name: String = source_skeleton.get_bone_name(b)
		var tgt_b: int
		if perform_upper_chest_fold and bone_name == "Chest":
			#print("SRC:" + str(source_skeleton.get_bone_pose_rotation(b)))
			continue
		if perform_upper_chest_fold and bone_name == "UpperChest":
			tgt_b = skel.find_bone("Chest")
		else:
			tgt_b = skel.find_bone(bone_name)
		if tgt_b < 0:
			continue
		var rot: Quaternion = source_skeleton.get_bone_global_pose(b).basis.get_rotation_quaternion()
		#while tgt_b == -1 and b != -1:
			#rot = source_skeleton.get_bone_rest(b).basis.get_rotation_quaternion().inverse() * rot
			##print("My rot1 " + str(source_skeleton.get_bone_name(b)) + " " + str(rot))
			#b = source_skeleton.get_bone_parent(b)
			#rot = source_skeleton.get_bone_rest(b).basis.get_rotation_quaternion() * rot
			##print("My rot2 " + str(source_skeleton.get_bone_name(b)) + " " + str(rot))
			#tgt_b = skel.find_bone(source_skeleton.get_bone_name(b))
			#rot = source_skeleton.get_bone_pose_rotation(b) * rot
			##print("My rot3 " + str(source_skeleton.get_bone_name(b)) + " " + str(rot))
		var tgt_par_b := skel.get_bone_parent(tgt_b)
		#while typeof(target_rotations[tgt_par_b]) == TYPE_NIL:
		#	tgt_par_b = skel.get_bone_parent(tgt_par_b)
		var parent_bone_rot: Quaternion = calculate_bone_pose_rotation(target_rotations, skel, tgt_par_b)
		if source_skeleton.get_bone_name(b) == "UpperChest":
			pass#print(parent_bone_rot)
		if tgt_b == skel.find_bone("Chest"):
			pass#print("TGT: " + str(parent_bone_rot.inverse() * rot))
		skel.set_bone_pose_rotation(tgt_b, parent_bone_rot.inverse() * rot)
		target_rotations[tgt_b] = rot

func _process_modification() -> void:
	#set_process(true)
	pass # do_process_modification()

func _process(_delta: float):
	do_process_modification()
	#print("Do process")
	#get_skeleton().clear_bones_global_pose_override()
