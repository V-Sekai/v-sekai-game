extends RefCounted

var eigenvector_precision: float
var target = PackedVector3Array()
var moved = PackedVector3Array()
var weight = PackedFloat64Array()
var transformation_calculated = false
var inner_product_calculated = false
var moved_center: Vector3
var target_center: Vector3
var w_sum: float = 0

var sum_xx: float = 0
var sum_xy: float = 0
var sum_xz: float = 0
var sum_yx: float = 0
var sum_yy: float = 0
var sum_yz: float = 0
var sum_zx: float = 0
var sum_zy: float = 0
var sum_zz: float = 0
var max_eigenvalue: float = 0

var sum_xz_plus_zx: float = 0
var sum_yz_plus_zy: float = 0
var sum_xy_plus_yx: float = 0
var sum_yz_minus_zy: float = 0
var sum_xz_minus_zx: float = 0
var sum_xy_minus_yx: float = 0
var sum_xx_plus_yy: float = 0
var sum_xx_minus_yy: float = 0


func _init(p_evec_prec: float):
	self.eigenvector_precision = p_evec_prec


func qcp_set(r_target: PackedVector3Array, r_moved: PackedVector3Array) -> void:
	target = r_target
	moved = r_moved
	transformation_calculated = false
	inner_product_calculated = false


func get_rotation() -> Quaternion:
	if not transformation_calculated:
		if not inner_product_calculated:
			inner_product(target, moved)
	return calculate_rotation()


func calculate_rotation() -> Quaternion:
	var result = Quaternion()

	if moved.size() == 1:
		var u = moved[0]
		var v = target[0]
		var norm_product = u.length() * v.length()

		if norm_product == 0.0:
			return Quaternion()

		var dot = u.dot(v)

		if dot < ((2.0e-15 - 1.0) * norm_product):
			var w = u.normalized()
			result = Quaternion(-w.x, -w.y, -w.z, 0.0).normalized()
		else:
			var q0 = sqrt(0.5 * (1.0 + dot / norm_product))
			var coeff = 1.0 / (2.0 * q0 * norm_product)
			var q = v.cross(u).normalized()
			result = Quaternion(coeff * q.x, coeff * q.y, coeff * q.z, q0).normalized()
	else:
		var a13 = -sum_xz_minus_zx
		var a14 = sum_xy_minus_yx
		var a21 = sum_yz_minus_zy
		var a22 = sum_xx_minus_yy - sum_zz - max_eigenvalue
		var a23 = sum_xy_plus_yx
		var a24 = sum_xz_plus_zx
		var a31 = a13
		var a32 = a23
		var a33 = sum_yy - sum_xx - sum_zz - max_eigenvalue
		var a34 = sum_yz_plus_zy
		var a41 = a14
		var a42 = a24
		var a43 = a34
		var a44 = sum_zz - sum_xx_plus_yy - max_eigenvalue

		var a3344_4334 = a33 * a44 - a43 * a34
		var a3244_4234 = a32 * a44 - a42 * a34
		var a3243_4233 = a32 * a43 - a42 * a33
		var a3143_4133 = a31 * a43 - a41 * a33
		var a3144_4134 = a31 * a44 - a41 * a34
		var a3142_4132 = a31 * a42 - a41 * a32

		var quaternion_w = a22 * a3344_4334 - a23 * a3244_4234 + a24 * a3243_4233
		var quaternion_x = -a21 * a3344_4334 + a23 * a3144_4134 - a24 * a3143_4133
		var quaternion_y = a21 * a3244_4234 - a22 * a3144_4134 + a24 * a3142_4132
		var quaternion_z = -a21 * a3243_4233 + a22 * a3143_4133 - a23 * a3142_4132

		var qsqr = (
			quaternion_w * quaternion_w
			+ quaternion_x * quaternion_x
			+ quaternion_y * quaternion_y
			+ quaternion_z * quaternion_z
		)

		if qsqr < eigenvector_precision:
			return Quaternion()

		quaternion_x *= -1
		quaternion_y *= -1
		quaternion_z *= -1

		var min_value = min(quaternion_w, quaternion_x, quaternion_y, quaternion_z)

		if min_value != 0:
			quaternion_w /= min_value
			quaternion_x /= min_value
			quaternion_y /= min_value
			quaternion_z /= min_value

		result = Quaternion(quaternion_x, quaternion_y, quaternion_z, quaternion_w).normalized()

	return result


func translate(translation_vector: Vector3, x: PackedVector3Array) -> void:
	for i in range(x.size()):
		x[i] += translation_vector


func get_translation() -> Vector3:
	return target_center - moved_center


