@tool
extends Node

const build_constants_const = preload("build_constants.gd")

static func get_build_label() -> String:
	return build_constants_const.BUILD_DATE_STR + "\n" + build_constants_const.BUILD_LABEL
