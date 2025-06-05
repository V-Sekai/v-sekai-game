@tool
extends Node
class_name VSKSoulPlayerCurtainComponent

## A player soul's curtain component is intended to control a GUI component
## which blanks out the screen when the soul is not possessing a vessel.

## The control which will be shown and hidden depending on the posession state.
@export var curtain: Control = null

###

func _on_possessed(p_vessel: SarGameEntityVessel3D) -> void:
	if not Engine.is_editor_hint() and is_multiplayer_authority():
		if not curtain:
			printerr("Curtain node was not assigned.")
			return
		
		if p_vessel:
			curtain.hide()
		else:
			curtain.show()

# I'm not sure how we can detect when the signal state has changed.
func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = SarConnectionUtilities.get_warnings_for_missing_incoming_connections(self, [_on_possessed])
		
	return warnings
