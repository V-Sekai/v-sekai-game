@tool
extends SkeletonModifier3D
class_name SarInterpolateSkeletonModifier3D

## A SkeletonModifier3D designed to interpolate a Skeleton3D towards a
## a reference Skeleton3D.

@export var interp_old: Skeleton3D = null
@export var interp_new: Skeleton3D = null

func _copy_skeleton_pose(p_src: Skeleton3D, p_target: Skeleton3D) -> void:
	if not SarUtils.assert_equal(p_src.get_bone_count(), p_target.get_bone_count(),
		"SarInterpolateSkeletonModifier3D._copy_skeleton_pose: p_src and p_target Skeleton3D have differing bone count."):
		return

	for i: int in range(0, p_target.get_bone_count()):
		p_target.set_bone_pose(i, p_src.get_bone_pose(i))

func _interpolate_skeleton_pose(p_src_a: Skeleton3D, p_src_b: Skeleton3D, p_target: Skeleton3D, p_weight: float) -> void:
	if not SarUtils.assert_equal(p_src_a.get_bone_count(), p_target.get_bone_count(),
		"SarInterpolateSkeletonModifier3D._interpolate_skeleton_pose: p_src_a and p_target Skeleton3D have differing bone count."):
		return
	if not SarUtils.assert_equal(p_src_b.get_bone_count(), p_target.get_bone_count(),
		"SarInterpolateSkeletonModifier3D._interpolate_skeleton_pose: p_src_b and p_target Skeleton3D have differing bone count."):
		return
	
	for i: int in range(0, p_target.get_bone_count()):
		p_target.set_bone_pose(i, p_src_a.get_bone_pose(i).interpolate_with(p_src_b.get_bone_pose(i), p_weight))

func _process_modification() -> void:
	if is_physics_interpolated_and_enabled():
		if interp_old and interp_new and get_skeleton():
			_interpolate_skeleton_pose(interp_old, interp_new, get_skeleton(), Engine.get_physics_interpolation_fraction())
	else:
		if  interp_new and get_skeleton():
			_copy_skeleton_pose(interp_new, get_skeleton())