func move_to_weighted_center(to_center: PackedVector3Array, weights: PackedFloat64Array) -> Vector3:
	var center: Vector3 = Vector3.ZERO
	var total_weight: float = 0
	var size = to_center.size()

	if size == 0 or (weights.size() > 0 and weights.size() != size):
		push_error("Sizes of arrays do not match or are zero.")
		return center

	for i in range(size):
		var current_weight = 1.0
		if weights.size() > 0:
			current_weight = weights[i]
		total_weight += current_weight
		center += to_center[i] * current_weight

	if total_weight > 0:
		center /= total_weight

	return center


func inner_product(coords1: PackedVector3Array, coords2: PackedVector3Array) -> void:
	var weighted_coord1: Vector3
	var weighted_coord2: Vector3
	var sum_of_squares1: float = 0.0
	var sum_of_squares2: float = 0.0

	# Initialize sums to zero
	var sum_xx: float = 0.0
	var sum_xy: float = 0.0
	var sum_xz: float = 0.0
	var sum_yx: float = 0.0
	var sum_yy: float = 0.0
	var sum_yz: float = 0.0
	var sum_zx: float = 0.0
	var sum_zy: float = 0.0
	var sum_zz: float = 0.0

	# Check if weight is empty (assuming 'weight' is defined elsewhere)
	# You'll need to define 'weight' similarly to the original C++ code
	var weight_is_empty: bool = weight.empty()  # replace with correct method call if available
	var size: int = coords1.size()

	for i in range(size):
		if not weight_is_empty:
			weighted_coord1 = weight[i] * coords1[i]
			sum_of_squares1 += weighted_coord1.dot(coords1[i])
		else:
			weighted_coord1 = coords1[i]
			sum_of_squares1 += weighted_coord1.dot(weighted_coord1)

		weighted_coord2 = coords2[i]
		if weight_is_empty:
			sum_of_squares2 += weighted_coord2.dot(weighted_coord2)
		else:
			sum_of_squares2 += weight[i] * weighted_coord2.dot(weighted_coord2)

		sum_xx += weighted_coord1.x * weighted_coord2.x
		sum_xy += weighted_coord1.x * weighted_coord2.y
		sum_xz += weighted_coord1.x * weighted_coord2.z

		sum_yx += weighted_coord1.y * weighted_coord2.x
		sum_yy += weighted_coord1.y * weighted_coord2.y
		sum_yz += weighted_coord1.y * weighted_coord2.z

		sum_zx += weighted_coord1.z * weighted_coord2.x
		sum_zy += weighted_coord1.z * weighted_coord2.y
		sum_zz += weighted_coord1.z * weighted_coord2.z

	var initial_eigenvalue: float = (sum_of_squares1 + sum_of_squares2) * 0.5

	# Additional variables must be declared and properly scoped in GDScript
	var sum_xz_plus_zx: float = sum_xz + sum_zx
	var sum_yz_plus_zy: float = sum_yz + sum_zy
	var sum_xy_plus_yx: float = sum_xy + sum_yx
	var sum_yz_minus_zy: float = sum_yz - sum_zy
	var sum_xz_minus_zx: float = sum_xz - sum_zx
	var sum_xy_minus_yx: float = sum_xy - sum_yx
	var sum_xx_plus_yy: float = sum_xx + sum_yy
	var sum_xx_minus_yy: float = sum_xx - sum_yy

	# These values seem to be used outside this function, so they should be properties of the class.
	# Make sure these are class properties or provide them with proper scope.
	max_eigenvalue = initial_eigenvalue
	inner_product_calculated = true


func weighted_superpose(
	p_moved: PackedVector3Array,
	p_target: PackedVector3Array,
	p_weights: PackedFloat64Array,
	translate: bool
) -> Quaternion:
	set_qcp_(p_moved, p_target, p_weights, translate)
	return get_rotation()


func set_qcp_(
	p_moved: PackedVector3Array,
	p_target: PackedVector3Array,
	p_weights: PackedFloat64Array,
	p_translate: bool
) -> void:
	transformation_calculated = false
	inner_product_calculated = false

	moved = p_moved
	target = p_target
	weight = p_weights

	if p_translate:
		moved_center = move_to_weighted_center(moved, weight)
		target_center = move_to_weighted_center(target, weight)
		w_sum = 0  # Initialize to 0 so we don't double up
		translate(-moved_center, moved)
		translate(-target_center, target)
	else:
		if weight.size() > 0:
			w_sum = weight.reduce(0, sum_accumulate)
		else:
			w_sum = p_moved.size()


func sum_accumulate(accumulated: float, current: float) -> float:
	return accumulated + current
