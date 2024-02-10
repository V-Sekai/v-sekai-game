# test_qcp.gd

extends "res://addons/gut/test.gd"

var epsilon = 0.00001

const qcp_const = preload("res://addons/many_bone_ik_script/qcp.gd")


func test_weighted_superpose():
	var qcp := qcp_const.new(epsilon)
	var expected := Quaternion(0, 0, sqrt(2) / 2, sqrt(2) / 2)
	var moved := PackedVector3Array([Vector3(4, 5, 6), Vector3(7, 8, 9), Vector3(1, 2, 3)])
	var target := moved.duplicate()

	for i in range(target.size()):
		target[i] = expected * target[i]

	var weight := [1.0, 1.0, 1.0]  # Equal weights
	var result := qcp.weighted_superpose(moved, target, weight, false)

	assert_almost_eq(result.x, expected.x, epsilon)
	assert_almost_eq(result.y, expected.y, epsilon)
	assert_almost_eq(result.z, expected.z, epsilon)
	assert_almost_eq(result.w, expected.w, epsilon)


func test_weighted_translation():
	var qcp := qcp_const.new(epsilon)
	var expected := Quaternion()
	var moved := PackedVector3Array([Vector3(4, 5, 6), Vector3(7, 8, 9), Vector3(1, 2, 3)])
	var target := moved.duplicate()
	var translation_vector := Vector3(1, 2, 3)

	for i in range(target.size()):
		target[i] = expected * (target[i] + translation_vector)

	var weight := [1.0, 1.0, 1.0]  # Equal weights
	var translate := true
	var result := qcp.weighted_superpose(moved, target, weight, translate)

	# Quaternion checks
	assert_almost_eq(result.x, expected.x, epsilon)
	assert_almost_eq(result.y, expected.y, epsilon)
	assert_almost_eq(result.z, expected.z, epsilon)
	assert_almost_eq(result.w, expected.w, epsilon)

	# Translation checks
	assert_eq(translate, true)
	var inverted_expected := expected.inverse()
	var translation_result := inverted_expected * qcp.get_translation()
	assert_almost_eq(translation_result.x, translation_vector.x, epsilon)
	assert_almost_eq(translation_result.y, translation_vector.y, epsilon)
	assert_almost_eq(translation_result.z, translation_vector.z, epsilon)


func test_weighted_translation_shortest_path():
	var qcp := qcp_const.new(epsilon)
	var expected := Quaternion(1, 2, 3, 4).normalized()
	var moved := PackedVector3Array([Vector3(4, 5, 6), Vector3(7, 8, 9), Vector3(1, 2, 3)])
	var target := moved.duplicate()
	var translation_vector := Vector3(1, 2, 3)

	for i in range(target.size()):
		target[i] = expected * (target[i] + translation_vector)

	var weight := [1.0, 1.0, 1.0]  # Equal weights
	var translate := true
	var result := qcp.weighted_superpose(moved, target, weight, translate)

	# Quaternion checks
	assert_almost_eq(result.x, expected.x, epsilon)
	assert_almost_eq(result.y, expected.y, epsilon)
	assert_almost_eq(result.z, expected.z, epsilon)
	assert_almost_eq(result.w, expected.w, epsilon)

	# Translation checks
	assert_eq(translate, true)

	var inverted_expected := expected.inverse()
	var translation_result := inverted_expected * qcp.get_translation()
	assert_almost_ne(translation_result.x, translation_vector.x, epsilon)
	assert_almost_ne(translation_result.y, translation_vector.y, epsilon)
	assert_almost_ne(translation_result.z, translation_vector.z, epsilon)
