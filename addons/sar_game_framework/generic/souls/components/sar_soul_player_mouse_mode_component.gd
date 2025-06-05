@tool
extends Node
class_name SarSoulPlayerMouseModeComponent

## A component attached to a SarSoul responsible for changing the global
## mouse_mode.

func _change_mouse_mode(p_mouse_mode: Input.MouseMode):
	if not Engine.is_editor_hint() and is_multiplayer_authority():
		Input.mouse_mode = p_mouse_mode

# I'm not sure how we can detect when the signal state has changed.
func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = SarConnectionUtilities.get_warnings_for_missing_incoming_connections(self, [_change_mouse_mode])
		
	return warnings
