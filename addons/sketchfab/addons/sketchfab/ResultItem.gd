@tool
extends MarginContainer

const SafeData = preload("res://addons/sketchfab/SafeData.gd")
const Utils = preload("res://addons/sketchfab/Utils.gd")

const ModelDialog = preload("res://addons/sketchfab/ModelDialog.tscn")

@onready var user_name = get_node("_/_2/_/UserName")
@onready var model_name = get_node("_/_2/_/ModelName")
@onready var image = get_node("_/_/Image")

var data
var editor_interface :EditorInterface

var dialog

func set_data(data):
	self.data = data

func _enter_tree():
	custom_minimum_size = custom_minimum_size * 1.0

func _ready():
	if data == null:
		return

	model_name.text = SafeData.string(data, "name")

	var user = SafeData.dictionary(data, "user")
	user_name.text = "by %s" % SafeData.string(user, "displayName")

	var thumbnails = SafeData.dictionary(data, "thumbnails")
	var images = SafeData.array(thumbnails, "images")
	image.url = Utils.get_best_size_url(images, self.image.max_size, SafeData)

func _on_Button_pressed():
	dialog = ModelDialog.instantiate()
	dialog.editor_interface = editor_interface
	dialog.set_uid(SafeData.string(data, "uid"))
	add_child(dialog)
	dialog.close_requested.connect(_on_dialog_hide)
	dialog.popup_centered()

func _on_dialog_hide():
	remove_child(dialog)
