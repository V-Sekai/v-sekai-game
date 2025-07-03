@tool
extends SarGameEntityComponent
class_name SarGameEntityComponentSkeletonInterpolation

# Ugly hack until we nail interpolated skeletons in a more universal way.

var _prev_frame_skeleton: Skeleton3D = null
var _next_frame_skeleton: Skeleton3D = null
var _original_skeleton: Skeleton3D = null
var _interpolated_skeleton: Skeleton3D = null
	
func _copy_skeleton_pose(p_src: Skeleton3D, p_target: Skeleton3D) -> void:
	if not SarUtils.assert_equal(p_src.get_bone_count(), p_target.get_bone_count(), "SarGameEntityComponentSkeletonInterpolation._copy_skeleton_pose: src and target have differing bone count"):
		return
	
	for i: int in range(0, p_target.get_bone_count()):
		p_target.set_bone_pose(i, p_src.get_bone_pose(i))
	
func _copy_skeleton_bones(p_src: Skeleton3D, p_target: Skeleton3D) -> void:
	for i: int in range(0, p_src.get_bone_count()):
		var idx: int = p_target.add_bone(p_src.get_bone_name(i))
		p_target.set_bone_parent(idx, p_src.get_bone_parent(i))
		p_target.set_bone_rest(idx, p_src.get_bone_rest(i))
		p_target.set_bone_pose(idx, p_src.get_bone_pose(i))
	
func _update_interpolation_rig() -> void:
	if _next_frame_skeleton and _prev_frame_skeleton and _original_skeleton and _interpolated_skeleton:
		_copy_skeleton_pose(_next_frame_skeleton, _prev_frame_skeleton)
		_copy_skeleton_pose(_original_skeleton, _next_frame_skeleton)
	
func _reference_skeleton_updated() -> void:
	_update_interpolation_rig()
	
func _setup_interpolation_rig_for_node(p_root: Node3D, p_skeleton: Skeleton3D) -> void:
	if _prev_frame_skeleton:
		_prev_frame_skeleton.queue_free()
	
	if _next_frame_skeleton:
		_next_frame_skeleton.queue_free()
	
	if _interpolated_skeleton:
		_interpolated_skeleton.queue_free()
	
	_next_frame_skeleton = Skeleton3D.new()
	_next_frame_skeleton.name = "NextFrameSkeleton"
	_next_frame_skeleton.motion_scale = p_skeleton.motion_scale
	_next_frame_skeleton.animate_physical_bones = false
	_copy_skeleton_bones(p_skeleton, _next_frame_skeleton)
	
	_prev_frame_skeleton = Skeleton3D.new()
	_prev_frame_skeleton.name = "PreviousFrameSkeleton"
	_prev_frame_skeleton.motion_scale = p_skeleton.motion_scale
	_prev_frame_skeleton.animate_physical_bones = false
	_copy_skeleton_bones(p_skeleton, _prev_frame_skeleton)
	
	_interpolated_skeleton = Skeleton3D.new()
	_interpolated_skeleton.name = "InterpolatedSkeleton"
	_interpolated_skeleton.motion_scale = p_skeleton.motion_scale
	_interpolated_skeleton.animate_physical_bones = false
	_copy_skeleton_bones(p_skeleton, _interpolated_skeleton)
	p_skeleton.add_sibling(_interpolated_skeleton)
	
	var interpolate_modifier: SarInterpolateSkeletonModifier3D = SarInterpolateSkeletonModifier3D.new()
	interpolate_modifier.name = "Interpolator"
	interpolate_modifier.interp_old = _prev_frame_skeleton
	interpolate_modifier.interp_new = _next_frame_skeleton
	_interpolated_skeleton.add_child(interpolate_modifier)
	
	var mesh_instances: Array[Node] = p_root.find_children("*", "MeshInstance3D")
	for mesh_instance: MeshInstance3D in mesh_instances:
		var node: Node = mesh_instance.get_node_or_null(mesh_instance.skeleton)
		if node == p_skeleton:
			mesh_instance.skeleton = mesh_instance.get_path_to(_interpolated_skeleton)
	
	# Hack. Make sure the VRM secondaries are using the interpolated skeleton so their
	# interpolation can be layered on top.
	var vrm_secondaries: Array[Node] = p_root.find_children("*", "VRMSecondary")
	for secondary in vrm_secondaries:
		secondary.skeleton = secondary.get_path_to(_interpolated_skeleton)
	
	_original_skeleton = p_skeleton
	if not SarUtils.assert_ok(_original_skeleton.skeleton_updated.connect(_reference_skeleton_updated),
		"Could not connect signal '_original_skeleton.skeleton_updated' to '_reference_skeleton_updated'"):
		return


func _on_model_component_model_pre_change(p_new_model: SarModel3D) -> void:
	var general_skeleton: Skeleton3D = p_new_model.find_child("GeneralSkeleton")
	if general_skeleton:
		_setup_interpolation_rig_for_node(p_new_model, general_skeleton)
