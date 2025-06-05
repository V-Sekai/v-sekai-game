@tool
extends RefCounted
class_name SarScriptUtilities

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
