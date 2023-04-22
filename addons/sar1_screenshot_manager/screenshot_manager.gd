@tool
extends Node

const screenshot_manager_const = preload("res://addons/sar1_screenshot_manager/screenshot_manager.gd")

var pending: bool = false
var image_thread: Thread = Thread.new()

signal screenshot_requested(p_info, p_callback)
signal screenshot_saved(p_path)
signal screenshot_failed(p_path, p_err)

const MAX_INCREMENTAL_FILES = 99999
const INCREMENTAL_DIGIT_LENGTH = 5

##############
# Screenshot #
##############


# OpenGL backend requires screenshots to be flipped on the Y-axis
static func apply_screenshot_flip(p_image: Image) -> Image:
	p_image.flip_y()
	return p_image


static func _get_screenshot_path_and_prefix(p_screenshot_directory: String) -> String:
	return "%s/screenshot_" % p_screenshot_directory


static func _incremental_screenshot(p_info: Dictionary) -> Dictionary:
	var err: int = OK
	var path: String = ""

	var screenshot_directory: String = p_info["screenshot_directory"]

	var screenshot_number: int = 0
	var screenshot_path_and_prefix: String = _get_screenshot_path_and_prefix(screenshot_directory)
	while FileAccess.file_exists(
		screenshot_path_and_prefix + str(screenshot_number).pad_zeros(INCREMENTAL_DIGIT_LENGTH) + ".png"
	):
		screenshot_number += 1

	if screenshot_number <= MAX_INCREMENTAL_FILES:
		path = screenshot_path_and_prefix + str(screenshot_number).pad_zeros(INCREMENTAL_DIGIT_LENGTH) + ".png"
	else:
		err = FAILED

	return {"error": err, "path": path}


static func _date_and_time_screenshot(p_info: Dictionary) -> Dictionary:
	var err: int = OK
	var path: String = ""

	var screenshot_directory: String = p_info["screenshot_directory"]

	var screenshot_path_and_prefix: String = _get_screenshot_path_and_prefix(screenshot_directory)
	var time: Dictionary = Time.get_datetime_dict_from_system()
	var date_time_string: String = (
		"%s_%02d_%02d_%02d%02d%02d"
		% [time["year"], time["month"], time["day"], time["hour"], time["minute"], time["second"]]
	)

	if !FileAccess.file_exists(screenshot_path_and_prefix + date_time_string + ".png"):
		path = screenshot_path_and_prefix + date_time_string + ".png"
	else:
		err = ERR_FILE_ALREADY_IN_USE

	return {"error": err, "path": path}


func _unsafe_serialize_screenshot(p_userdata: Dictionary) -> Dictionary:
	var info: Dictionary = p_userdata["info"]
	var image: Image = p_userdata["image"]

	var screenshot_path_callback: Callable = info["screenshot_path_callback"]
	var error: int = FAILED

	var result: Dictionary = screenshot_path_callback.call(info)
	error = result["error"]
	if error == OK:
		error = screenshot_manager_const.apply_screenshot_flip(image).save_png(result["path"])

	call_deferred("_serialize_screenshot_done")

	return {"error": error, "path": result["path"]}


func _serialize_screenshot_done() -> void:
	var result: Dictionary = image_thread.wait_to_finish()
	var err: int = result["error"]
	var path: String = result["path"]
	print("Screenshot serialised at '%s' with error code: %s" % [path, str(err)])

	pending = false
	if err == OK:
		screenshot_saved.emit(path)
	else:
		screenshot_failed.emit(path, err)


func _screenshot_captured(p_info: Dictionary, p_image: Image) -> void:
	if p_image != null:
		var directory_ready: bool = false
		var screenshot_directory: String = p_info["screenshot_directory"]

		var dir: DirAccess = DirAccess.open("user://")
		if dir:
			if dir.dir_exists(screenshot_directory):
				directory_ready = true
			else:
				if dir.make_dir(screenshot_directory) == OK:
					directory_ready = true

		if directory_ready:
			var callable: Callable = self._unsafe_serialize_screenshot
			callable = callable.bind({"image": p_image, "info": p_info})
			if image_thread.start(callable) != OK:
				printerr("Could not create start processing thread!")


func capture_screenshot(p_info: Dictionary) -> void:
	if !pending:
		pending = true
		print("Capturing screenshot (%s)..." % p_info["screenshot_type"])

		screenshot_requested.emit(p_info, self._screenshot_captured)


func _input(p_event: InputEvent) -> void:
	if !Engine.is_editor_hint():
		if p_event.is_action_pressed("screenshot"):
			capture_screenshot(
				{
					"screenshot_path_callback": Callable(self, "_date_and_time_screenshot"),
					"screenshot_type": "screenshot",
					"screenshot_directory": "user://screenshots"
				}
			)


func _ready():
	process_mode = PROCESS_MODE_ALWAYS
