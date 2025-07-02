@tool
extends Node
class_name SarSimulationComponentFader

var _tween: Tween = null

func _fade_in_complete() -> void:
	if _tween:
		_tween.finished.disconnect(_fade_in_complete)
		_tween.kill()
	
	fade_in_complete.emit()

func _request_fade_in() -> void:
	if fade_overlay:
		fade_overlay.show()
		if _tween:
			_tween.kill()
			
		fade_overlay.color = Color.BLACK
		
		_tween = create_tween().bind_node(self).set_trans(Tween.TRANS_LINEAR)
		
		if not SarUtils.assert_ok(_tween.finished.connect(_fade_in_complete),
			"Could not connect signal '_tween.finished' to '_fade_in_complete'"):
			return
		
		_tween.tween_property(
			fade_overlay,
			"color", 
			Color(
				Color.BLACK.r,
				Color.BLACK.g,
				Color.BLACK.b,
				0.0),
			fade_in_time)

func _on_vessel_possession_changed(p_soul: SarSoul) -> void:
	if p_soul:
		if fade_overlay:
			fade_overlay.show()
			_request_fade_in()
	else:
		if fade_overlay:
			fade_overlay.hide()

###

## Emitted when the fade in has finished.
signal fade_in_complete

## The node responsible for drawing the fade.
@export var fade_overlay: ColorRect = null

## How long (in seconds) should it take to fade in.
@export var fade_in_time: float = 2.0
