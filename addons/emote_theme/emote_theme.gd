# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# emote_theme.gd
# SPDX-License-Identifier: MIT

@tool
extends Node
class_name EmoteTheme

const DEFAULT_CONTRAST = 0.25
const DEFAULT_BOX_CONTAINER_SEPERATION = 4

const WINDOW_TITLEBAR = 26

const DEFAULT_MARGIN_SIZE = 8
const DEFAULT_FONT_SIZE = 16

const EMOTE_PRIMARY_COLOR = Color("#731C1C")
var EMOTE_PRIMARY_COLOR_BRIGHT = generate_color(EMOTE_PRIMARY_COLOR, 1.1)
var EMOTE_PRIMARY_COLOR_DARK = generate_color(EMOTE_PRIMARY_COLOR, 0.5)
const EMOTE_SECONDARY_COLOR = Color("#F6F4F2")
var EMOTE_SECONDARY_COLOR_DARK = generate_color(EMOTE_SECONDARY_COLOR, 0.5)

const DEFAULT_BASE_COLOR = EMOTE_SECONDARY_COLOR
const DEFAULT_BG_COLOR = EMOTE_SECONDARY_COLOR
var DEFAULT_DISABLED_BG_COLOR = EMOTE_PRIMARY_COLOR_DARK
const DEFAULT_DISABLED_BORDER_COLOR = Color(0.0, 0.0, 0.0, 0.0)

const DEFAULT_WIDGET_COLOR = EMOTE_SECONDARY_COLOR
const DEFAULT_WIDGET_COLOR_INVERSE = EMOTE_PRIMARY_COLOR
const DEFAULT_WIDGET_BORDER_COLOR = EMOTE_PRIMARY_COLOR
const DEFAULT_WIDGET_FONT_COLOR = EMOTE_PRIMARY_COLOR
const DEFAULT_WIDGET_FONT_COLOR_INVERSE = EMOTE_SECONDARY_COLOR

const DEFAULT_FONT_COLOR = EMOTE_PRIMARY_COLOR
var DEFAULT_FONT_COLOR_HL = EMOTE_PRIMARY_COLOR_BRIGHT
const DEFAULT_FONT_COLOR_DISABLED = Color("#ffffff4d")
var DEFAULT_ACCENT_COLOR = EMOTE_PRIMARY_COLOR_DARK
const DEFAULT_FONT_COLOR_SELECTION = EMOTE_PRIMARY_COLOR
const DEFAULT_FONT_COLOR_HIGHLIGHT = EMOTE_PRIMARY_COLOR


static func make_stylebox(p_texture, p_left, p_top, p_right, p_botton, p_scale, p_margin_left = -1, p_margin_top = -1, p_margin_right = -1, p_margin_botton = -1, p_draw_center = true) -> StyleBoxTexture:
	var style = StyleBoxTexture.new()
	style.set_texture(p_texture)
	style.content_margin_left = p_left * p_scale
	style.content_margin_right = p_left * p_scale
	style.content_margin_bottom = p_left * p_scale
	style.content_margin_top = p_left * p_scale
	style.set_draw_center(p_draw_center)
	return style


static func make_empty_stylebox(p_scale, p_margin_left = -1, p_margin_top = -1, p_margin_right = -1, p_margin_bottom = -1) -> StyleBoxEmpty:
	var style = StyleBoxEmpty.new()
	style.content_margin_left = p_margin_left * p_scale
	style.content_margin_right = p_margin_right * p_scale
	style.content_margin_bottom = p_margin_bottom * p_scale
	style.content_margin_top = p_margin_top * p_scale
	return style


static func make_flat_stylebox(p_color: Color, p_scale: float, p_margin_left: float = -1.0, p_margin_top: float = -1.0, p_margin_right: float = -1.0, p_margin_bottom: float = -1.0) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.set_bg_color(p_color)
	style.content_margin_left = p_margin_left * p_scale
	style.content_margin_right = p_margin_right * p_scale
	style.content_margin_bottom = p_margin_bottom * p_scale
	style.content_margin_top = p_margin_top * p_scale
	return style


static func make_line_stylebox(p_color: Color, p_scale: float, p_thickness: float = 1.0, p_grow: float = 1.0, p_vertical: bool = false) -> StyleBoxLine:
	var style = StyleBoxLine.new()
	style.set_color(p_color)
	style.set_grow_begin(p_grow)
	style.set_grow_end(p_grow)
	style.set_thickness(p_thickness)
	style.set_vertical(p_vertical)
	return style


static func create_font(p_data: Font, p_scale: float, p_fallback: Array = []) -> Font:
	var font = FontVariation.new()
	font.set_base_font(p_data)
	font.spacing_top = -p_scale
	font.spacing_bottom = -p_scale
	var fallbacks: Array = []
	for fallback in p_fallback:
		#font.add_fallback(fallback)
		fallbacks.append(fallback)
	font.fallbacks = fallbacks

	ResourceSaver.save(font, "res://addons/emote_theme/fonts/default_regular_font.tres")

	return font


static func generate_color(base_color: Color, multiplier: float) -> Color:
	var new_color = Color(clamp(base_color.r * multiplier, 0, 1), clamp(base_color.g * multiplier, 0, 1), clamp(base_color.b * multiplier, 0, 1), base_color.a)
	return new_color


static func register_font(p_theme: Theme, p_scale: float) -> Font:
	var default_regular_font_data: Font = load("res://addons/emote_theme/fonts/roboto_mono_regular.ttf")

	var default_regular_font: Font = create_font(default_regular_font_data, p_scale)
	p_theme.set_default_font(default_regular_font)

	return default_regular_font


# Rudimentary approach - deal with a more sophisticated DPI system in the future
# FIXME: This doesn't use scale, and seems to be arbitrarily used to load StyleBox and Texture2D resources.
static func load_scaled_image(p_path: String, p_scale: float) -> Resource:
	return load(p_path)


