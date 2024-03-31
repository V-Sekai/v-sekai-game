@tool
extends Window

const SafeData = preload("res://addons/sketchfab/SafeData.gd")
const Utils = preload("res://addons/sketchfab/Utils.gd")
const Requestor = preload("res://addons/sketchfab/Requestor.gd")
const Api = preload("res://addons/sketchfab/Api.gd")

var api = Api.new()
var downloader

@onready var label_model = get_node("All/_/_/Model")
@onready var label_user = get_node("All/_/_/_/User")
@onready var image = get_node("All/Image")

@onready var info = get_node("All/_3/_/Info")
@onready var license = get_node("All/_3/_/License")

@onready var download = get_node("All/_2/Download")
@onready var progress = get_node("All/_2/ProgressBar")
@onready var size_label = get_node("All/_2/Size")

var uid
var imported_path
var view_url
var download_url
var download_size
var editor_interface

func set_uid(uid):
	self.uid = uid

func _ready():
	$All.visible = false
	var editor_scale = 1.0
	image.custom_minimum_size *= editor_scale
	size *= editor_scale
	self.about_to_popup.connect(_on_about_to_popup)

func _on_about_to_popup():
	if uid == null:
		hide()
		return

	# Setup download button

	if Api.get_token():
		# Request download link
		var result = await api.request_download(uid)
		if get_tree() == null:
			return

		if typeof(result) == TYPE_INT && result == Api.SymbolicErrors.NOT_AUTHORIZED:
			OS.alert("Your session may have expired. Please log in again.", "Not authorized")
			hide()
			return

		if typeof(result) != TYPE_DICTIONARY:
			hide()
			return

		var gtlf = SafeData.dictionary(result, "gltf")
		if gtlf == null or gtlf.size() == 0:
			OS.alert("This model has not a glTF version.", "Sorry")
			hide()
			return

		download_url = SafeData.string(gtlf, "url")
		download_size = SafeData.float(gtlf, "size")
		if download_url == null:
			hide()
			return

		download.text = "Download (%.1f MiB)" % [download_size / (1024 * 1024)]
		
		# Populate other information
		var data = await api.get_model_detail(uid)
		if typeof(data) != TYPE_DICTIONARY:
			hide()
			return


		print("----------DATA---------")
		print(data)
		print("-------------------")

		label_model.text = SafeData.string(data, "name")

		var user = SafeData.dictionary(data, "user")
		label_user.text = "by %s" % SafeData.string(user, "displayName")

		view_url = SafeData.string(data, "viewerUrl")

		var thumbnails = SafeData.dictionary(data, "thumbnails")
		var images = SafeData.array(thumbnails, "images")
		image.url = Utils.get_best_size_url(images, image.get_rect().size.x, SafeData)
		
		var vc = SafeData.float(data, "vertexCount") * 0.001
		var fc = SafeData.float(data, "faceCount") * 0.001
		var ac = bool(SafeData.float(data, "animationCount"))
		info.text = (
			"Vertex count: %.1fk\n" +
			"Face count: %.1fk\n" +
			"Animation: %s") % [
				vc,
				fc,
				"Yes" if ac else "No",
			]

		var license_data = SafeData.dictionary(data, "license")
		license.text = "%s\n(%s)" % [
			SafeData.string(license_data, "fullName"),
			SafeData.string(license_data, "requirements"),
		]
	else:
		download.text = "To download models you need to be logged in."
		download.disabled = true

	$All.visible = true

func open_selected_file(node :Node, filename :String):
	if node is Tree and node.get_selected():
		if node.get_selected().get_text(0) == filename:
			node.emit_signal("item_activated")
	else:
		for child in node.get_children():
			open_selected_file(child, filename) 

func _on_download_pressed():
	if imported_path:
		open_selected_file(editor_interface.get_file_system_dock(), imported_path.get_file())
		hide()
		return

	# Download file

	download.visible = false
	progress.value = 0
	progress.max_value = download_size
	progress.visible = true
	size_label.visible = true
	size_label.text = "    %.1f MiB" % (download_size / (1024 * 1024))
	
	var host_idx = download_url.find("//") + 2
	var path_idx = download_url.find("/", host_idx)
	var host = download_url.substr(host_idx, path_idx - host_idx)
	var path = download_url.right(path_idx)

	downloader = Requestor.new(host, true)

	var dir = DirAccess.open("res://")
	dir.make_dir("res://sketchfab")

	var file_regex = RegEx.new()
	file_regex.compile("[^/]+?\\.zip")
	var filename = file_regex.search(download_url).get_string()
	var zip_path = "res://sketchfab/%s" % filename

	downloader.download_progressed.connect(_on_download_progressed)
	downloader.request(download_url, null, { "download_to": zip_path })
	var result = await downloader.completed
	if result == null:
		return
	downloader.term()
	downloader = null

	if !result.ok || result.code != 200:
		download.visible = true
		progress.visible = false
		size_label.visible = false
		OS.alert(
			"Please check your network connectivity, free disk space and try again.",
			"Download error")
		return

	# Unpack

	progress.show_percentage = false
	size_label.text = "    Model downloaded! Unpacking..."
	await get_tree().process_frame
	if get_tree() == null:
		return

	var out = []
	OS.execute(OS.get_executable_path(), [
		"-s", ProjectSettings.globalize_path("res://addons/sketchfab/unzip.gd"),
		"--zip-to-unpack %s" % ProjectSettings.globalize_path(zip_path),
		"--no-window",
		"--quit",
	], out, true)
	print(out)

	size_label.text = "    Model unpacked into project!"

	# Import and open

	var base_name = filename.substr(0, filename.find(".zip"))
	imported_path = "res://sketchfab/%s/scene.gltf" % base_name
	editor_interface.get_resource_filesystem().scan()
	while not dir.file_exists(imported_path + ".import"):
		await get_tree().process_frame
		if get_tree() == null:
			return
	editor_interface.select_file(imported_path)

	progress.visible = false
	size_label.visible = false
	download.visible = true
	download.text = "OPEN IMPORTED MODEL"

func _on_download_progressed(bytes, total_bytes):
	if get_tree() == null:
		downloader.term()
	progress.value = bytes

func _on_view_on_site_pressed():
	OS.shell_open(view_url)
