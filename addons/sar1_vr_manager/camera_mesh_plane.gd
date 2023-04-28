@tool
extends MeshInstance3D

const camera_mesh_plane_const = preload("res://addons/sar1_vr_manager/camera_mesh_plane.gd")

@export var distance: float = 1.0:
	set = set_distance


static func xform_plane(p_transform: Transform3D, p_plane: Plane) -> Plane:
	var point: Vector3 = p_plane.normal * p_plane.d
	var point_dir: Vector3 = point + p_plane.normal
	point = p_transform * (point)
	point_dir = p_transform * (point_dir)

	var normal: Vector3 = point_dir - point
	normal = normal.normalized()
	var d: float = normal.dot(point)

	return Plane(normal, d)


static func get_endpoints_for_camera(p_camera: Camera3D) -> PackedVector2Array:
	var planes: Array = p_camera.get_frustum()

	var camera_gt_inv: Transform3D = p_camera.global_transform.inverse()

	var near_plane: Plane = xform_plane(camera_gt_inv, planes[0])
	var far_plane: Plane = xform_plane(camera_gt_inv, planes[1])
	# The is a placeholder for the plane index 2.
	var top_plane: Plane = xform_plane(camera_gt_inv, planes[3])
	var right_plane: Plane = xform_plane(camera_gt_inv, planes[4])
	# The is a placeholder for the plane index 5.

	var near_endpoint: Vector3 = near_plane.intersect_3(right_plane, top_plane)
	var far_endpoint: Vector3 = far_plane.intersect_3(right_plane, top_plane)

	return PackedVector2Array([Vector2(near_endpoint.x, near_endpoint.y), Vector2(far_endpoint.x, far_endpoint.y)])


func update_plane(p_lerp: float) -> void:
	var camera: Camera3D = get_parent()
	if camera:
		var sizes = camera_mesh_plane_const.get_endpoints_for_camera(camera)
		if sizes.size() > 0:
			var far = Vector2(sizes[0].x, sizes[0].y) * 2.0
			var near = Vector2(sizes[1].x, sizes[1].y) * 2.0

			var lerped_size: Vector2 = far.lerp(near, p_lerp)

			var z_near: float = camera.near
			var z_far: float = camera.far

			var lerp_position: float = lerpf(z_near, z_far, p_lerp)

			set_transform(
				Transform3D(
					Basis.from_euler(Vector3(PI * 0.5, 0.0, 0.0)).scaled(Vector3(lerped_size.x, lerped_size.y, 1.0)),
					Vector3(0.0, 0.0, -lerp_position)
				)
			)


func set_distance(p_distance: float) -> void:
	distance = p_distance
	update_plane(distance)


func _ready() -> void:
	var unshaded: StandardMaterial3D = StandardMaterial3D.new()
	unshaded.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	update_plane(distance)
