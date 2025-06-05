@tool
# # # # # # # # # # # # # # # # # # # # # # # # # # #
# Twister
#
# AutoSize TextEdit.
# # # # # # # # # # # # # # # # # # # # # # # # # # #
class_name AutoSizeTextEdit
extends TextEdit

# Taking custom _char offset prevent text clip by rect
const OFFSET_BY: String = "_"

@export_tool_button("FORCE REFRESH")
var refresh_button: Callable = resize_text

## String value of the TextEdit.
@export_multiline
var _text: String = "":
	set(txt):
		_text = txt
		if auto_split_text:
			_split_txt()
		else:
			set(&"text", _text)

## Enable auto size text function.
@export
var enable_auto_resize: bool = true:
	set(value):
		enable_auto_resize = value
		if is_node_ready():
			set_deferred(&"_text", _text)

## This cut allows you to cut the string if the width limit is exceeded and works if the minimum size is reached.
@export
var auto_split_text: bool = false:
	set(value):
		auto_split_text = value
		if is_node_ready():
			set_deferred(&"_text", _text)

@export_group("Auto Font Size")

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
var use_focus_theme: bool = false:
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


## Set text to TextEdit with auto size function.
func set_auto_size_text(new_text: String) -> void:
	_text = new_text


## Get original text setted from TextEdit auto size.
func get_auto_size_text() -> String:
	return _text


func _validate_property(property: Dictionary) -> void:
	if property.name == &"text":
		property.usage = PROPERTY_USAGE_NONE


func _split_txt() -> void:
	if _text.is_empty():
		return

	var offset: float = 0.0
	var txt: PackedStringArray = _text.split('\n', true, 0)

	var character_size: int = get(&"theme_override_font_sizes/font_size")
	if character_size < 2 and character_size != min_size:
		character_size = max(min_size, min(16, max_size))

	var font: Font = get(&"theme_override_fonts/font")
	if null == font:
		font = get_theme_default_font()

	offset = size.x - font.get_string_size(
		OFFSET_BY,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		character_size,
		TextServer.JUSTIFICATION_NONE,
		TextServer.DIRECTION_AUTO,
		TextServer.ORIENTATION_HORIZONTAL
	).x

	var new_text: String = ""
	for character: String in txt:
		if character.is_empty():
			new_text += '\n'
			continue

		var size_offset: Vector2 = font.get_string_size(character, HORIZONTAL_ALIGNMENT_LEFT, -1, character_size, TextServer.JUSTIFICATION_NONE,TextServer.DIRECTION_AUTO,TextServer.ORIENTATION_HORIZONTAL)

		if offset < size_offset.x:
			var split: PackedStringArray  = character.split()
			var current_character: String = ""
			var final: String             = ""

			for _char: String in split:
				if "\n" == _char:
					final += current_character + _char
					current_character = ""
					continue

				size_offset = font.get_string_size(
					current_character + "- " + _char,
					HORIZONTAL_ALIGNMENT_LEFT,
					-1,
					character_size,
					TextServer.JUSTIFICATION_NONE,
					TextServer.DIRECTION_AUTO,
					TextServer.ORIENTATION_HORIZONTAL
				)

				if offset < size_offset.x:
					final += current_character + "- " + "\n" + _char
					current_character = ""
				else:
					current_character += _char

			new_text += '\n' + final + current_character
		else:
			new_text += '\n' + character

	set(&"text",new_text.strip_edges())


func _set(property: StringName, _value: Variant) -> bool:
	if property == &"text" or property == &"placeholder_text" or property == &"editable":
		resize_text.call_deferred()

	return false


func _ready() -> void:
	if _text.is_empty() and !text.is_empty():
		# Onload handle transition from native TextEdit to AutoSizeTextEdit
		_text = text

	item_rect_changed.connect(update)

	# Process custom themes on focus
	if use_focus_theme:
		if !focus_entered.is_connected(update):
			focus_entered.connect(update)
		if !focus_exited.is_connected(update):
			focus_exited.connect(update)

func update() -> void:
	set_process(true)

func _process(_delta: float) -> void:
	_text = _text
	set_process(false)


func resize_text() -> void:
	if _processing_flag:
		return

	_processing_flag = true

	if !enable_auto_resize:
		set(&"theme_override_font_sizes/font_size", max_size)
		set_deferred(&"_processing_flag", false)
		return

	var font: Font = get(&"theme_override_fonts/font")
	var iterator: Array = get_iterator()
	var font_size_x: float = 0.0
	var offset: float = iterator[0]

	#region kick_falls

	var use_placeholder: bool = false
	var current_text: String = text

	if current_text.is_empty():
		if placeholder_text.is_empty():
			return

		current_text = placeholder_text
		use_placeholder = true

	if null == font:
		font = get_theme_default_font()

	#endregion

	var txt: PackedStringArray = current_text.split('\n', true, 0)
	for character: String in txt:
		var size_offset: Vector2 = font.get_string_size(character, HORIZONTAL_ALIGNMENT_LEFT, -1, int(offset), TextServer.JUSTIFICATION_NONE,TextServer.DIRECTION_AUTO,TextServer.ORIENTATION_HORIZONTAL)
		font_size_x = maxf(font_size_x, size_offset.x)

	offset = size.x - font.get_string_size(OFFSET_BY, HORIZONTAL_ALIGNMENT_LEFT, -1, int(offset), TextServer.JUSTIFICATION_NONE,TextServer.DIRECTION_AUTO,TextServer.ORIENTATION_HORIZONTAL).x

	if use_placeholder:
		# HACK: Lines updated response by text only
		text = placeholder_text

	var margin: float = 0.0
	var current_theme: StyleBox = null

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
		margin += current_theme.border_width_left
		margin += current_theme.border_width_right
		margin += current_theme.content_margin_left
		margin += current_theme.content_margin_right
	elif current_theme is StyleBoxTexture:
		margin += current_theme.texture_margin_left
		margin += current_theme.texture_margin_right
	elif current_theme is StyleBoxEmpty:
		margin += current_theme.content_margin_left
		margin += current_theme.content_margin_right

	offset -= margin

	for font_size_iterator: int in iterator:
		# Refresh rect
		set(&"theme_override_font_sizes/font_size", font_size_iterator)

		font_size_x = 0.0
		for character: String in txt:
			var size_offset: Vector2 = font.get_string_size(character, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size_iterator, TextServer.JUSTIFICATION_NONE,TextServer.DIRECTION_AUTO,TextServer.ORIENTATION_HORIZONTAL)
			font_size_x = maxf(font_size_x, size_offset.x)

		offset = size.x - font.get_string_size(OFFSET_BY, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size_iterator, TextServer.JUSTIFICATION_NONE,TextServer.DIRECTION_AUTO,TextServer.ORIENTATION_HORIZONTAL).x - margin

		if not needs_resize(offset < font_size_x):
			break

	if use_placeholder:
		# Restore
		text = ""

	set_deferred(&"_processing_flag", false)

func needs_resize(font_size: float) -> bool:
	return font_size or get_line_count() > get_visible_line_count()

func get_iterator() -> Array:
	if len(step_sizes) >= 2:
		var clone: Array[int] = step_sizes.duplicate()
		clone.reverse()
		return clone

	if len(step_sizes) == 1:
		push_warning(name + " Step sizes needs at least 2 numbers to work")

	return range(max_size, min_size, -1)
