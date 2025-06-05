@tool
extends Node
class_name SarGameSettingsManager

# This class is provides a standardized base for interacting with what should be
# user-configurable project settings.

signal setting_updated(p_setting: String)

func _setting_updated(p_setting) -> void:
	setting_updated.emit(p_setting)

func set_msaa_2d(p_msaa: Viewport.MSAA) -> void:
	get_viewport().msaa_2d = p_msaa

func set_msaa_3d(p_msaa: Viewport.MSAA) -> void:
	get_viewport().msaa_3d = p_msaa
	
static func get_content_scale_mode_string(p_cs_mode: Window.ContentScaleMode) -> String:
	match p_cs_mode:
		Window.ContentScaleMode.CONTENT_SCALE_MODE_CANVAS_ITEMS:
			return "canvas_items"
		Window.ContentScaleMode.CONTENT_SCALE_MODE_VIEWPORT:
			return "viewport"
		_:
			return "disabled"
			
static func get_content_scale_stretch_string(p_cs_stretch: Window.ContentScaleStretch) -> String:
	match p_cs_stretch:
		Window.ContentScaleStretch.CONTENT_SCALE_STRETCH_INTEGER:
			return "integer"
		_:
			return "fractional"
			
func _write_project_setting(
	p_default_cfg: ConfigFile,
	p_custom_cfg: ConfigFile,
	p_section: String,
	p_key: String,
	p_skip_if_default_matches) -> void:
	
	if ProjectSettings.get_setting(p_section + "/" + p_key, "") != p_default_cfg.get_value(p_section, p_key) or not p_skip_if_default_matches:
		p_custom_cfg.set_value(p_section, p_key, ProjectSettings.get_setting(p_section + "/" + p_key, ""))
	else:
		if p_custom_cfg.has_section_key(p_section, p_key):
			p_custom_cfg.erase_section_key(p_section, p_key)
			
func _write_custom_config(p_default_cfg: ConfigFile, p_custom_cfg: ConfigFile) -> void:
	# Rendering
	p_custom_cfg.set_value("rendering", "anti_aliasing/quality/msaa_2d", get_viewport().msaa_2d)
	p_custom_cfg.set_value("rendering", "anti_aliasing/quality/msaa_3d", get_viewport().msaa_3d)
	
	# Display
	p_custom_cfg.set_value("display", "window/size/mode", DisplayServer.window_get_mode())
	p_custom_cfg.set_value("display", "window/vsync/vsync_mode", DisplayServer.window_get_vsync_mode())
	
	p_custom_cfg.set_value("display", "window/stretch/mode", get_content_scale_mode_string(get_window().content_scale_mode))
	p_custom_cfg.set_value("display", "window/stretch/stretch", get_content_scale_stretch_string(get_window().content_scale_stretch))
	
	# Physics
	_write_project_setting(p_default_cfg, p_custom_cfg, "common", "physics_interpolation", true)

func _save_settings() -> void:
	if not Engine.is_editor_hint():
		var default_cfg: ConfigFile = ConfigFile.new()
		
		if FileAccess.file_exists("res://project.godot"):
			var _err_for_default_cfg: Error = default_cfg.load("res://project.godot")
		
			var override_path: String = ProjectSettings.get("application/config/project_settings_override")
			if not override_path.is_empty():
				var custom_cfg: ConfigFile = ConfigFile.new()
				
				if FileAccess.file_exists(override_path):
					var _err_for_custom_cfg: Error = custom_cfg.load(override_path)
				
				if default_cfg and custom_cfg:
					_write_custom_config(default_cfg, custom_cfg)
				
					custom_cfg.save(override_path)

func _enter_tree() -> void:
	if not Engine.is_editor_hint():
		add_to_group("game_settings_managers")

func _exit_tree() -> void:
	_save_settings()
