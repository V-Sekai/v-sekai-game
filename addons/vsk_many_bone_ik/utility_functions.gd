@tool
extends RefCounted


class SwingConeRadius:
	extends RefCounted
	var center: Vector2
	var cone_radius: float


static func get_initial_global_poses(skeleton: Skeleton3D) -> Dictionary:
	var initial_global_poses = {}
	for bone_i in range(skeleton.get_bone_count()):
		var bone_name = skeleton.get_bone_name(bone_i)
		initial_global_poses[bone_name] = skeleton.get_bone_global_pose(bone_i)
	return initial_global_poses

static func create_new_ik(skeleton: Skeleton3D, root: Node3D) -> ManyBoneIK3D:
	var new_ik: ManyBoneIK3D = ManyBoneIK3D.new()
	skeleton.add_child(new_ik, true)
	new_ik.skeleton_node_path = ".."
	new_ik.owner = root
	new_ik.iterations_per_frame = 10
	skeleton.reset_bone_poses()
	return new_ik

static func set_constraints(config: Dictionary, skeleton: Skeleton3D, new_ik: ManyBoneIK3D):
	if not skeleton or not new_ik:
		print("Invalid arguments provided to set_constraints.")
		return

	for bone_i in range(skeleton.get_bone_count()):
		var bone_name = skeleton.get_bone_name(bone_i)

		if not config.has(bone_name):
			continue

		var bone_config = config[bone_name]
		if bone_config.has("twist_angle_limits"):
			var twist: Vector2 = Vector2(deg_to_rad(bone_config["twist_angle_limits"][0]), deg_to_rad(bone_config["twist_angle_limits"][1]))
			new_ik.set_kusudama_twist(bone_i, twist)

		if bone_config.has("swing_constraints_spherical"):
			var cones: Array = bone_config["swing_constraints_spherical"]
			new_ik.set_kusudama_limit_cone_count(bone_i, cones.size())
			for cone_i in range(cones.size()):
				var cone = cones[cone_i]
				var center: Vector2 = cone[0]
				center = Vector2(deg_to_rad(center.x), deg_to_rad(center.y))
				new_ik.set_kusudama_limit_cone_center(bone_i, cone_i, spherical_to_cartesian(center))
				new_ik.set_kusudama_limit_cone_radius(bone_i, cone_i, deg_to_rad(cone[1]))

static func setup_targets(targets: Dictionary, skeleton: Skeleton3D, new_ik: ManyBoneIK3D):
	for target_name in targets.keys():
		var node_3d = Node3D.new()
		node_3d.name = target_name
		var bone_i = skeleton.find_bone(node_3d.name)
		var children: Array[Node] = skeleton.owner.find_children("*", "")
		var parent: Node = null
		for node in children:
			if str(node.name) == targets[target_name]:
				node.add_child(node_3d, true)
				node_3d.owner = skeleton.owner
				parent = node
				break
		node_3d.global_transform = (
			skeleton.global_transform.affine_inverse() * skeleton.get_bone_global_pose_no_override(bone_i)
		)
		node_3d.owner = new_ik.owner
		new_ik.set_pin_nodepath(bone_i, new_ik.get_path_to(node_3d))

static func get_bone_children(skeleton, parent_index):
	var children = []
	for i in range(skeleton.get_bone_count()):
		if skeleton.get_bone_parent(i) == parent_index:
			children.append(i)
			children.append_array(skeleton.get_bone_children(i))
	return children

static func remove_duplicates(array):
	var unique_elements = {}
	var result = []

	for element in array:
		if not unique_elements.has(element):
			unique_elements[element] = true
			result.append(element)

	return result
	

static func mirror_x(rotation):
	return Vector3(-rotation.x, rotation.y, rotation.z)

static func mirror_y(rotation):
	return Vector3(rotation.x, -rotation.y, rotation.z)

static func mirror_z(rotation):
	return Vector3(rotation.x, rotation.y, -rotation.z)
	
