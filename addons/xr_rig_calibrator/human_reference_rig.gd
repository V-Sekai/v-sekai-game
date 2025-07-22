@tool
extends Skeleton3D

# TODO
# @export var armspan: float: set: recalculate_skeleton()
# @export var heaad_root_height: float: set: recalculate_skeleton()

const GodotPositionOffsets := {
	"Hips": Vector3(0, 1, 0),
	"LeftUpperLeg": Vector3(0.078713, -0.064749, -0.01534),
	"RightUpperLeg": Vector3(-0.078713, -0.064749, -0.01534),
	"LeftLowerLeg": Vector3(0, 0.42551, 0.003327),
	"RightLowerLeg": Vector3(0, 0.42551, 0.003327),
	"LeftFoot": Vector3(0, 0.426025, 0.029196),
	"RightFoot": Vector3(0, 0.426025, 0.029196),
	"Spine": Vector3(0, 0.097642, 0.001261),
	"Chest": Vector3(0, 0.096701, -0.009598),
	"Neck": Vector3(0, 0.159882, -0.02413),
	"Head": Vector3(0, 0.092236, 0.016159),
	"LeftShoulder": Vector3(0.043831, 0.104972, -0.025203),
	"RightShoulder": Vector3(-0.043826, 0.104974, -0.025203),
	"LeftUpperArm": Vector3(-0.021406, 0.101581, -0.005031),
	"RightUpperArm": Vector3(0.021406, 0.101586, -0.005033),
	"LeftLowerArm": Vector3(0, 0.267001, 0),
	"RightLowerArm": Vector3(0, 0.267001, 0),
	"LeftHand": Vector3(0, 0.271675, 0),
	"RightHand": Vector3(0, 0.271675, 0),
	"LeftToes": Vector3(0, 0.102715, -0.083708),
	"RightToes": Vector3(0, 0.102715, -0.083708),
}


func _init():
	clear_bones()
	var sp := SkeletonProfileHumanoid.new()
	for b in range(sp.bone_size):
		add_bone(sp.get_bone_name(b))
	for b in range(sp.bone_size):
		set_bone_parent(b, sp.find_bone(sp.get_bone_parent(b)))
		var t: Transform3D = sp.get_reference_pose(b)
		if GodotPositionOffsets.has(sp.get_bone_name(b)):
			t.origin = GodotPositionOffsets[sp.get_bone_name(b)]
		set_bone_rest(b, t)
		set_bone_pose_position(b, t.origin)
		set_bone_pose_rotation(b, t.basis.get_rotation_quaternion())
		#set_bone_pose_scale(b, t.basis.get_scale())
