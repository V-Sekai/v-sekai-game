@tool
# # # # # # # # # # # # # # # # # # # # # # # # # # #
# Twister
#
# AutoSize LineEdit.
# # # # # # # # # # # # # # # # # # # # # # # # # # #
class_name AutoSizeLineEdit
extends LineEdit

@export_tool_button("FORCE REFRESH")
var refresh_button: Callable = resize_text

@export_group("Auto Font Size")
## String value of the LineEdit.
##[br][br]
## Note: Changing text using this property won't emit the text_changed signal.
@export
var _text : String:
	set(new_text):
		_text = new_text
		if alignment == HORIZONTAL_ALIGNMENT_FILL and !_text.is_empty():
			# HACK: https://github.com/SpielmannSpiel/AutoSizeText/issues/3
			text = _text + " "
			return
		text = _text

## Min text size to reach
@export_range(1, 512)
var min_size: int = 8:
	set(new_min):
		min_size = min(max(1, new_min), max_size)
		if is_node_ready():
			resize_text()

## Max text size to reach
@export_range(1, 512)
var max_size: int = 38:
	set(new_max):
		max_size = max(min_size, min(new_max, 512))
		if is_node_ready():
			resize_text()

## Enable this if you have a focus theme with an overriding border margin modifier.
@export
var use_focus_theme : bool = false:
	set(use_focus):
		use_focus_theme = use_focus
		
		if use_focus:
			if !focus_entered.is_connected(update):
				focus_entered.connect(update)
			if !focus_exited.is_connected(update):
				focus_exited.connect(update)
		else:
			if focus_entered.is_connected(update):
				focus_entered.disconnect(update)
			if focus_exited.is_connected(update):
				focus_exited.disconnect(update)

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
		resize_text()


var _processing_flag: bool = false


func _set(property: StringName, _value: Variant) -> bool:
	if (
		property == &"text"
		or property == &"right_icon"
		or property == &"clear_button_enabled"
		or property == &"placeholder_text"
		or property == &"editable"
	):
		resize_text.call_deferred()

	return false


func _ready() -> void:
	if _text.is_empty() and !text.is_empty():
		# Onload handle transition from native LineEdit to AutoSizeLineEdit
		_text = text

	item_rect_changed.connect(update)

	# Process custom themes on focus
	if use_focus_theme:
		if !focus_entered.is_connected(update):
			focus_entered.connect(update)
		if !focus_exited.is_connected(update):
			focus_exited.connect(update)


func _validate_property(property: Dictionary) -> void:
	if property.name == &"text":
		property.usage = PROPERTY_USAGE_NONE


func update() -> void:
	set_process(true)


func _process(_delta: float) -> void:
	resize_text()
	set_process(false)


func resize_text() -> void:
	if _processing_flag:
		return

	_processing_flag = true

	# Taking custom char offset prevent text clip by rect
	const OFFSET_BY: String = "_"

	var font: Font = get(&"theme_override_fonts/font")
	var font_size: Vector2 = Vector2.ZERO
	var offset: float = 0

	#region kick_falls

	var current_text: String = text
	var use_clear_btn: bool = clear_button_enabled

	if current_text.is_empty():
		if placeholder_text.is_empty():
			return

		current_text = placeholder_text
		use_clear_btn = false

	if null == font:
		font = get_theme_default_font()

	var right_icon_size: float = 0.0

	if null != right_icon:
		# Assume native size
		right_icon_size = right_icon.get_size().x

	if use_clear_btn:
		var _clear: Texture2D = get(&"theme_override_icons/clear")
		if null == _clear:
			_clear = get_theme_icon(&"clear")
		if _clear is Texture2D:
			right_icon_size += (_clear as Texture2D).get_size().x

	#endregion

	var rect_size : float = get_rect().size.x
	var current_theme : StyleBox = null

	if use_focus_theme:
		if has_focus():
			current_theme = get(&"theme_override_styles/focus")
			if current_theme == null:
				current_theme = get_theme_stylebox(&"focus")
		elif !editable:
			current_theme = get(&"theme_override_styles/read_only")
			if current_theme == null:
				current_theme = get_theme_stylebox(&"read_only")
		else:
			current_theme = get(&"theme_override_styles/normal")
			if current_theme == null:
				current_theme = get_theme_stylebox(&"normal")
	else:
		if !editable:
			current_theme = get(&"theme_override_styles/read_only")
			if current_theme == null:
				current_theme = get_theme_stylebox(&"read_only")
		else:
			current_theme = get(&"theme_override_styles/normal")
			if current_theme == null:
				current_theme = get_theme_stylebox(&"normal")

	if current_theme is StyleBoxFlat:
		rect_size -= current_theme.border_width_left
		rect_size -= current_theme.border_width_right
		rect_size -= current_theme.content_margin_left
		rect_size -= current_theme.content_margin_right
	elif current_theme is StyleBoxTexture:
		rect_size -= current_theme.texture_margin_left
		rect_size -= current_theme.texture_margin_right
	elif current_theme is StyleBoxEmpty:
		rect_size -= current_theme.content_margin_left
		rect_size -= current_theme.content_margin_right

	for font_size_iterator : int in get_iterator():
		set(&"theme_override_font_sizes/font_size", font_size_iterator)

		font_size = font.get_string_size(
			current_text,
			alignment,
			-1,
			font_size_iterator,
			TextServer.JUSTIFICATION_NONE,
			TextServer.DIRECTION_AUTO,
			TextServer.ORIENTATION_HORIZONTAL
		)
		font_size.x += right_icon_size

		offset = font.get_string_size(
			OFFSET_BY,
			alignment,
			-1,
			font_size_iterator,
			TextServer.JUSTIFICATION_NONE,
			TextServer.DIRECTION_AUTO,
			TextServer.ORIENTATION_HORIZONTAL
		).x

		if not needs_resize(rect_size - offset, font_size.x):
			break

	set_deferred(&"_processing_flag", false)


func needs_resize(rect_size : float, font_size : float) -> bool:
	return rect_size < font_size


func get_iterator() -> Array:
	if len(step_sizes) >= 2:
		var clone: Array[int] = step_sizes.duplicate()
		clone.reverse()
		return clone

	if len(step_sizes) == 1:
		push_warning(name + " Step sizes needs at least 2 numbers to work")

	return range(max_size, min_size, -1)
