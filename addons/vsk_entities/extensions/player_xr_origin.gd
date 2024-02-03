extends XROrigin3D

@export var xr_camera: XRCamera3D = null
var left_hand_controller: XRController3D = null
var right_hand_controller: XRController3D = null

@export var player_movement_controller: Node = null

@export var xr_camera_scene: PackedScene = null

@export var head_child_scenes: Array[PackedScene] = []
@export var left_hand_child_scenes: Array[PackedScene] = []
@export var right_hand_child_scenes: Array[PackedScene] = []

##
## Adds an XRCamera3D node as a child and returns it.
## p_packed_scenes is an array of PackedScenes which will be added as children
## to the newly instantiated tracker.
##
func _add_xr_camera(p_packed_scenes: Array[PackedScene]) -> XRCamera3D:
	var new_xr_camera = xr_camera_scene.instantiate()
	new_xr_camera.name = "xr_camera"
	for packed_scene in p_packed_scenes:
		new_xr_camera.add_child(packed_scene.instantiate())

	add_child(new_xr_camera)
	
	return new_xr_camera

##
## Adds an XRController3D node as a child and returns it.
## p_tracker_name is the name of the tracker it is meant to represent.
## p_pose is the specific controller pose for this tracker.
## p_packed_scenes is an array of PackedScenes which will be added as children
## to the newly instantiated tracker.
##
func _add_hand_tracker(p_tracker_name: String, p_pose: String, p_packed_scenes: Array[PackedScene]) -> XRController3D:
	var new_hand_controller: XRController3D = XRController3D.new()
	new_hand_controller.tracker = p_tracker_name
	new_hand_controller.pose = p_pose
	new_hand_controller.name = p_tracker_name + "_" + p_pose

	for packed_scene in p_packed_scenes:
		new_hand_controller.add_child(packed_scene.instantiate())

	add_child(new_hand_controller)
	
	return new_hand_controller

##
## Callback to the tracker_added signal in XRServer.
## Will add required trackers as children.
##
func _tracker_added(p_tracker_name: String, p_type: int) -> void:
	if p_type == XRServer.TRACKER_CONTROLLER:
		if p_tracker_name == "left_hand":
			if not left_hand_controller:
				left_hand_controller = _add_hand_tracker("left_hand", "aim", left_hand_child_scenes)
		if p_tracker_name == "right_hand":
			if not right_hand_controller:
				right_hand_controller = _add_hand_tracker("right_hand", "aim", right_hand_child_scenes)

##
## Callback to the tracker_removed signal in XRServer.
##
func _tracker_removed(p_tracker_name: String, p_type: int) -> void:
	if p_type == XRServer.TRACKER_CONTROLLER:
		if p_tracker_name == "left_hand":
			if left_hand_controller:
				left_hand_controller.queue_free()
				remove_child(left_hand_controller)
				left_hand_controller = null
		if p_tracker_name == "right_hand":
			if not right_hand_controller:
				right_hand_controller.queue_free()
				remove_child(right_hand_controller)
				right_hand_controller = null

func _ready() -> void:
	if is_multiplayer_authority():
		# Hands
		var controller_trackers: Dictionary = XRServer.get_trackers(XRServer.TRACKER_CONTROLLER)
		if controller_trackers.has("left_hand"):
			left_hand_controller = _add_hand_tracker("left_hand", "aim", left_hand_child_scenes)
		if controller_trackers.has("right_hand"):
			right_hand_controller = _add_hand_tracker("right_hand", "aim", right_hand_child_scenes)

		# Tracker signals
		assert(XRServer.connect("tracker_added", _tracker_added) == OK)
		assert(XRServer.connect("tracker_removed", _tracker_removed) == OK)
