@tool
extends Node3D

#@export_node_path("Node3D") var raw_tracker: NodePath:
	#set(value):
		#raw_tracker = value
		#raw_tracker_node = get_node_or_null(raw_tracker)
@export var raw_tracker_node: Node3D
@export_custom(PROPERTY_HINT_RANGE,"-3,3,0.01") var outer_position_offset: Vector3
@export var outer_basis: Basis
@export_custom(PROPERTY_HINT_RANGE,"-3,3,0.01") var position_offset: Vector3
@export_custom(PROPERTY_HINT_RANGE,"-180,180,0.01,radians") var rotation_euler_offset: Vector3
@export var relative_scale: float = 1.0
@export_range(-3,3,0.01) var bone_extension: float = 0
@export var bone_extension_target: Node3D
var calculated_bone_extension: Vector3 = Vector3.ZERO
@export var bone_extension_add_mode: bool = false
@export_range(0, 2.0, 0.001, "or_greater", "or_less") var fixed_distance: float = 0
@export_range(0, 1, 0.001) var aim_to_fixed_distance: float = 0
#expo

enum TrackingMode {
	ABSOLUTE = 0,
	ORTHONORMALIZED_PARENT = 1,
	RELATIVE = 2,
}

@export_enum("Absolute", "Orthonormalized Parent", "Relative") var tracking_mode: int = TrackingMode.RELATIVE

@export var relative_motion_position_initial: Vector3
@export var relative_motion_position_offset: Vector3
@export var relative_motion_position_scale: Vector3 = Vector3(1,0,1)
@export var relative_motion_rotation_initial: Quaternion
@export var relative_motion_rotation_offset: Quaternion
@export var relative_motion_scale: Vector3 = Vector3.ZERO
@export var relative_motion_source: Node3D:
	set(value):
		relative_motion_source = value
		relative_motion_position_offset = Vector3.ZERO
		relative_motion_rotation_offset = Quaternion.IDENTITY
		if value == null:
			relative_motion_position_initial = Vector3()
			relative_motion_rotation_initial = Quaternion.IDENTITY
		else:
			if tracking_mode == TrackingMode.RELATIVE:
				relative_motion_position_initial = relative_motion_source.position
			elif tracking_mode == TrackingMode.ORTHONORMALIZED_PARENT:
				relative_motion_position_initial = relative_motion_source.get_parent_node_3d().global_transform.orthonormalized() * relative_motion_source.position
			else:
				relative_motion_position_initial = relative_motion_source.global_position
			relative_motion_rotation_initial = value.global_basis.get_rotation_quaternion()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var raw_tracker_valid: bool = raw_tracker_node != null and raw_tracker_node.visible and not raw_tracker_node.position.is_zero_approx()
	if raw_tracker_node != null and raw_tracker_valid and not visible:
		visible = true
	if raw_tracker_node == null or not raw_tracker_valid:
		if visible == true:
			visible = false
		return
	if relative_motion_source != null and relative_motion_source.visible:
		var rel_source_pos: Vector3
		if tracking_mode == TrackingMode.RELATIVE:
			rel_source_pos = relative_motion_source.position
		elif tracking_mode == TrackingMode.ORTHONORMALIZED_PARENT:
			rel_source_pos = relative_motion_source.get_parent_node_3d().global_transform.orthonormalized() * relative_motion_source.position
		else:
			rel_source_pos = relative_motion_source.global_position
		relative_motion_position_offset = (rel_source_pos - relative_motion_position_initial)
		relative_motion_rotation_offset = relative_motion_rotation_initial.inverse() * relative_motion_source.global_basis.get_rotation_quaternion()

	if not basis.is_finite():
		basis = Basis.IDENTITY
	var raw_tracker_parent_transform := Transform3D.IDENTITY
	if tracking_mode == TrackingMode.ORTHONORMALIZED_PARENT or tracking_mode == TrackingMode.ABSOLUTE:
		raw_tracker_parent_transform = Transform3D(raw_tracker_node.get_parent_node_3d().global_basis)
		if tracking_mode == TrackingMode.ORTHONORMALIZED_PARENT:
			raw_tracker_parent_transform = raw_tracker_parent_transform.orthonormalized()

	var raw_tracker_transform := raw_tracker_node.transform.orthonormalized()

	if relative_motion_source != null and relative_motion_source.visible:
		raw_tracker_transform.origin -= (relative_motion_position_offset) * relative_motion_position_scale


	raw_tracker_transform = raw_tracker_parent_transform * raw_tracker_transform

	if not is_zero_approx(relative_scale):
		raw_tracker_transform = Transform3D.IDENTITY.scaled_local(Vector3.ONE * relative_scale) * raw_tracker_transform

	var quat_offset: Quaternion = Quaternion.from_euler(rotation_euler_offset)
	var new_position: Vector3 = outer_position_offset + ((raw_tracker_transform * (1 * position_offset)))
	if bone_extension_target != null:
		var extension_vector: Vector3 = (new_position - bone_extension_target.position)
		var target_extension: Vector3 = Vector3.ZERO
		if not extension_vector.is_zero_approx():
			if bone_extension_add_mode:
				calculated_bone_extension = Transform3D(Basis.from_scale(raw_tracker_transform.basis.get_scale())) * (target_extension + extension_vector.normalized() * bone_extension)
			else:
				calculated_bone_extension = bone_extension_target.position + extension_vector * bone_extension - new_position
			new_position += calculated_bone_extension
	var new_basis: Quaternion = raw_tracker_node.basis.get_rotation_quaternion() * quat_offset
	if get_parent().name == 'AvatarCalibratedRig' and name == 'Hips':
		pass
	position = new_position
	basis = outer_basis * Basis(new_basis)
