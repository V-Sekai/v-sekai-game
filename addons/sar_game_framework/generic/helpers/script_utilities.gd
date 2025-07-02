@tool
extends RefCounted
class_name SarUtils

## This class contains helper functions designed for dealing with scripts.

## Returns true if p_script is or inherits from p_base_inheritance_script.
static func does_script_inherit(
	p_script: Script,
	p_base_inheritance_script: Script) -> bool:
	var script: Script = p_script

	while 1:
		if script == p_base_inheritance_script:
			return true
		else:
			if script == null:
				break
			script = script.get_base_script()
			
	return false

static func is_falsy(value: Variant) -> bool:
	return not value

static func is_truthy(value: Variant) -> bool:
	return not not value

## Assert Utilities
## Improved 'assert()' functions to ensure passed statements with side-effects 
## are evaluated in exported releases too.
##
## WARNING: These functions won't pause execution in release builds.
## If required you MUST check return value and early exit,
## like "if not SarUtils.assert_ok(___, error_msg): return"';

## Returns true if first two parameters are equal, else prints error message
## and return false.
static func assert_equal(
	p_value: Variant,
	p_expected: Variant,
	p_error_msg: String = "'p_value' is not equal to 'p_expected'"
) -> bool:
	var result: bool = p_value == p_expected
	if not result:
		push_error("Assert Error: " + p_error_msg)
		# Editor debugger only
		print_stack()
		assert(result)
	return result

## Returns true if first parameter evaluates to 'true', else prints error message
## and return false.
static func assert_true(
	p_value: Variant,
	p_error_msg: String = "p_value is 'false'"
) -> bool:
	var result: bool = is_truthy(p_value)
	if not result:
		push_error("Assert Error: " + p_error_msg)
		# Editor debugger only
		print_stack()
		assert(result)
	return result

## Returns true if first parameter is not 'null', else prints error message
## and return false.
static func assert_exists(
	p_value: Variant,
	p_error_msg: String = "p_value is 'null'"
) -> bool:
	var result: bool = true
	if p_value == null:
		result = false
		push_error("Assert Error: " + p_error_msg)
		# Editor debugger only
		print_stack()
		assert(result)
	return result

## Returns true if first parameter is 'OK', else prints error message
## and return false.
static func assert_ok(
	p_value: Error,
	p_error_msg: String = ""
) -> bool:
	var result: bool = p_value == OK
	if not result:
		var error_msg = p_error_msg
		if error_msg == "":
			error_msg = "p_value is " + error_string(p_value)
		push_error("Assert Error: " + error_msg)
		# Editor debugger only
		print_stack()
		assert(result)
	return result
