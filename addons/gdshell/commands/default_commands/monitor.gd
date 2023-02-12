extends GDShellCommand


func _main(p_argv: Array, p_data) -> Dictionary:
	var data: Dictionary = {
		"ms_per_frame": 1000.0 / Performance.get_monitor(Performance.TIME_FPS),
		"frames_per_second": Performance.get_monitor(Performance.TIME_FPS),
		"physics_frames_per_second": Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS),
		"render_total_objects_in_frame": Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
		"render_draw_calls_in_frame": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		"render_primitives_in_frame": Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
		"memory_static_kilobytes": ceil(Performance.get_monitor(Performance.MEMORY_STATIC) * 0.001),
		"memory_max_kilobytes": ceil(Performance.get_monitor(Performance.MEMORY_STATIC_MAX) * 0.001),
		"object_count": Performance.get_monitor(Performance.OBJECT_COUNT),
		"object_node_count": Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT),
		"physics_3d_active_objects": Performance.get_monitor(Performance.PHYSICS_3D_ACTIVE_OBJECTS),
		"physics_3d_collision_pairs": Performance.get_monitor(Performance.PHYSICS_3D_COLLISION_PAIRS),
		"physics_3d_island_count": Performance.get_monitor(Performance.PHYSICS_3D_ISLAND_COUNT),
		"physics_2d_active_objects": Performance.get_monitor(Performance.PHYSICS_2D_ACTIVE_OBJECTS),
		"physics_2d_collision_pairs": Performance.get_monitor(Performance.PHYSICS_2D_COLLISION_PAIRS),
		"physics_2d_island_count": Performance.get_monitor(Performance.PHYSICS_2D_ISLAND_COUNT),
		"video_memory_used": ceil(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) * 0.001),
		"texture_memory_used": ceil(Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) * 0.001),
	}
	if not p_argv.size() > 1:
		output(data)
		return {"data": data}	
	var command_name: String = p_argv[1]
	var keys = data.keys()
	if command_name == "list":
		output(keys)
		return {"data": keys}
	if data.keys().has(command_name):
		var out = data[command_name]
		output(out)
		return {"data": out}
	return DEFAULT_COMMAND_RESULT
