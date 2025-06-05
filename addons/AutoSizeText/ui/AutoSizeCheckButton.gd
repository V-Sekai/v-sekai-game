@tool
class_name AutoSizeCheckButton
extends CheckButton

signal text_changed(old_text: String, new_text: String)

## Since it is not possible to override existing variables in gdscript,
## this needs to be a dirty workaround
@export_multiline
var button_text: String = "":
	get:
		return button_text
	set(value):
		button_text = value
		
		notify_property_list_changed()
		_sync_label()
		_update_label()
		
		if not Engine.is_editor_hint() and _label != null:
			text_changed.emit(_label.text, button_text)

@export_tool_button("FORCE REFRESH")
var refresh_button: Callable = _update_label

@export_group("Auto Font Size")

## Min text size to reach
@export_range(1, 512, 1.0)
var min_font_size: int = 8:
	get:
		return min_font_size
	set(value):
		min_font_size = value
		if min_font_size >= max_font_size:
			min_font_size = max_font_size - 1
			push_warning(
				"min_font_size {0} >= max_font_size {1}, fixed to {2}"
				.format([value, max_font_size, min_font_size])
			)

		notify_property_list_changed()
		_sync_label()
		_update_label()

## Max text size to reach
@export_range(1, 512, 1.0)
var max_font_size: int = 38:
	get:
		return max_font_size
	set(value):
		max_font_size = value
		if max_font_size <= min_font_size:
			max_font_size = min_font_size + 1
			push_warning(
				"max_font_size {0} <= min_font_size {1}, fixed to {2}"
				.format([value, min_font_size, max_font_size])
			)

		notify_property_list_changed()
		_sync_label()
		_update_label()

@export_group("Step Size")

## Needs 2 numbers to work / will be automatically prefered over "Auto-Size"[br]
## when 2 numbers or more are present.
@export
var step_sizes: Array[int] = []:
	get:
		return step_sizes
	set(value):
		step_sizes = value
		step_sizes.sort()

		notify_property_list_changed()
		_sync_label()
		_update_label()


var _processing_flag: bool = false
var _label: AutoSizeLabel
var _saved_theme_colors: Dictionary[String, Color]


func _ready() -> void:
	# TODO: change defaults instead of hard-setting!

	# smalles possible font to force the button smallest size
	set(&"theme_override_font_sizes/font_size", 1)
	_prepare_colors()

	clip_text = true
	
	if _label == null:
		_label = AutoSizeLabel.new()
		_label.force_default_settings()
		add_child(_label)
		_label.size = Vector2(size.x - _get_biggest_check_icon_size().x - _get_icon_space(), size.y)
		_label.horizontal_alignment = alignment
		_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_label.set_anchors_preset(PRESET_FULL_RECT)
		
	_sync_label()
	_update_label()


func _sync_label() -> void:
	if _label == null:
		return
		
	_label.min_font_size = min_font_size
	_label.max_font_size = max_font_size
	_label.step_sizes = step_sizes


func _update_label() -> void:
	if _label == null:
		return
	
	_label.text = button_text
	# TODO: detect current button state to pass on the color
	_sync_color("font_color")
	_label.do_resize_text()
	
	if Engine.is_editor_hint() and text != "":
		push_warning(
			"The AutoSizeButton '%s' has the text '%s'. Please set the text to 'button_text' instead of the text property."
			 % [name, text]
		)


func _prepare_colors():
	const colors_to_disable: Array[String] = [
		"font_color",
		"font_disabled_color",
		"font_hover_pressed_color",
		"font_hover_color",
	 	"font_focus_color",
		"font_pressed_color",
	]
	
	for color_name in colors_to_disable:
		# TODO: get_theme_color always returns (0, 0, 0, 0), WHY?
		_saved_theme_colors[color_name] = get_theme_color(color_name, "Button")
		
		# theme-overriding in editor will save the changes and break on scene reload
		if not Engine.is_editor_hint():
			set("theme_override_colors/" + color_name, Color(0, 0, 0, 0))


func _sync_color(color_type: String) -> void:
	var theme_color: Color = _saved_theme_colors[color_type] #get_theme_color(color_type, "Button")
	_label.set(&"theme_override_colors/font_color", theme_color)


func _get_biggest_check_icon_size() -> Vector2:
	const icons_to_check: Array[String] = [
		"icon",
		"checked",
		"unchecked",
		"checked_disabled",
		"unchecked_disabled",
		"checked_mirrored",
		"unchecked_mirrored",
		"checked_disabled_mirrored",
		"unchecked_disabled_mirrored"
	]
	
	var biggest_size: Vector2 = Vector2(0 , 0)
	
	for icon_name in icons_to_check:
		var theme_icon = get("theme_override_icons/" + icon_name)
		if theme_icon == null:
			continue

		if theme_icon.size.x > biggest_size.x:
			biggest_size = theme_icon.size
	
	for icon_name in icons_to_check:
		var theme_icon: Texture2D = get_theme_icon(icon_name, "CheckButton")
		if theme_icon == null:
			continue

		if theme_icon.get_size().x > biggest_size.x:
			biggest_size = theme_icon.get_size()
	
	return biggest_size


func _get_icon_space() -> int:
	var margin: int = 0
	margin = get_theme_constant("h_separation", "CheckButton")
	
	var stylebox = get_theme_stylebox("normal", "CheckButton")
	margin += stylebox.get_margin(SIDE_LEFT)
	margin += stylebox.get_margin(SIDE_RIGHT)
	
	return margin
