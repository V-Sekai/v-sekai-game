extends Control
class_name VSKUIViewWelcome

signal sign_in_pressed
signal register_pressed
signal skip_pressed

func _sign_in_button_pressed() -> void:
	sign_in_pressed.emit()
	
func _register_button_pressed() -> void:
	register_pressed.emit()
	
func _skip_button_pressed() -> void:
	skip_pressed.emit()

func _ready():
	if XRServer.primary_interface != null and XRServer.primary_interface.is_initialized():
		push_error("FIXME XRXRXR HACK: The main menu is being auto-skipped because XR support is not yet implemented!")
		await get_tree().process_frame
		_skip_button_pressed()
