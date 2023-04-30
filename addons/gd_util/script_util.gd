@tool


static func does_script_inherit(p_script: Script, p_base_inheritance_script: Script):
	var script: Script = p_script

	while 1:
		if script == p_base_inheritance_script:
			return true
		else:
			if script == null:
				return false

			script = script.get_base_script()


static func get_root_script(p_script: Script):
	var script: Script = p_script

	while 1:
		var base_script: Script = script.get_base_script()
		if base_script == null:
			return script
		script = base_script