static func get_direction_message(transform_from: Transform3D, transform_to: Transform3D) -> String:
	var direction = transform_to.origin - transform_from.origin
	var rotation_adjustment = adjustment_rotation(transform_from.basis.get_euler(), transform_to.basis.get_euler())

	if direction.length() < 0.001 and rotation_adjustment.get_euler().length() < 0.001:
		return "None"
		
	var position_constants = {
		"Stay Centered": Vector3.ZERO,
		"Zoom In": Vector3.ONE,
		"Zoom Out": Vector3(INF, INF, INF),
		"Step Left": Vector3.LEFT,
		"Step Right": Vector3.RIGHT,
		"Move Up": Vector3.UP,
		"Move Down": Vector3.DOWN,
		"Step Forward": Vector3.FORWARD,
		"Step Backward": Vector3.BACK
	}

	var rotation_constants = {}
	for i in range(0, 360, 1):
		var angle_rad = i * PI / 180
		rotation_constants["Turn %s° Clockwise" % i] = Vector3(0, -angle_rad, 0)
		rotation_constants["Turn %s° Counterclockwise" % i] = Vector3(0, angle_rad, 0)
		rotation_constants["Tilt %s° Up" % i] = Vector3(-angle_rad, 0, 0)
		rotation_constants["Tilt %s° Down" % i] = Vector3(angle_rad, 0, 0)
		rotation_constants["Lean %s° Left" % i] = Vector3(0, 0, angle_rad)
		rotation_constants["Lean %s° Right" % i] = Vector3(0, 0, -angle_rad)

	rotation_constants["Align with X-axis"] = Vector3(PI / 2, 0, 0)
	rotation_constants["Align with Y-axis"] = Vector3(0, PI / 2, 0)
	rotation_constants["Align with Z-axis"] = Vector3(0, 0, PI / 2)

	var mirrored_rotations = {}

	for key in rotation_constants.keys():
		var rotation = rotation_constants[key]
		mirrored_rotations["Mirror X: " + key] = mirror_x(rotation)
		mirrored_rotations["Mirror Y: " + key] = mirror_y(rotation)
		mirrored_rotations["Mirror Z: " + key] = mirror_z(rotation)

	for key in mirrored_rotations.keys():
		rotation_constants[key] = mirrored_rotations[key]

	var closest_position_constant = ""
	var min_position_distance = INF

	for key in position_constants.keys():
		var distance = direction.distance_to(position_constants[key])
		if distance < min_position_distance:
			min_position_distance = distance
			closest_position_constant = key

	var closest_rotation_constant = ""
	var min_rotation_distance = INF

	for key in rotation_constants.keys():
		var distance = rotation_adjustment.get_euler().distance_to(rotation_constants[key])
		if distance < min_rotation_distance:
			min_rotation_distance = distance
			closest_rotation_constant = key

	return "%s | %s" % [closest_position_constant, closest_rotation_constant]


static func adjustment_rotation(from_vector: Vector3, to_vector: Vector3) -> Basis:
	var axis = from_vector.cross(to_vector)
	var angle = from_vector.angle_to(to_vector)
	if is_equal_approx(axis.length(), 0.0):
		axis = Vector3(0, 1, 0)
	else:
		axis = axis.normalized()
	return Basis(axis, angle)

static func print_bone_report(config, skeletons: Array[Node], targets, initial_global_poses):
	var num_bones_considered = 0
	var sum_squared_position_distances = 0.0
	var sum_squared_rotation_degrees = 0.0

	var max_position_distance = -1.0
	var bone_to_fix = ""

	for skeleton in skeletons:
		if skeleton == null:
			print("No Skeleton3D found.")
			continue

		var sorted_bone_indices = []

		sorted_bone_indices.append_array(skeleton.get_parentless_bones())

		for root_bone_index in sorted_bone_indices:
			sorted_bone_indices.append_array(get_bone_children(skeleton, root_bone_index))
		
		sorted_bone_indices = remove_duplicates(sorted_bone_indices)

		for bone_index in sorted_bone_indices:
			var bone_name = skeleton.get_bone_name(bone_index)
			if not initial_global_poses.has(bone_name):
				continue
			
			if not targets.has(bone_name) and not config.has(bone_name):
				continue

			num_bones_considered += 1

			var current_pose_global = skeleton.get_bone_global_pose(bone_index)
			var initial_pose_global = initial_global_poses[bone_name]

			var position_distance = initial_pose_global.origin.distance_to(current_pose_global.origin) * 1000  # Convert to mm
			var rotation_difference = (current_pose_global.basis.get_euler() - initial_pose_global.basis.get_euler()) * 180 / PI  # Convert to degrees

			var rotation_adjustment = adjustment_rotation(initial_pose_global.basis.get_euler(), current_pose_global.basis.get_euler())

			sum_squared_position_distances += position_distance * position_distance
			sum_squared_rotation_degrees += rotation_difference.length_squared()
			var comment: String
			if config != null and config.has(bone_name):
				var bone_constraint = config[bone_name]
				if bone_constraint != null and bone_constraint.keys().has("comment"):
					comment = bone_constraint["comment"]

			print("Bone: %s | Adjustment: %s | Comment: %s"  % [bone_name, get_direction_message(initial_pose_global, current_pose_global), comment])

			if position_distance > max_position_distance and position_distance != 0 and bone_to_fix.is_empty():
				max_position_distance = position_distance
				bone_to_fix = bone_name

	if num_bones_considered > 0:
		var rmse_position = sqrt(sum_squared_position_distances / num_bones_considered)
		var rmse_rotation = sqrt(sum_squared_rotation_degrees / num_bones_considered)
		print("RMSE Position: %.2fmm | RMSE Rotation: %.2f°" % [rmse_position, rmse_rotation])
		print("Bone to fix: %s with distance: %.2fmm" % [bone_to_fix, max_position_distance])


static func spherical_to_cartesian(altitude_azimuth: Vector2) -> Vector3:
	var azimuth = altitude_azimuth.x
	var altitude = altitude_azimuth.y
	var x = sin(altitude) * cos(azimuth)
	var y = sin(altitude) * sin(azimuth)
	var z = cos(altitude)
	return Vector3(x, y, z)


static func cartesian_to_spherical(cartesian: Vector3) -> Vector2:
	var x = cartesian.x
	var y = cartesian.y
	var z = cartesian.z

	var r = sqrt(x * x + y * y + z * z)
	var azimuth = atan2(y, x)
	var altitude = acos(z / r)

	return Vector2(azimuth, altitude)


static func calculate_version(config):
	var config_string = str(config)
	return str(hash(config_string))

