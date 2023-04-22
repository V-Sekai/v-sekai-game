@tool
extends EditorPlugin

var uro_logo_png = load("res://addons/vsk_editor/uro_logo.png")
var editor_interface: EditorInterface = null
var undo_redo: EditorUndoRedoManager = null
var uro_button: Button = null


func _init():
	print("Initialising VSKEditor plugin")


func _notification(p_notification: int):
	match p_notification:
		NOTIFICATION_PREDELETE:
			print("Destroying VSKEditor plugin")


func _get_plugin_name() -> String:
	return "VSKEditor"


func setup_vskeditor(
	viewport: Viewport, button: Button, editor_interface: EditorInterface, undo_redo: EditorUndoRedoManager
) -> void:
	var vsk_editor: Node = get_node_or_null("/root/VSKEditor")
	assert(vsk_editor)

	vsk_editor.setup_editor(editor_interface.get_editor_main_screen(), button, editor_interface)


func _enter_tree() -> void:
	editor_interface = get_editor_interface()
	undo_redo = get_undo_redo()

	add_autoload_singleton("VSKEditor", "res://addons/vsk_editor/vsk_editor.gd")

	uro_button = Button.new()
	uro_button.set_text("Uro")
	uro_button.set_button_icon(uro_logo_png)
	uro_button.set_tooltip_text("Access the Uro Menu.")
	uro_button.set_flat(true)
	uro_button.set_disabled(false)  # true

	add_control_to_container(CONTAINER_TOOLBAR, uro_button)

	# FIXME: WAT. The next link can't be rsun because we haven't run the previous line yet.
	# but now this creates a syntax error :'-(
	# Existing projects won't have this problem because VSKEditor is already defined as singleton
	# from the previous iteration
	call_deferred("setup_vskeditor", editor_interface.get_viewport(), uro_button, editor_interface, undo_redo)

	uro_button.call_deferred("set_disabled", false)  # What keeps disabling this button?!


func _exit_tree() -> void:
	remove_control_from_container(CONTAINER_TOOLBAR, uro_button)
	remove_autoload_singleton("VSKEditor")

	if uro_button:
		if uro_button.is_inside_tree():
			uro_button.get_parent().remove_child(uro_button)
		uro_button.queue_free()
