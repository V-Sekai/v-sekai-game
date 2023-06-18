# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# node_textureRectUrl.gd
# SPDX-License-Identifier: MIT

@tool
extends TextureRect

# Modified by Saracen 2022

var request_in_progress: String = ""
var http: HTTPRequest
var progress_texture = TextureProgressBar.new()
var file_name = ""
var file_ext = ""

@export var textureUrl = "":
	set = _setTextureUrl

@export var storeCache: bool = true
@export var everCache: bool = false  # Ever load from cache after the first acess
@export var preloadImage: bool = true

@export var progressbar: bool = true:
	set = _setProgressbar

@export var progressbarRect: Rect2 = Rect2(0, 0, 0, 0)
@export var progressbarColor: Color = Color.RED

signal loaded(image, fromCache)
signal progress(percent)


func _setProgressbar(newValue):
	progressbar = newValue
	_adjustProgress()


func _setTextureUrl(newValue):
	textureUrl = newValue
	if preloadImage and is_inside_tree():
		_loadImage(false)


func _loadImage(p_cache_only):
	if textureUrl.is_empty():
		return

	var dt = textureUrl.split(":")
	if dt[0] == "data":
		_base64texture(textureUrl)
		return

	var spl = textureUrl.split("/")
	file_name = spl[spl.size() - 1]

	if not self.request_in_progress.is_empty():
		push_warning("Canceling current request " + str(self.request_in_progress))
		http.cancel_request()
		_recreateHttp()
	http.download_file = ""

	var file_name_stripped = file_name.split("?")[0]
	var ext = file_name_stripped.split(".")
	file_ext = ext[ext.size() - 1].to_lower()

	if not file_ext.is_empty():
		var doFileExists = FileAccess.file_exists(str("user://image_cache/", file_name.sha256_text() + "." + file_ext))
		if doFileExists:
			var _image = Image.new()
			if _image.load(str("user://image_cache/", file_name.sha256_text() + "." + file_ext)) == OK:
				var _texture = ImageTexture.create_from_image(_image)

				texture = _texture

				progress_texture.hide()
				loaded.emit(_texture, true)

				if everCache:
					return

		elif storeCache:
			# Add cache directory
			var dir: DirAccess = DirAccess.open("user://")
			var _err = dir.make_dir("image_cache")

			http.download_file = str("user://image_cache/", file_name.sha256_text() + "." + file_ext)

		if !p_cache_only:
			_downloadImage()


func _downloadImage():
	if not textureUrl.is_empty():
		set_process(true)
		_adjustProgress()
		http.use_threads = true
		self.request_in_progress = textureUrl
		print("Starting request for " + str(textureUrl))
		http.request(textureUrl)


func _recreateHttp():
	if http != null:
		http.queue_free()
	http = HTTPRequest.new()
	http.name = "http"
	http.use_threads = true
	http.request_completed.connect(self._on_HTTPRequest_request_completed)
	add_child(http, true)


func _ready():
	add_to_group("TextureRectUrl")
	add_child(progress_texture, true)
	progress_texture.hide()
	_recreateHttp()

	set_process(false)
	_loadImage(false)


func _adjustProgress():
	if progressbar:
		progress_texture.nine_patch_stretch = true
		progress_texture.texture_progress = load("res://addons/textureRectUrl/rect.png")
		progress_texture.tint_progress = progressbarColor
		progress_texture.show()
		progress_texture.value = 0
		progress_texture.size_flags_horizontal = SIZE_SHRINK_END
		progress_texture.size_flags_vertical = SIZE_SHRINK_END
		if progressbarRect.size.x == 0:
			progress_texture.size.x = size.x * 4 / 5
		else:
			progress_texture.size.x = progressbarRect.size.x

		if progressbarRect.size.y == 0:
			progress_texture.size.y = size.y / 10
		else:
			progress_texture.size.y = progressbarRect.size.y
		if progressbarRect.position.x == 0:
			progress_texture.position.x = 0
		else:
			progress_texture.position.x = progressbarRect.position.x

		if progressbarRect.position.y == 0:
			progress_texture.position.y = 0
		else:
			progress_texture.position.y = progressbarRect.position.y


func _on_HTTPRequest_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray):
	var this_url = self.request_in_progress
	self.request_in_progress = ""
	if response_code == 200:
		if body.size():
			var image = Image.new()
			var image_error = null

			if file_ext == "png":
				image_error = image.load_png_from_buffer(body)
			elif file_ext == "jpg" or file_ext == "jpeg":
				image_error = image.load_jpg_from_buffer(body)
			elif file_ext == "webp":
				image_error = image.load_webp_from_buffer(body)

			set_process(false)
			if image_error == OK:
				print("Request completed successfully for " + this_url + ": " + str(image.get_width()) + "x" + str(image.get_height()))
				# An error did not occur while trying to display the image

				var _texture = ImageTexture.create_from_image(image)

				if !Engine.is_editor_hint():
					loaded.emit(image, false)

				progress_texture.value = 0
				progress_texture.hide()

				# Assign a downloaded texture
				texture = _texture
			else:
				print("Request completed but failed to parse for " + this_url + " ext " + str(file_ext))
		else:
			_loadImage(true)
	else:
		print("Request failed for " + this_url + " with result " + str(result) + " and code " + str(response_code))


func _process(_delta):
	# show progressbar
	var bodySize = http.get_body_size()
	var downloadedBytes = http.get_downloaded_bytes()
	var percent = int(downloadedBytes * 100 / bodySize)

	progress.emit(percent)

	if progressbar:
		progress_texture.value = percent


func _base64texture(image64):
	var tmp = image64.split(",")[1]
	var image = Image.new()
	var err = image.load_png_from_buffer(Marshalls.base64_to_raw(tmp))
	if err == OK:
		if !Engine.is_editor_hint():
			progress_texture.hide()
			loaded.emit(image, false)
		return
	var image_texture: ImageTexture = ImageTexture.create_from_image(image)
	texture = image_texture

	if !Engine.is_editor_hint():
		progress_texture.hide()
		loaded.emit(image, false)
