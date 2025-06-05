@tool
extends Node
class_name SarConnectionUtilities

## This class contains helper functions designed for dealing with signal
## connections.

## Returns a PackedStringArray for all the p_callables on p_node which don't
## have incoming connection assigned to them.
static func get_warnings_for_missing_incoming_connections(p_node: Node, p_callables: Array[Callable]) -> PackedStringArray:
	var warnings: PackedStringArray = []
	var incoming_connections: Array[Dictionary] = p_node.get_incoming_connections()
	var missing_callables: Array[Callable] = p_callables.duplicate()
	for conn: Dictionary in incoming_connections:
		var callable: Callable = conn["callable"]
		if p_callables.has(callable):
			if missing_callables.has(callable):
				missing_callables.erase(callable)
			
	for missing_callable: Callable in missing_callables:
		warnings.push_back("No signal is connected to %s." % missing_callable.get_method())
		
	return warnings
