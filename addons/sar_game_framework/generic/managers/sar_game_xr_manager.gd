@tool
extends Node
class_name SarGameXRManager

var _xr_interface: XRInterface = null

func _ready() -> void:
	if not Engine.is_editor_hint():
		_xr_interface = XRServer.find_interface("OpenXR")
		if _xr_interface and _xr_interface.is_initialized():
			print("OpenXR initialized successfully.")
			
			# If we're in XR mode, turn off VSync.
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
			
			# Make sure that the default viewport is shown in the headset.
			get_viewport().use_xr = true
		else:
			print("OpenXR not initialized, please check your headset connection.")

func _enter_tree() -> void:
	if not Engine.is_editor_hint():
		add_to_group("xr_managers")
