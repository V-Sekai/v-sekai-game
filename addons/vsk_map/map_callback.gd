@tool
extends Node

enum { MAP_OK, MAP_FAILED, ROOT_IS_NULL, EXPORTER_NODE_LOADED, INVALID_NODE }


static func get_error_str(p_err: int) -> String:
	var error_str: String = "Unknown error!"
	match p_err:
		MAP_FAILED:
			error_str = "Generic map error! (complain to Saracen)"
		ROOT_IS_NULL:
			error_str = "Root node is null!"
		EXPORTER_NODE_LOADED:
			error_str = "Exporter not loaded!"
		INVALID_NODE:
			error_str = "Invalid node!"

	return error_str
