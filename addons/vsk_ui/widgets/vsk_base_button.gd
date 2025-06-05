@tool
class_name VSKBaseButton
extends BaseButton

const _BORDER_SIZE: float = 8.0

func _update_text() -> void:
	for label in _labels:
		if label:
			label.text = text
			update_minimum_size()

func _update_icons() -> void:
	for thumbnail_icon_texture_rect: TextureRect in _thumbnail_icons_texture_rects:
		if thumbnail_icon_texture_rect:
			thumbnail_icon_texture_rect.set_texture(icon)

@export_group("Internal Nodes")
@export var _background: Panel = null
@export var _button_drop_shadow: Panel = null
@export var _thumbnail_backgrounds: Array[Panel] = []
@export var _thumbnail_icons_texture_rects: Array[TextureRect] = []:
	set(p_thumbnail_icons_texture_rects):
		_thumbnail_icons_texture_rects = p_thumbnail_icons_texture_rects
		_update_icons()
@export var _labels: Array[Label] = []:
	set(p_labels):
		_labels = p_labels
		_update_text()
@export var _vertical_container: VBoxContainer = null
@export var _horizontal_container: HBoxContainer = null

@export var _image_containers: Array[Control] = []
@export var _text_containers: Array[Control] = []
@export var _url_texture: Control = null
@export_group("")

var _shadow_offset: Vector2 = Vector2()
var _thumbnail_background_stylebox: StyleBox = null
var _thumbnail_background_hover_stylebox: StyleBox = null
var _thumbnail_background_pressed_stylebox: StyleBox = null
var _background_stylebox: StyleBox = null
var _background_hover_stylebox: StyleBox = null
var _background_pressed_stylebox: StyleBox = null

func _validate_property(property: Dictionary) -> void:
	if Engine.is_editor_hint():
		if is_inside_tree():
			if owner == get_tree().edited_scene_root and property.name.begins_with("_"):
				property.usage = PROPERTY_USAGE_NO_EDITOR

func _get_border_size() -> Vector2:
	return Vector2(_BORDER_SIZE, _BORDER_SIZE)

func _get_minimum_size() -> Vector2:
	var minimum_size: Vector2 = Vector2(_get_border_size().x * 2, 0)
	#if _label:
	#	minimum_size += _label.get_size()

	return minimum_size

func _update_state() -> void:
	if not is_node_ready():
		await ready
	
	match get_draw_mode():
		DRAW_PRESSED:
			for thumbnail_background in _thumbnail_backgrounds:
				if thumbnail_background:
					thumbnail_background.set("theme_override_styles/panel", _thumbnail_background_pressed_stylebox)
			_background.set("theme_override_styles/panel", _background_pressed_stylebox)
		DRAW_HOVER_PRESSED:
			for thumbnail_background in _thumbnail_backgrounds:
				if thumbnail_background:
					thumbnail_background.set("theme_override_styles/panel", _thumbnail_background_pressed_stylebox)
			_background.set("theme_override_styles/panel", _background_pressed_stylebox)
		DRAW_HOVER:
			for thumbnail_background in _thumbnail_backgrounds:
				if thumbnail_background:
					thumbnail_background.set("theme_override_styles/panel", _thumbnail_background_hover_stylebox)
			_background.set("theme_override_styles/panel", _background_hover_stylebox)
		_:
			for thumbnail_background in _thumbnail_backgrounds:
				if thumbnail_background:
					thumbnail_background.set("theme_override_styles/panel", _thumbnail_background_stylebox)
			_background.set("theme_override_styles/panel", _background_stylebox)

	_button_drop_shadow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_button_drop_shadow.set_position(_shadow_offset)
	
	
	match display_mode:
		DisplayMode.VERTICAL:
			if _vertical_container:
				_vertical_container.show()
			if _horizontal_container:
				_horizontal_container.hide()
		DisplayMode.HORIZONTAL:
			if _vertical_container:
				_vertical_container.hide()
			if _horizontal_container:
				_horizontal_container.show()
		DisplayMode.NONE:
			if _vertical_container:
				_vertical_container.hide()
			if _horizontal_container:
				_horizontal_container.hide()

	for image_container in _image_containers:
		if image_container:
			if image_container.is_ancestor_of(_horizontal_container):
				image_container.size_flags_stretch_ratio = size.y / size.x
			
			if show_image_container:
				image_container.show()
			else:
				image_container.hide()
		
	for text_container in _text_containers:
		if text_container:
			if show_text_container:
				text_container.show()
			else:
				text_container.hide()
		
func _update_theme() -> void:
	_shadow_offset.x = get_theme_constant("shadow_offset_x", "VSKButton")
	_shadow_offset.y = get_theme_constant("shadow_offset_y", "VSKButton")
	
	_background_stylebox = get_theme_stylebox("background", "VSKButton")
	_background_hover_stylebox = get_theme_stylebox("background_hover", "VSKButton")
	
	_thumbnail_background_stylebox = get_theme_stylebox("thumbnail_background", "VSKButton")
	_thumbnail_background_hover_stylebox = get_theme_stylebox("thumbnail_background_hover", "VSKButton")
	
	_update_state()

func _notification(p_what: int) -> void:
	match p_what:
		NOTIFICATION_THEME_CHANGED:
			_update_theme()
		NOTIFICATION_DRAW:
			_update_state()
		NOTIFICATION_RESIZED:
			_update_state()
			
#func _get_property_list() -> Array[Dictionary]:
#	print(super.get_property_list())
#	return super.get_property_list()
			

func _ready() -> void:
	#ignore_texture_size = true
	_update_theme()

###

enum DisplayMode {
	VERTICAL,
	HORIZONTAL,
	NONE
}

@export_multiline var text: String = "" :
	set(value):
		text = value
		_update_text()
		
@export var icon: Texture2D = null:
	set(p_icon):
		icon = p_icon
		_update_icons()
		
@export var url: String = "":
	set(p_url):
		url = p_url
		if not is_node_ready():
			await ready
		if _url_texture:
			_url_texture.textureUrl = url

@export var display_mode: DisplayMode = DisplayMode.VERTICAL:
	set(p_display_mode):
		display_mode = p_display_mode
		_update_state()
		
@export var show_image_container: bool = true:
	set(p_show_image_container):
		show_image_container = p_show_image_container
		_update_state()

@export var show_text_container: bool = true:
	set(p_show_text_container):
		show_text_container = p_show_text_container
		_update_state()
