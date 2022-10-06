@tool
extends Control

signal fade_complete(p_skipped)
signal color_changed(p_color)

var source_fade_color: Color = Color(0.0, 0.0, 0.0, 0.0)
var target_fade_color: Color = Color(0.0, 0.0, 0.0, 0.0)
var color: Color = Color(0.0, 0.0, 0.0, 0.0) :
	set = set_color


var tween: Tween = null

func set_color(p_color: Color) -> void:
	if color != p_color:
		color = p_color
		color_changed.emit(p_color)

func _tween_complete() -> void:
	print("GOT a finished signal!")
	fade_complete.emit(false)

func _reset_tween() -> void:
	if tween != null:
		tween.kill()
		tween = null
	color = target_fade_color

func execute_fade(p_start: Color, p_end: Color, p_time: float) -> void:
	_reset_tween()

	source_fade_color = p_start
	target_fade_color = p_end

	self.color = source_fade_color
	tween = get_tree().create_tween()
	assert(tween.finished.connect(self._tween_complete) == OK)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_LINEAR)
	assert(tween.tween_property(self, "color", target_fade_color, p_time) != null)
	# tween.play() not needed due to Autoplay.

func skip_fade() -> void:
	_reset_tween()

	fade_complete.emit(true)

func is_fading() -> bool:
	return tween.is_running()

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 0)
	set_focus_mode(FOCUS_NONE)
	set_mouse_filter(MOUSE_FILTER_IGNORE)