func generate_emote_theme(p_theme_class, p_scale: float) -> Theme:
	var theme: Theme = p_theme_class.new()

	# Icons
	var icon_empty = load_scaled_image("res://addons/emote_theme/icons/icon_empty.svg", 1.0)

	var icon_add = load_scaled_image("res://addons/emote_theme/icons/icon_add.svg", p_scale)
	var icon_arrow_left = load_scaled_image("res://addons/emote_theme/icons/icon_arrow_left.svg", p_scale)
	var icon_arrow_right = load_scaled_image("res://addons/emote_theme/icons/icon_arrow_right.svg", p_scale)
	var icon_arrow_up = load_scaled_image("res://addons/emote_theme/icons/icon_arrow_up.svg", p_scale)
	var icon_color_pick = load_scaled_image("res://addons/emote_theme/icons/icon_color_pick.svg", p_scale)
	var icon_folder = load_scaled_image("res://addons/emote_theme/icons/icon_folder.svg", p_scale)
	var icon_snap_grid = load_scaled_image("res://addons/emote_theme/icons/icon_snap_grid.svg", p_scale)
	var icon_zoom_less = load_scaled_image("res://addons/emote_theme/icons/icon_zoom_less.svg", p_scale)
	var icon_zoom_more = load_scaled_image("res://addons/emote_theme/icons/icon_zoom_more.svg", p_scale)
	var icon_zoom_reset = load_scaled_image("res://addons/emote_theme/icons/icon_zoom_reset.svg", p_scale)

	var icon_gui_option_arrow = load_scaled_image("res://addons/emote_theme/icons/icon_gui_option_arrow.svg", p_scale)
	var icon_gui_toggle_on = load_scaled_image("res://addons/emote_theme/icons/icon_gui_toggle_on.svg", p_scale)
	var icon_gui_toggle_off = load_scaled_image("res://addons/emote_theme/icons/icon_gui_toggle_off.svg", p_scale)
	var icon_gui_tab_menu = load_scaled_image("res://addons/emote_theme/icons/icon_gui_tab_menu.svg", p_scale)
	var icon_gui_close = load_scaled_image("res://addons/emote_theme/icons/icon_gui_close.svg", p_scale)
	var icon_gui_close_customizable = load_scaled_image("res://addons/emote_theme/icons/icon_gui_close_customizable.svg", p_scale)
	var icon_gui_checked = load_scaled_image("res://addons/emote_theme/icons/icon_gui_checked.svg", p_scale)
	var icon_gui_unchecked = load_scaled_image("res://addons/emote_theme/icons/icon_gui_unchecked.svg", p_scale)
	var icon_gui_radio_checked = load_scaled_image("res://addons/emote_theme/icons/icon_gui_radio_checked.svg", p_scale)
	var icon_gui_radio_unchecked = load_scaled_image("res://addons/emote_theme/icons/icon_gui_radio_unchecked.svg", p_scale)
	var icon_gui_scroll_arrow_right = load_scaled_image("res://addons/emote_theme/icons/icon_gui_scroll_arrow_right.svg", p_scale)
	var icon_gui_scroll_arrow_left = load_scaled_image("res://addons/emote_theme/icons/icon_gui_scroll_arrow_left.svg", p_scale)
	var icon_gui_tab = load_scaled_image("res://addons/emote_theme/icons/icon_gui_tab.svg", p_scale)
	var icon_gui_spinbox_updown = load_scaled_image("res://addons/emote_theme/icons/icon_gui_spinbox_updown.svg", p_scale)
	var icon_gui_vsplit_bg = load_scaled_image("res://addons/emote_theme/icons/icon_gui_vsplit_bg.svg", p_scale)
	var icon_gui_hsplit_bg = load_scaled_image("res://addons/emote_theme/icons/icon_gui_hsplit_bg.svg", p_scale)
	var icon_gui_slider_grabber = load_scaled_image("res://addons/emote_theme/icons/icon_gui_slider_grabber.svg", p_scale)
	var icon_gui_slider_grabber_hl = load_scaled_image("res://addons/emote_theme/icons/icon_gui_slider_grabber_hl.svg", p_scale)
	var icon_gui_tree_arrow_down = load_scaled_image("res://addons/emote_theme/icons/icon_gui_tree_arrow_down.svg", p_scale)
	var icon_gui_tree_arrow_right = load_scaled_image("res://addons/emote_theme/icons/icon_gui_tree_arrow_right.svg", p_scale)
	var icon_gui_vsplitter = load_scaled_image("res://addons/emote_theme/icons/icon_gui_vsplitter.svg", p_scale)
	var icon_gui_hsplitter = load_scaled_image("res://addons/emote_theme/icons/icon_gui_hsplitter.svg", p_scale)
	var icon_gui_graph_node_port = load_scaled_image("res://addons/emote_theme/icons/icon_gui_graph_node_port.svg", p_scale)
	var icon_gui_mini_checkerboard = load_scaled_image("res://addons/emote_theme/icons/icon_gui_mini_checkerboard.svg", p_scale)
	var icon_gui_resizer = load_scaled_image("res://addons/emote_theme/icons/icon_gui_resizer.svg", p_scale)
	var icon_gui_visibility_hidden = load_scaled_image("res://addons/emote_theme/icons/icon_gui_visibility_hidden.svg", p_scale)
	var icon_gui_visibility_visible = load_scaled_image("res://addons/emote_theme/icons/icon_gui_visibility_visible.svg", p_scale)
	var icon_gui_visibility_xray = load_scaled_image("res://addons/emote_theme/icons/icon_gui_visibility_xray.svg", p_scale)
	var icon_gui_tree_updown = load_scaled_image("res://addons/emote_theme/icons/icon_gui_tree_updown.svg", p_scale)
	var icon_gui_tree_option = load_scaled_image("res://addons/emote_theme/icons/icon_gui_tree_option.svg", p_scale)
	var icon_gui_dropdown = load_scaled_image("res://addons/emote_theme/icons/icon_gui_dropdown.svg", p_scale)

	var icon_gui_v_tick = load_scaled_image("res://addons/emote_theme/icons/icon_gui_v_tick.svg", p_scale)
	var icon_gui_h_tick = load_scaled_image("res://addons/emote_theme/icons/icon_gui_h_tick.svg", p_scale)

	var border_width = 2 * p_scale

	var mono_color = Color(0, 0, 0)
	var separator_color = Color(mono_color.r, mono_color.g, mono_color.b, 0.1)
	var highlight_color = Color(mono_color.r, mono_color.g, mono_color.b, 0.2)

	var dark_color_1 = DEFAULT_BASE_COLOR.lerp(Color(0, 0, 0, 1), DEFAULT_CONTRAST)
	var dark_color_2 = DEFAULT_BASE_COLOR.lerp(Color(0, 0, 0, 1), DEFAULT_CONTRAST * 1.5)
	var dark_color_3 = DEFAULT_BASE_COLOR.lerp(Color(0, 0, 0, 1), DEFAULT_CONTRAST * 2)

	var background_color = dark_color_2

	var contrast_color_1 = DEFAULT_BASE_COLOR.lerp(mono_color, max(DEFAULT_CONTRAST, DEFAULT_CONTRAST))
	var contrast_color_2 = DEFAULT_BASE_COLOR.lerp(mono_color, max(DEFAULT_CONTRAST * 1.5, DEFAULT_CONTRAST * 1.5))

	var success_color = DEFAULT_ACCENT_COLOR.lerp(Color(0.2, 1, 0.2), 0.6) * 1.2
	var warning_color = DEFAULT_ACCENT_COLOR.lerp(Color(1, 1, 0), 0.7) * 1.2
	var error_color = DEFAULT_ACCENT_COLOR.lerp(Color(1, 0, 0), 0.8) * 1.7

	# 2d grid color
	var grid_minor_color = mono_color * Color(1.0, 1.0, 1.0, 0.07)
	var grid_major_color = Color(DEFAULT_FONT_COLOR_DISABLED.r, DEFAULT_FONT_COLOR_DISABLED.g, DEFAULT_FONT_COLOR_DISABLED.b, 0.15)
	theme.set_color("grid_major_color", "Editor", grid_major_color)
	theme.set_color("grid_minor_color", "Editor", grid_minor_color)

	var default_font = register_font(theme, p_scale)
	var large_font = register_font(theme, p_scale)

	var tab_color = DEFAULT_WIDGET_COLOR_INVERSE
	var margin_size_extra = DEFAULT_MARGIN_SIZE + 1

	var shadow_color = Color(0, 0, 0, 0.6)

	var style_default = make_flat_stylebox(DEFAULT_BASE_COLOR, DEFAULT_MARGIN_SIZE, DEFAULT_MARGIN_SIZE, DEFAULT_MARGIN_SIZE, DEFAULT_MARGIN_SIZE)
	var style_empty_widget = make_empty_stylebox(p_scale, 0, DEFAULT_MARGIN_SIZE, 0, DEFAULT_MARGIN_SIZE)

	style_default.set_name("StyleDefault")
	style_default.set_border_width_all(border_width)
	style_default.set_border_color(DEFAULT_BASE_COLOR)
	style_default.set_draw_center(true)

	var style_widget = style_default.duplicate()
	style_widget.set_border_width_all(border_width)
	style_widget.set_name("StyleWidget")
	style_widget.content_margin_left = DEFAULT_MARGIN_SIZE * p_scale
	style_widget.content_margin_right = DEFAULT_MARGIN_SIZE * p_scale
	style_widget.content_margin_bottom = DEFAULT_MARGIN_SIZE * p_scale
	style_widget.content_margin_top = DEFAULT_MARGIN_SIZE * p_scale
	style_widget.set_bg_color(DEFAULT_WIDGET_COLOR)
	style_widget.set_border_color(DEFAULT_WIDGET_BORDER_COLOR)

	var style_widget_disabled = style_widget.duplicate()
	style_widget_disabled.set_name("StyleWidgetDisabled")
	style_widget_disabled.set_border_color(DEFAULT_DISABLED_BORDER_COLOR)
	style_widget_disabled.set_bg_color(DEFAULT_DISABLED_BG_COLOR)

	var style_widget_focus = style_widget.duplicate()
	style_widget_focus.set_name("StyleWidgetFocus")
	style_widget_focus.set_draw_center(false)
	style_widget_focus.set_border_width_all(border_width * 2.0)
	style_widget_focus.set_border_color(DEFAULT_WIDGET_COLOR_INVERSE)

	var style_widget_pressed = style_widget.duplicate()
	style_widget_pressed.set_name("StyleWidgetPressed")
	style_widget_pressed.set_bg_color(Color(DEFAULT_WIDGET_COLOR_INVERSE.r, DEFAULT_WIDGET_COLOR_INVERSE.g, DEFAULT_WIDGET_COLOR_INVERSE.b, 0.5))
	style_widget_pressed.set_border_color(DEFAULT_WIDGET_BORDER_COLOR)

	var style_widget_hover = style_widget.duplicate()
	style_widget_hover.set_name("StyleWidgetHover")
	style_widget_hover.set_border_width_all(border_width)
	style_widget_hover.set_bg_color(DEFAULT_WIDGET_COLOR_INVERSE)
	style_widget_hover.set_border_color(DEFAULT_WIDGET_COLOR_INVERSE)
	style_widget_hover.set_draw_center(true)

	var style_popup = style_default.duplicate()
	style_popup.set_name("StylePopup")
	var popup_margin_size = DEFAULT_MARGIN_SIZE * p_scale * 2
	style_popup.content_margin_left = popup_margin_size
	style_popup.content_margin_right = popup_margin_size
	style_popup.content_margin_bottom = popup_margin_size
	style_popup.content_margin_top = popup_margin_size
	style_popup.set_border_color(contrast_color_1)
	style_popup.set_border_width_all(max(p_scale, border_width))
	style_popup.set_shadow_color(shadow_color)
	style_popup.set_shadow_offset(Vector2(2, 2) * p_scale)
	style_popup.set_shadow_size(2 * p_scale)

	var style_popup_separator = StyleBoxLine.new()
	style_popup_separator.set_name("StylePopupSeparator")
	style_popup_separator.set_color(separator_color)
	style_popup_separator.set_grow_begin(popup_margin_size - max(p_scale, border_width))
	style_popup_separator.set_grow_end(popup_margin_size - max(p_scale, border_width))
	style_popup_separator.set_thickness(max(p_scale, border_width))

	var style_empty = make_empty_stylebox(0, 0, 0, 0)

	###

	theme.set_constant("scale", "Editor", p_scale)

	# Tabs

	var tab_default_margin_side = 10 * p_scale
	var tab_default_margin_vertical = 5 * p_scale

	var style_tab_selected = style_widget.duplicate()
	style_tab_selected.set_name("StyleTabSelected")
	style_tab_selected.set_border_width_all(border_width)
	style_tab_selected.set_border_width(SIDE_BOTTOM, 0)
	style_tab_selected.set_border_color(DEFAULT_WIDGET_COLOR)
	style_tab_selected.expand_margin_bottom = border_width
	style_tab_selected.content_margin_left = tab_default_margin_side
	style_tab_selected.content_margin_right = tab_default_margin_side
	style_tab_selected.content_margin_bottom = tab_default_margin_vertical
	style_tab_selected.content_margin_top = tab_default_margin_vertical
	style_tab_selected.set_bg_color(DEFAULT_WIDGET_COLOR_INVERSE)

	var style_tab_unselected = style_tab_selected.duplicate()
	style_tab_unselected.set_name("StyleTabUnSelected")
	style_tab_unselected.set_bg_color(DEFAULT_WIDGET_COLOR)
	style_tab_unselected.set_border_width_all(0)

	# Editor background

	theme.set_stylebox("Background", "EditorStyles", make_flat_stylebox(background_color, DEFAULT_MARGIN_SIZE, DEFAULT_MARGIN_SIZE, DEFAULT_MARGIN_SIZE, DEFAULT_MARGIN_SIZE))

	# Focus

	var style_focus = style_default.duplicate()
	style_focus.set_name("Focus")
	style_focus.set_draw_center(false)
	style_focus.set_border_color(contrast_color_2)
	theme.set_stylebox("Focus", "EditorStyles", style_focus)

	# Menu

	var style_menu = style_widget.duplicate()
	style_menu.set_name("StyleMenu")
	style_menu.set_draw_center(false)
	style_menu.set_border_width_all(0)
	theme.set_stylebox("panel", "PanelContainer", style_menu)
	theme.set_stylebox("MenuPanel", "EditorStyles", style_menu)

	# Script Editor

	theme.set_stylebox("ScriptEditorPanel", "EditorStyles", make_empty_stylebox(DEFAULT_MARGIN_SIZE, 0, DEFAULT_MARGIN_SIZE, DEFAULT_MARGIN_SIZE))
	theme.set_stylebox("ScriptEditor", "EditorStyles", make_empty_stylebox(0, 0, 0, 0))

	# Play button group

	theme.set_stylebox("PlayButtonPanel", "EditorStyles", style_empty_widget)

	# Button

	theme.set_stylebox("normal", "Button", style_widget)
	theme.set_stylebox("hover", "Button", style_widget_hover)
	theme.set_stylebox("pressed", "Button", style_widget_pressed)
	theme.set_stylebox("focus", "Button", style_widget_focus)
	theme.set_stylebox("disabled", "Button", style_widget_disabled)

	theme.set_font("font", "Button", default_font)
	theme.set_font_size("font_size", "Button", DEFAULT_FONT_SIZE)

	theme.set_color("font_color", "Button", DEFAULT_WIDGET_FONT_COLOR)
	theme.set_color("font_hover_color", "Button", Color(DEFAULT_WIDGET_FONT_COLOR_INVERSE.r * 0.75, DEFAULT_WIDGET_FONT_COLOR_INVERSE.b * 0.75, DEFAULT_WIDGET_FONT_COLOR_INVERSE.g * 0.75, 1.0))
	theme.set_color("font_focus_color", "Button", DEFAULT_WIDGET_FONT_COLOR)
	theme.set_color("font_pressed_color", "Button", DEFAULT_WIDGET_FONT_COLOR)
	theme.set_color("font_disabled_color", "Button", DEFAULT_FONT_COLOR_DISABLED)

	theme.set_color("icon_color_hover", "Button", Color(DEFAULT_WIDGET_FONT_COLOR_INVERSE.r * 0.75, DEFAULT_WIDGET_FONT_COLOR_INVERSE.b * 0.75, DEFAULT_WIDGET_FONT_COLOR_INVERSE.g * 0.75, 1.0))

	theme.set_color("icon_color_pressed", "Button", DEFAULT_WIDGET_FONT_COLOR)

	# LinkButton

	theme.set_stylebox("focus", "LinkButton", style_focus)

	theme.set_font("font", "LinkButton", default_font)
	theme.set_font_size("font_size", "LinkButton", DEFAULT_FONT_SIZE)

	theme.set_color("font_color", "LinkButton", DEFAULT_FONT_COLOR)
	theme.set_color("font_color_pressed", "LinkButton", DEFAULT_ACCENT_COLOR)
	theme.set_color("font_selected_color", "LinkButton", DEFAULT_FONT_COLOR_HL)

	theme.set_constant("underline_spacing", "LinkButton", 2 * p_scale)

	# ColorPickerButton

	theme.set_stylebox("normal", "ColorPickerButton", style_widget)
	theme.set_stylebox("pressed", "ColorPickerButton", style_widget_pressed)
	theme.set_stylebox("hover", "ColorPickerButton", style_widget_hover)
	theme.set_stylebox("disabled", "ColorPickerButton", style_widget_focus)
	theme.set_stylebox("focus", "ColorPickerButton", style_widget_disabled)

	theme.set_font("font", "ColorPickerButton", default_font)
	theme.set_font_size("font_size", "ColorPickerButton", DEFAULT_FONT_SIZE)

	theme.set_color("font_color", "ColorPickerButton", Color(1, 1, 1, 1))
	theme.set_color("font_color_pressed", "ColorPickerButton", Color(0.8, 0.8, 0.8, 1))
	theme.set_color("font_selected_color", "ColorPickerButton", Color(1, 1, 1, 1))
	theme.set_color("font_color_disabled", "ColorPickerButton", Color(0.9, 0.9, 0.9, 0.3))

	theme.set_constant("hseparation", "ColorPickerButton", 2 * p_scale)

	# ToolButton

	theme.set_stylebox("normal", "ToolButton", make_empty_stylebox(0, 0, 0, 0))
	theme.set_stylebox("hover", "ToolButton", make_empty_stylebox(0, 0, 0, 0))
	theme.set_stylebox("pressed", "ToolButton", make_empty_stylebox(0, 0, 0, 0))
	theme.set_stylebox("focus", "ToolButton", make_empty_stylebox(0, 0, 0, 0))
	theme.set_stylebox("disabled", "ToolButton", make_empty_stylebox(0, 0, 0, 0))

	theme.set_font("font", "ToolButton", default_font)
	theme.set_font_size("font_size", "ToolButton", DEFAULT_FONT_SIZE)

	theme.set_color("font_color", "ToolButton", DEFAULT_WIDGET_FONT_COLOR_INVERSE)
	theme.set_color("font_selected_color", "ToolButton", DEFAULT_FONT_COLOR_HL)
	theme.set_color("font_color_pressed", "ToolButton", DEFAULT_ACCENT_COLOR)

	# OptionButton

	theme.set_stylebox("normal", "OptionButton", style_widget)
	theme.set_stylebox("hover", "OptionButton", style_widget_hover)
	theme.set_stylebox("pressed", "OptionButton", style_widget_pressed)
	theme.set_stylebox("focus", "OptionButton", style_widget_focus)
	theme.set_stylebox("disabled", "OptionButton", style_widget_disabled)

	theme.set_font("font", "OptionButton", default_font)
	theme.set_font_size("font_size", "OptionButton", DEFAULT_FONT_SIZE)

	theme.set_color("font_color", "OptionButton", DEFAULT_FONT_COLOR)
	theme.set_color("font_selected_color", "OptionButton", DEFAULT_FONT_COLOR_HL)
	theme.set_color("font_color_pressed", "OptionButton", DEFAULT_ACCENT_COLOR)
	theme.set_color("font_color_disabled", "OptionButton", DEFAULT_FONT_COLOR_DISABLED)
	theme.set_color("icon_color_hover", "OptionButton", DEFAULT_FONT_COLOR_HL)

	theme.set_icon("arrow", "OptionButton", icon_gui_option_arrow)
	theme.set_font("font", "OptionButton", default_font)

	theme.set_constant("arrow_margin", "OptionButton", DEFAULT_MARGIN_SIZE * p_scale)
	theme.set_constant("modulate_arrow", "OptionButton", true)

	# MenuButton

	var style_menu_hover_border = style_widget.duplicate()
	style_menu_hover_border.set_name("StyleMenuHoverBorder")
	style_menu_hover_border.set_draw_center(false)
	style_menu_hover_border.set_border_width_all(0)
	style_menu_hover_border.set_border_width(SIDE_BOTTOM, border_width)
	style_menu_hover_border.set_border_color(DEFAULT_ACCENT_COLOR)

	var style_menu_hover_bg = style_widget.duplicate()
	style_menu_hover_bg.set_name("StyleMenuHoverBG")
	style_menu_hover_bg.set_border_width_all(0)
	style_menu_hover_bg.set_bg_color(dark_color_1)

	theme.set_stylebox("normal", "MenuButton", style_widget)
	theme.set_stylebox("hover", "MenuButton", style_widget_hover)
	theme.set_stylebox("pressed", "MenuButton", style_widget_pressed)
	theme.set_stylebox("focus", "MenuButton", style_widget_focus)
	theme.set_stylebox("disabled", "MenuButton", style_widget_disabled)

	theme.set_font("font", "MenuButton", default_font)
	theme.set_font_size("font_size", "MenuButton", DEFAULT_FONT_SIZE)

	theme.set_color("font_color", "MenuButton", DEFAULT_FONT_COLOR)
	theme.set_color("font_selected_color", "MenuButton", DEFAULT_FONT_COLOR_HL)
	theme.set_color("font_color_pressed", "MenuButton", DEFAULT_ACCENT_COLOR)
	theme.set_color("font_color_disabled", "MenuButton", DEFAULT_FONT_COLOR_DISABLED)

	theme.set_constant("hseparation", "MenuButton", 3 * p_scale)

	# PopupMenu

	theme.set_stylebox("normal", "PopupMenu", style_menu)
	theme.set_stylebox("hover", "PopupMenu", style_menu_hover_bg)
	theme.set_stylebox("pressed", "PopupMenu", style_menu)
	theme.set_stylebox("focus", "PopupMenu", style_menu)
	theme.set_stylebox("disabled", "PopupMenu", style_menu)

	theme.set_stylebox("MenuHover", "EditorStyles", style_menu_hover_border)

	# ButtonGroup

	theme.set_stylebox("panel", "ButtonGroup", StyleBoxEmpty.new())

	# Checkbox

	theme.set_stylebox("normal", "CheckBox", style_empty_widget)
	theme.set_stylebox("pressed", "CheckBox", style_empty_widget)
	theme.set_stylebox("disabled", "CheckBox", style_empty_widget)
	theme.set_stylebox("hover", "CheckBox", style_empty_widget)
	theme.set_icon("checked", "CheckBox", icon_gui_checked)
	theme.set_icon("unchecked", "CheckBox", icon_gui_unchecked)
	theme.set_icon("radio_checked", "CheckBox", icon_gui_radio_checked)
	theme.set_icon("radio_unchecked", "CheckBox", icon_gui_radio_unchecked)

	theme.set_font("font", "CheckBox", default_font)

	theme.set_color("font_color", "CheckBox", DEFAULT_WIDGET_FONT_COLOR_INVERSE)
	theme.set_color("font_selected_color", "CheckBox", DEFAULT_FONT_COLOR_HL)
	theme.set_color("font_color_pressed", "CheckBox", DEFAULT_ACCENT_COLOR)
	theme.set_color("font_color_disabled", "CheckBox", DEFAULT_FONT_COLOR_DISABLED)
	theme.set_color("icon_color_hover", "CheckBox", DEFAULT_FONT_COLOR_HL)

	theme.set_constant("hseparation", "CheckBox", 4 * p_scale)
	theme.set_constant("check_vadjust", "CheckBox", 0 * p_scale)

	# CheckButton

	theme.set_stylebox("normal", "CheckButton", style_empty_widget)
	theme.set_stylebox("pressed", "CheckButton", style_empty_widget)
	theme.set_stylebox("disabled", "CheckButton", style_empty_widget)
	theme.set_stylebox("hover", "CheckButton", style_empty_widget)

	theme.set_icon("on", "CheckButton", icon_gui_toggle_on)
	theme.set_icon("off", "CheckButton", icon_gui_toggle_off)

	theme.set_font("font", "CheckButton", default_font)

	theme.set_color("font_color", "CheckButton", DEFAULT_WIDGET_FONT_COLOR_INVERSE)
	theme.set_color("font_selected_color", "CheckButton", DEFAULT_FONT_COLOR_HL)
	theme.set_color("font_color_pressed", "CheckButton", DEFAULT_ACCENT_COLOR)
	theme.set_color("font_color_disabled", "CheckButton", DEFAULT_FONT_COLOR_DISABLED)
	theme.set_color("icon_color_hover", "CheckButton", DEFAULT_FONT_COLOR_HL)

	theme.set_constant("hseparation", "CheckButton", 4 * p_scale)
	theme.set_constant("check_vadjust", "CheckButton", 0 * p_scale)

	# Label

	theme.set_stylebox("normal", "Label", style_empty)
	theme.set_font("font", "Label", default_font)

	theme.set_color("font_color", "Label", DEFAULT_FONT_COLOR)
	theme.set_color("font_color_shadow", "Label", Color(0, 0, 0, 0))
	theme.set_color("font_outline_modulate", "Label", Color(1, 1, 1))

	theme.set_constant("shadow_offset_x", "Label", 1 * p_scale)
	theme.set_constant("shadow_offset_y", "Label", 1 * p_scale)
	theme.set_constant("shadow_as_outline", "Label", 0 * p_scale)
	theme.set_constant("line_spacing", "Label", 3 * p_scale)

	# LineEdit

	theme.set_stylebox("normal", "LineEdit", style_widget_hover)
	theme.set_stylebox("focus", "LineEdit", style_widget_hover)
	theme.set_stylebox("read_only", "LineEdit", style_widget_disabled)

	theme.set_font("font", "LineEdit", default_font)

	theme.set_color("read_only", "LineEdit", DEFAULT_FONT_COLOR_DISABLED)
	theme.set_color("font_color", "LineEdit", DEFAULT_WIDGET_FONT_COLOR_INVERSE)
	theme.set_color("cursor_color", "LineEdit", DEFAULT_WIDGET_FONT_COLOR_INVERSE)
	theme.set_color("selection_color", "LineEdit", DEFAULT_FONT_COLOR_SELECTION)

	# ProgressBar
	var progressbar_bg_stylebox = make_flat_stylebox(EMOTE_SECONDARY_COLOR, p_scale, 0, -1, 0, -1)
	var progressbar_fg_stylebox = make_flat_stylebox(EMOTE_PRIMARY_COLOR, p_scale, 0, -1, 0, -1)

	theme.set_stylebox("bg", "ProgressBar", progressbar_bg_stylebox)
	theme.set_stylebox("fg", "ProgressBar", progressbar_fg_stylebox)

	theme.set_font("font", "ProgressBar", default_font)

	theme.set_color("font_color", "ProgressBar", DEFAULT_WIDGET_FONT_COLOR)
	theme.set_color("font_color_shadow", "ProgressBar", Color(0, 0, 0))

	# TextEdit

	theme.set_stylebox("normal", "TextEdit", style_widget_pressed)
	theme.set_stylebox("focus", "TextEdit", style_widget_pressed)
	theme.set_stylebox("read_only", "TextEdit", style_widget_disabled)

	theme.set_constant("side_margin", "TabContainer", 0)

	theme.set_icon("tab", "TextEdit", icon_gui_tab)
	theme.set_font("font", "TextEdit", default_font)

	theme.set_color("font_color", "TextEdit", DEFAULT_FONT_COLOR)
	theme.set_color("caret_color", "TextEdit", DEFAULT_FONT_COLOR_HIGHLIGHT)
	theme.set_color("selection_color", "TextEdit", DEFAULT_FONT_COLOR_SELECTION)

	# Scrollbars

	var scroll_stylebox = make_flat_stylebox(DEFAULT_BASE_COLOR, p_scale, 5.0, 5.0, 5.0, 5.0)
	var scroll_focus_stylebox = make_flat_stylebox(DEFAULT_BASE_COLOR, p_scale, 5.0, 5.0, 5.0, 5.0)
	var grabber_stylebox = make_flat_stylebox(EMOTE_PRIMARY_COLOR, p_scale, 5.0, 5.0, 5.0, 5.0)
	var grabber_highlight_stylebox = make_flat_stylebox(EMOTE_PRIMARY_COLOR_BRIGHT, p_scale, 5.0, 5.0, 5.0, 5.0)
	var grabber_pressed_stylebox = make_flat_stylebox(EMOTE_PRIMARY_COLOR_DARK, p_scale, 5.0, 5.0, 5.0, 5.0)

	# HScrollBar
	theme.set_stylebox("scroll", "HScrollBar", scroll_stylebox)
	theme.set_stylebox("scroll_focus", "HScrollBar", scroll_focus_stylebox)
	theme.set_stylebox("grabber", "HScrollBar", grabber_stylebox)
	theme.set_stylebox("grabber_highlight", "HScrollBar", grabber_highlight_stylebox)
	theme.set_stylebox("grabber_pressed", "HScrollBar", grabber_pressed_stylebox)

	theme.set_icon("increment", "HScrollBar", icon_empty)
	theme.set_icon("increment_highlight", "HScrollBar", icon_empty)
	theme.set_icon("decrement", "HScrollBar", icon_empty)
	theme.set_icon("decrement_highlight", "HScrollBar", icon_empty)

	# VScrollBar

	theme.set_stylebox("scroll", "VScrollBar", scroll_stylebox)
	theme.set_stylebox("scroll_focus", "VScrollBar", scroll_focus_stylebox)
	theme.set_stylebox("grabber", "VScrollBar", grabber_stylebox)
	theme.set_stylebox("grabber_highlight", "VScrollBar", grabber_highlight_stylebox)
	theme.set_stylebox("grabber_pressed", "VScrollBar", grabber_pressed_stylebox)

	theme.set_icon("increment", "VScrollBar", icon_empty)
	theme.set_icon("increment_highlight", "VScrollBar", icon_empty)
	theme.set_icon("decrement", "VScrollBar", icon_empty)
	theme.set_icon("decrement_highlight", "VScrollBar", icon_empty)

	# HSlider

	theme.set_icon("grabber", "HSlider", icon_gui_slider_grabber)
	theme.set_icon("grabber_highlight", "HSlider", icon_gui_slider_grabber_hl)
	theme.set_icon("tick", "HSlider", icon_gui_h_tick)
	theme.set_stylebox("slider", "HSlider", make_flat_stylebox(EMOTE_SECONDARY_COLOR, p_scale, 2.0, 2.0, 2.0, 2.0))
	theme.set_stylebox("grabber_area", "HSlider", make_flat_stylebox(EMOTE_PRIMARY_COLOR, p_scale, 2.0, 2.0, 2.0, 2.0))
	theme.set_stylebox("grabber_area_highlight", "HSlider", make_flat_stylebox(EMOTE_PRIMARY_COLOR_BRIGHT, p_scale, 2.0, 2.0, 2.0, 2.0))

	# VSlider

	theme.set_icon("grabber", "VSlider", icon_gui_slider_grabber)
	theme.set_icon("grabber_highlight", "VSlider", icon_gui_slider_grabber_hl)
	theme.set_icon("tick", "VSlider", icon_gui_v_tick)
	theme.set_stylebox("slider", "VSlider", make_flat_stylebox(EMOTE_SECONDARY_COLOR, p_scale, 2.0, 2.0, 2.0, 2.0))
	theme.set_stylebox("grabber_area", "VSlider", make_flat_stylebox(EMOTE_PRIMARY_COLOR, p_scale, 2.0, 2.0, 2.0, 2.0))
	theme.set_stylebox("grabber_area_highlight", "VSlider", make_flat_stylebox(EMOTE_PRIMARY_COLOR_BRIGHT, p_scale, 2.0, 2.0, 2.0, 2.0))
	# SpinBox
	theme.set_icon("updown", "SpinBox", icon_gui_spinbox_updown)

	# ScrollContainer

	theme.set_stylebox("bg", "ScrollContainer", icon_empty)

	# Window

	var style_window = style_popup.duplicate()
	style_window.set_name("StyleWindow")
	style_window.set_border_color(DEFAULT_WIDGET_COLOR)
	style_window.set_border_width(SIDE_TOP, WINDOW_TITLEBAR * p_scale)
	style_window.expand_margin_top = (WINDOW_TITLEBAR * p_scale)
	theme.set_stylebox("panel", "Window", style_window)
	theme.set_color("title_color", "Window", DEFAULT_WIDGET_FONT_COLOR)
	theme.set_icon("close", "Window", icon_gui_close)
	theme.set_icon("close_highlight", "Window", icon_gui_close)
	theme.set_constant("close_h_ofs", "Window", 22 * p_scale)
	theme.set_constant("close_v_ofs", "Window", 20 * p_scale)
	theme.set_constant("title_height", "Window", 24 * p_scale)
	theme.set_font("title_font", "Window", large_font)

	# FileDialog

	theme.set_icon("folder", "FileDialog", icon_folder)
	theme.set_color("files_disabled", "FileDialog", DEFAULT_FONT_COLOR_DISABLED)

	# PopupMenu

	var style_popup_menu = style_popup
	theme.set_stylebox("panel", "PopupMenu", style_popup_menu)
	theme.set_stylebox("separator", "PopupMenu", style_popup_separator)
	theme.set_color("font_color", "PopupMenu", DEFAULT_WIDGET_FONT_COLOR_INVERSE)
	theme.set_color("font_selected_color", "PopupMenu", DEFAULT_WIDGET_FONT_COLOR)
	theme.set_color("font_color_accel", "PopupMenu", DEFAULT_FONT_COLOR_DISABLED)
	theme.set_color("font_color_disabled", "PopupMenu", DEFAULT_FONT_COLOR_DISABLED)
	theme.set_icon("checked", "PopupMenu", icon_gui_checked)
	theme.set_icon("unchecked", "PopupMenu", icon_gui_unchecked)
	theme.set_icon("radio_checked", "PopupMenu", icon_gui_checked)
	theme.set_icon("radio_unchecked", "PopupMenu", icon_gui_unchecked)
	theme.set_icon("submenu", "PopupMenu", icon_arrow_right)

	theme.set_font("font", "PopupMenu", default_font)

	theme.set_icon("visibility_hidden", "PopupMenu", icon_gui_visibility_hidden)
	theme.set_icon("visibility_visible", "PopupMenu", icon_gui_visibility_visible)
	theme.set_icon("visibility_xray", "PopupMenu", icon_gui_visibility_xray)
	theme.set_constant("vseparation", "PopupMenu", DEFAULT_MARGIN_SIZE * p_scale)

	# Tree & ItemList background

	theme.set_stylebox("bg", "Tree", style_widget_hover)

	var guide_color = Color(mono_color.r, mono_color.g, mono_color.b, 0.05)

	# Tree

	theme.set_icon("checked", "Tree", icon_gui_checked)
	theme.set_icon("unchecked", "Tree", icon_gui_unchecked)
	theme.set_icon("arrow", "Tree", icon_gui_tree_arrow_down)
	theme.set_icon("arrow_collapsed", "Tree", icon_gui_tree_arrow_right)
	theme.set_font("title_button_font", "Tree", default_font)
	theme.set_font("font", "Tree", default_font)
	theme.set_icon("updown", "Tree", icon_gui_tree_updown)
	theme.set_icon("select_arrow", "Tree", icon_gui_dropdown)
	theme.set_icon("select_option", "Tree", icon_gui_tree_option)
	theme.set_stylebox("bg_focus", "Tree", style_focus)
	theme.set_stylebox("custom_button", "Tree", make_empty_stylebox(p_scale))
	theme.set_stylebox("custom_button_pressed", "Tree", make_empty_stylebox(p_scale))
	theme.set_stylebox("custom_button_hover", "Tree", style_widget)
	theme.set_color("custom_button_font_highlight", "Tree", DEFAULT_FONT_COLOR_HL)
	theme.set_color("font_color", "Tree", DEFAULT_WIDGET_FONT_COLOR_INVERSE)
	theme.set_color("font_selected_color", "Tree", DEFAULT_WIDGET_FONT_COLOR)
	theme.set_color("title_button_color", "Tree", DEFAULT_WIDGET_FONT_COLOR)
	theme.set_color("guide_color", "Tree", guide_color)
	theme.set_color("drop_position_color", "Tree", DEFAULT_ACCENT_COLOR)
	theme.set_constant("vseparation", "Tree", (DEFAULT_MARGIN_SIZE) * p_scale)
	theme.set_constant("hseparation", "Tree", (DEFAULT_MARGIN_SIZE) * p_scale)
	theme.set_constant("guide_width", "Tree", border_width)
	theme.set_constant("item_margin", "Tree", 3 * DEFAULT_MARGIN_SIZE * p_scale)
	theme.set_constant("button_margin", "Tree", DEFAULT_MARGIN_SIZE * p_scale)
	theme.set_constant("draw_relationship_lines", "Tree", 0)
	theme.set_constant("scroll_border", "Tree", DEFAULT_MARGIN_SIZE * p_scale)
	theme.set_constant("scroll_speed", "Tree", 12)

	var style_tree_btn: StyleBoxFlat = style_default.duplicate()
	style_tree_btn.resource_name = "StyleTreeButton"
	style_tree_btn.set_bg_color(contrast_color_1)
	style_tree_btn.set_border_width_all(0)
	theme.set_stylebox("button_pressed", "Tree", style_tree_btn)

	var style_tree_focus = style_default.duplicate()
	style_tree_focus.resource_name = "StyleTreeFocus"
	style_tree_focus.set_bg_color(highlight_color)
	style_tree_focus.set_border_width_all(0)
	theme.set_stylebox("selected_focus", "Tree", style_tree_focus)

	var style_tree_selected = style_tree_focus.duplicate()
	style_tree_selected.resource_name = "StyleTreeSelected"
	theme.set_stylebox("selected", "Tree", style_tree_selected)

	var style_tree_cursor = style_default.duplicate()
	style_tree_cursor.resource_name = "StyleTreeCursor"
	style_tree_cursor.set_draw_center(false)
	style_tree_cursor.set_border_width_all(border_width)
	style_tree_cursor.set_border_color(contrast_color_1)

	var style_tree_title = style_default.duplicate()
	style_tree_title.resource_name = "StyleTreeTitle"
	style_tree_title.set_bg_color(dark_color_3)
	style_tree_title.set_border_width_all(0)
	theme.set_stylebox("cursor", "Tree", style_tree_cursor)
	theme.set_stylebox("cursor_unfocused", "Tree", style_tree_cursor)
	theme.set_stylebox("title_button_normal", "Tree", style_tree_title)
	theme.set_stylebox("title_button_hover", "Tree", style_tree_title)
	theme.set_stylebox("title_button_pressed", "Tree", style_tree_title)

	var prop_category_color = dark_color_1.lerp(mono_color, 0.12)
	var prop_section_color = dark_color_1.lerp(mono_color, 0.09)
	var prop_subsection_color = dark_color_1.lerp(mono_color, 0.06)
	theme.set_color("prop_category", "Editor", prop_category_color)
	theme.set_color("prop_section", "Editor", prop_section_color)
	theme.set_color("prop_subsection", "Editor", prop_subsection_color)
	theme.set_color("drop_position_color", "Tree", DEFAULT_ACCENT_COLOR)

	# ItemList
	var style_itemlist_bg = style_default.duplicate()
	style_itemlist_bg.resource_name = "StyleItemlistBG"
	style_itemlist_bg.set_bg_color(DEFAULT_WIDGET_COLOR_INVERSE)
	style_itemlist_bg.set_border_width_all(border_width)
	style_itemlist_bg.set_border_color(DEFAULT_WIDGET_COLOR)

	var style_itemlist_cursor = style_default.duplicate()
	style_itemlist_cursor.resource_name = "StyleItemlistCursor"
	style_itemlist_cursor.set_draw_center(false)
	style_itemlist_cursor.set_border_width_all(border_width)
	style_itemlist_cursor.set_border_color(highlight_color)
	theme.set_stylebox("cursor", "ItemList", style_itemlist_cursor)
	theme.set_stylebox("cursor_unfocused", "ItemList", style_itemlist_cursor)
	theme.set_stylebox("selected_focus", "ItemList", style_tree_focus)
	theme.set_stylebox("selected", "ItemList", style_tree_selected)
	theme.set_stylebox("bg_focus", "ItemList", style_focus)
	theme.set_stylebox("bg", "ItemList", style_itemlist_bg)
	theme.set_color("font_color", "ItemList", DEFAULT_WIDGET_FONT_COLOR_INVERSE)
	theme.set_color("font_selected_color", "ItemList", DEFAULT_WIDGET_FONT_COLOR)
	theme.set_color("guide_color", "ItemList", guide_color)
	theme.set_constant("vseparation", "ItemList", 2 * p_scale)
	theme.set_constant("hseparation", "ItemList", 2 * p_scale)
	theme.set_constant("icon_margin", "ItemList", DEFAULT_MARGIN_SIZE * p_scale)
	theme.set_constant("line_separation", "ItemList", 2 * p_scale)
	theme.set_font("font", "ItemList", default_font)

	# Tabs & TabContainer
	theme.set_stylebox("tab_fg", "TabContainer", style_tab_selected)
	theme.set_stylebox("tab_bg", "TabContainer", style_tab_unselected)
	theme.set_stylebox("tab_fg", "Tabs", style_tab_selected)
	theme.set_stylebox("tab_bg", "Tabs", style_tab_unselected)
	theme.set_color("font_color_fg", "TabContainer", DEFAULT_WIDGET_FONT_COLOR_INVERSE)
	theme.set_color("font_color_bg", "TabContainer", DEFAULT_WIDGET_FONT_COLOR)
	theme.set_color("font_color_fg", "Tabs", DEFAULT_WIDGET_FONT_COLOR_INVERSE)
	theme.set_color("font_color_bg", "Tabs", DEFAULT_WIDGET_FONT_COLOR)
	theme.set_icon("menu", "TabContainer", icon_gui_tab_menu)
	theme.set_icon("menu_highlight", "TabContainer", icon_gui_tab_menu)
	theme.set_font("font", "TabContainer", default_font)
	theme.set_font("font", "Tabs", default_font)
	theme.set_stylebox("SceneTabFG", "EditorStyles", style_tab_selected)
	theme.set_stylebox("SceneTabBG", "EditorStyles", style_tab_unselected)
	theme.set_icon("close", "Tabs", icon_gui_close)
	theme.set_stylebox("button_pressed", "Tabs", style_menu)
	theme.set_stylebox("button", "Tabs", style_menu)
	theme.set_icon("increment", "TabContainer", icon_gui_scroll_arrow_right)
	theme.set_icon("decrement", "TabContainer", icon_gui_scroll_arrow_left)
	theme.set_icon("increment", "Tabs", icon_gui_scroll_arrow_right)
	theme.set_icon("decrement", "Tabs", icon_gui_scroll_arrow_left)
	theme.set_icon("increment_highlight", "Tabs", icon_gui_scroll_arrow_right)
	theme.set_icon("decrement_highlight", "Tabs", icon_gui_scroll_arrow_left)
	theme.set_icon("increment_highlight", "TabContainer", icon_gui_scroll_arrow_right)
	theme.set_icon("decrement_highlight", "TabContainer", icon_gui_scroll_arrow_left)
	theme.set_constant("hseparation", "Tabs", 4 * p_scale)

	# Content of each tab
	var style_content_panel = style_default.duplicate()
	style_content_panel.resource_name = "StyleContentPanel"
	style_content_panel.set_border_color(DEFAULT_WIDGET_COLOR)
	style_content_panel.set_border_width_all(border_width)
	# compensate the border
	style_content_panel.content_margin_left = margin_size_extra * p_scale
	style_content_panel.content_margin_right = margin_size_extra * p_scale
	style_content_panel.content_margin_bottom = margin_size_extra * p_scale
	style_content_panel.content_margin_top = margin_size_extra * p_scale

	# this is the stylebox used in 3d and 2d viewports (no borders)
	var style_content_panel_vp = style_content_panel.duplicate()
	style_content_panel_vp.resource_name = "StyleContentPanelVP"
	style_content_panel_vp.content_margin_left = border_width * 2
	style_content_panel_vp.content_margin_right = DEFAULT_MARGIN_SIZE * p_scale
	style_content_panel_vp.content_margin_bottom = border_width * 2
	style_content_panel_vp.content_margin_top = border_width * 2
	theme.set_stylebox("panel", "TabContainer", style_content_panel)
	theme.set_stylebox("Content", "EditorStyles", style_content_panel_vp)

	# Separators
	theme.set_stylebox("separator", "HSeparator", make_line_stylebox(separator_color, border_width))
	theme.set_stylebox("separator", "VSeparator", make_line_stylebox(separator_color, border_width, 0, true))

	theme.set_icon("close", "Icons", icon_gui_close)
	theme.set_font("normal", "Fonts", default_font)
	theme.set_font("large", "Fonts", large_font)

	# H/VSplitContainer
	theme.set_stylebox("bg", "VSplitContainer", make_stylebox(icon_gui_vsplit_bg, 1, 1, 1, 1, p_scale))
	theme.set_stylebox("bg", "HSplitContainer", make_stylebox(icon_gui_hsplit_bg, 1, 1, 1, 1, p_scale))

	theme.set_icon("grabber", "VSplitContainer", icon_gui_vsplitter)
	theme.set_icon("grabber", "HSplitContainer", icon_gui_hsplitter)

	theme.set_constant("separation", "HSplitContainer", DEFAULT_MARGIN_SIZE * 2 * p_scale)
	theme.set_constant("separation", "VSplitContainer", DEFAULT_MARGIN_SIZE * 2 * p_scale)

	# Containers
	theme.set_constant("separation", "BoxContainer", DEFAULT_MARGIN_SIZE * p_scale)
	theme.set_constant("separation", "HBoxContainer", DEFAULT_MARGIN_SIZE * p_scale)
	theme.set_constant("separation", "VBoxContainer", DEFAULT_MARGIN_SIZE * p_scale)
	theme.set_constant("margin_left", "MarginContainer", 0)
	theme.set_constant("margin_top", "MarginContainer", 0)
	theme.set_constant("margin_right", "MarginContainer", 0)
	theme.set_constant("margin_bottom", "MarginContainer", 0)
	theme.set_constant("hseparation", "GridContainer", DEFAULT_MARGIN_SIZE * p_scale)
	theme.set_constant("vseparation", "GridContainer", DEFAULT_MARGIN_SIZE * p_scale)

	# complex window, for now only Editor settings and Project settings
	var style_complex_window = style_window.duplicate()
	style_complex_window.set_name("StyleComplexWindow")
	style_complex_window.set_bg_color(dark_color_2)
	style_complex_window.set_border_color(dark_color_2)
	theme.set_stylebox("panel", "EditorSettingsDialog", style_complex_window)
	theme.set_stylebox("panel", "ProjectSettingsEditor", style_complex_window)
	theme.set_stylebox("panel", "EditorAbout", style_complex_window)

	#RichTextLabel
	theme.set_color("default_color", "RichTextLabel", DEFAULT_FONT_COLOR)
	theme.set_stylebox("focus", "RichTextLabel", make_empty_stylebox(p_scale))
	theme.set_stylebox("normal", "RichTextLabel", style_widget)

	theme.set_font("normal_font", "RichTextLabel", default_font)
	theme.set_font("bold_font", "RichTextLabel", default_font)
	theme.set_font("italics_font", "RichTextLabel", default_font)
	theme.set_font("bold_italics_font", "RichTextLabel", default_font)
	theme.set_font("mono_font", "RichTextLabel", default_font)

	theme.set_color("headline_color", "EditorHelp", mono_color)

	# Panel
	theme.set_stylebox("panel", "Panel", style_default)

	# TooltipPanel
	var style_tooltip = style_popup.duplicate()
	style_tooltip.set_name("StyleTooltip")
	style_tooltip.set_bg_color(Color(mono_color.r, mono_color.g, mono_color.b, 0.9))
	style_tooltip.set_border_width_all(border_width)
	style_tooltip.set_border_color(mono_color)
	theme.set_color("font_color", "TooltipLabel", DEFAULT_FONT_COLOR.inverted())
	theme.set_color("font_color_shadow", "TooltipLabel", mono_color.inverted() * Color(1, 1, 1, 0.1))
	theme.set_stylebox("panel", "TooltipPanel", style_tooltip)
	theme.set_font("font", "TooltipLabel", default_font)

	# PopupPanel
	theme.set_stylebox("panel", "PopupPanel", style_popup)

	# GraphEdit
	theme.set_stylebox("bg", "GraphEdit", style_widget)
	theme.set_color("grid_major", "GraphEdit", grid_major_color)
	theme.set_color("grid_minor", "GraphEdit", grid_minor_color)
	theme.set_icon("minus", "GraphEdit", icon_zoom_less)
	theme.set_icon("more", "GraphEdit", icon_zoom_more)
	theme.set_icon("reset", "GraphEdit", icon_zoom_reset)
	theme.set_icon("snap", "GraphEdit", icon_snap_grid)
	theme.set_constant("bezier_len_pos", "GraphEdit", 80 * p_scale)
	theme.set_constant("bezier_len_neg", "GraphEdit", 160 * p_scale)

	# GraphNode
	var mv = 1.0
	var mv2 = 1.0 - mv
	var gn_margin_side = 28
	var graphsb = make_flat_stylebox(Color(mv, mv, mv, 0.7), gn_margin_side, 24, gn_margin_side, 5)
	graphsb.set_border_width_all(border_width)
	graphsb.set_border_color(Color(mv2, mv2, mv2, 0.9))
	var graphsbselected = make_flat_stylebox(Color(mv, mv, mv, 0.9), gn_margin_side, 24, gn_margin_side, 5)
	graphsbselected.set_border_width_all(border_width)
	graphsbselected.set_border_color(Color(DEFAULT_ACCENT_COLOR.r, DEFAULT_ACCENT_COLOR.g, DEFAULT_ACCENT_COLOR.b, 0.9))
	graphsbselected.set_shadow_size(8 * p_scale)
	graphsbselected.set_shadow_color(shadow_color)
	var graphsbcomment = make_flat_stylebox(Color(mv, mv, mv, 0.3), gn_margin_side, 24, gn_margin_side, 5)
	graphsbcomment.set_border_width_all(border_width)
	graphsbcomment.set_border_color(Color(mv2, mv2, mv2, 0.9))
	var graphsbcommentselected = make_flat_stylebox(Color(mv, mv, mv, 0.4), gn_margin_side, 24, gn_margin_side, 5)
	graphsbcommentselected.set_border_width_all(border_width)
	graphsbcommentselected.set_border_color(Color(mv2, mv2, mv2, 0.9))
	var graphsbbreakpoint = graphsbselected.duplicate()
	graphsbbreakpoint.set_name("GraphsBBreakpoint")
	graphsbbreakpoint.set_draw_center(false)
	graphsbbreakpoint.set_border_color(warning_color)
	graphsbbreakpoint.set_shadow_color(warning_color * Color(1.0, 1.0, 1.0, 0.1))
	var graphsbposition = graphsbselected.duplicate()
	graphsbposition.set_name("GraphsBPosition")
	graphsbposition.set_draw_center(false)
	graphsbposition.set_border_color(error_color)
	graphsbposition.set_shadow_color(error_color * Color(1.0, 1.0, 1.0, 0.2))

	theme.set_stylebox("frame", "GraphNode", graphsb)
	theme.set_stylebox("selectedframe", "GraphNode", graphsbselected)
	theme.set_stylebox("comment", "GraphNode", graphsbcomment)
	theme.set_stylebox("commentfocus", "GraphNode", graphsbcommentselected)
	theme.set_stylebox("breakpoint", "GraphNode", graphsbbreakpoint)
	theme.set_stylebox("position", "GraphNode", graphsbposition)

	var default_node_color = Color(mv2, mv2, mv2)
	theme.set_color("title_color", "GraphNode", default_node_color)
	default_node_color.a = 0.7
	theme.set_color("close_color", "GraphNode", default_node_color)

	theme.set_constant("port_offset", "GraphNode", 14 * p_scale)
	theme.set_constant("title_h_offset", "GraphNode", -16 * p_scale)
	theme.set_constant("close_h_offset", "GraphNode", 20 * p_scale)
	theme.set_constant("close_offset", "GraphNode", 20 * p_scale)
	theme.set_icon("close", "GraphNode", icon_gui_close_customizable)
	theme.set_icon("resizer", "GraphNode", icon_gui_resizer)
	theme.set_icon("port", "GraphNode", icon_gui_graph_node_port)

	# GridContainer
	theme.set_constant("vseperation", "GridContainer", (DEFAULT_MARGIN_SIZE) * p_scale)

	# ColorPicker
	theme.set_constant("margin", "ColorPicker", popup_margin_size)
	theme.set_constant("sv_width", "ColorPicker", 256 * p_scale)
	theme.set_constant("sv_height", "ColorPicker", 256 * p_scale)
	theme.set_constant("h_width", "ColorPicker", 30 * p_scale)
	theme.set_constant("label_width", "ColorPicker", 10 * p_scale)
	theme.set_icon("screen_picker", "ColorPicker", icon_color_pick)
	theme.set_icon("add_preset", "ColorPicker", icon_add)
	theme.set_icon("preset_bg", "ColorPicker", icon_gui_mini_checkerboard)

	theme.set_icon("bg", "ColorPickerButton", icon_gui_mini_checkerboard)

	# Information on 3D viewport
	var style_info_3d_viewport = style_default.duplicate()
	style_info_3d_viewport.set_name("StyleInfo3DViewport")
	style_info_3d_viewport.set_bg_color(style_info_3d_viewport.get_bg_color() * Color(1, 1, 1, 0.5))
	style_info_3d_viewport.set_border_width_all(0)
	theme.set_stylebox("Information3dViewport", "EditorStyles", style_info_3d_viewport)

	theme.set_color("modulate_color", "Global", EMOTE_PRIMARY_COLOR)

	return theme
