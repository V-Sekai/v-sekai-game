@tool
extends XROrigin3D
class_name SarPlayerSimulationXROrigin3D

# TODO: this class, if part of a vessel, will still add and remove trackers
# even if unpossessed.

var _left_hand_default_controller: XRController3D = null
var _left_hand_aim_controller: XRController3D = null
var _left_hand_grip_controller: XRController3D = null
var _left_hand_palm_controller: XRController3D = null
var _left_hand_skeleton_controller: XRController3D = null

var _right_hand_default_controller: XRController3D = null
var _right_hand_aim_controller: XRController3D = null
var _right_hand_grip_controller: XRController3D = null
var _right_hand_palm_controller: XRController3D = null
var _right_hand_skeleton_controller: XRController3D = null

var _left_hand_tracker: XRController3D = null
var _right_hand_tracker: XRController3D = null

# Adds an XRController3D node as a child and returns it.
# p_tracker_name is the name of the tracker it is meant to represent.
# p_pose is the specific controller pose for this tracker.
# p_packed_scenes is an array of PackedScenes which will be added as children
# to the newly instantiated tracker.
func _add_hand_tracker(p_tracker_name: String, p_pose: String, p_packed_scenes: Array[PackedScene]) -> XRController3D:
	var new_hand_controller: XRController3D = XRController3D.new()
	if new_hand_controller:
		new_hand_controller.tracker = p_tracker_name
		new_hand_controller.pose = p_pose
		new_hand_controller.name = p_tracker_name + "_" + p_pose
		new_hand_controller.show_when_tracked = true

		for packed_scene: PackedScene in p_packed_scenes:
			new_hand_controller.add_child(packed_scene.instantiate())

		add_child(new_hand_controller)
		
		return new_hand_controller
	else:
		printerr("_add_hand_tracker did not contain a valid XRController3D!")
		return null

# Callback to add a Vive tracker to the tracking space.
func _add_vive_tracker(p_tracker_name: String) -> XRController3D:
	var new_hand_controller: XRController3D = XRController3D.new()
	if new_hand_controller:
		new_hand_controller.tracker = p_tracker_name
		new_hand_controller.pose = &"default"
		new_hand_controller.name = "vive_" + str(p_tracker_name.get_file())
		new_hand_controller.show_when_tracked = true

		var cube := MeshInstance3D.new()
		var mesh := PrismMesh.new()
		mesh.size = Vector3(0.03, 0.03, 0.03)
		cube.mesh = mesh
		new_hand_controller.add_child(cube)

		add_child(new_hand_controller)
		
		return new_hand_controller
	else:
		printerr("_add_hand_tracker did not contain a valid XRController3D!")
		return null

# Callback to the tracker_added signal in XRServer.
# Will add required trackers as children.
func _tracker_added(p_tracker_name: String, p_type: int) -> void:
	if not Engine.is_editor_hint() and is_multiplayer_authority():
		if p_type == XRServer.TRACKER_CONTROLLER:
			if p_tracker_name == "left_hand":
				if not _left_hand_default_controller:
					_left_hand_default_controller = _add_hand_tracker("left_hand", "default", left_hand_default_child_scenes)
				if not _left_hand_aim_controller:
					_left_hand_aim_controller = _add_hand_tracker("left_hand", "aim", left_hand_aim_child_scenes)
				if not _left_hand_grip_controller:
					_left_hand_grip_controller = _add_hand_tracker("left_hand", "grip", left_hand_grip_child_scenes)
				if not _left_hand_palm_controller:
					_left_hand_palm_controller = _add_hand_tracker("left_hand", "palm", left_hand_palm_child_scenes)
				if not _left_hand_skeleton_controller:
					_left_hand_skeleton_controller = _add_hand_tracker("left_hand", "skeleton", left_hand_skeleton_child_scenes)
			elif p_tracker_name == "right_hand":
				if not _right_hand_default_controller:
					_right_hand_default_controller = _add_hand_tracker("right_hand", "default", right_hand_default_child_scenes)
				if not _right_hand_aim_controller:
					_right_hand_aim_controller = _add_hand_tracker("right_hand", "aim", right_hand_aim_child_scenes)
				if not _right_hand_grip_controller:
					_right_hand_grip_controller = _add_hand_tracker("right_hand", "grip", right_hand_grip_child_scenes)
				if not _right_hand_palm_controller:
					_right_hand_palm_controller = _add_hand_tracker("right_hand", "palm", right_hand_palm_child_scenes)
				if not _right_hand_skeleton_controller:
					_right_hand_skeleton_controller = _add_hand_tracker("right_hand", "skeleton", right_hand_skeleton_child_scenes)
			else:
				_add_vive_tracker(p_tracker_name)
		elif p_type == XRServer.TRACKER_HAND:
			if p_tracker_name == "/user/hand_tracker/left":
				_left_hand_tracker = _add_hand_tracker("/user/hand_tracker/left", "default", right_hand_skeleton_child_scenes)
			elif p_tracker_name == "/user/hand_tracker/right":
				_right_hand_tracker = _add_hand_tracker("/user/hand_tracker/right", "default", right_hand_skeleton_child_scenes)
			else:
				printerr("Hand tracking for not supported yet for " + str(p_tracker_name))
		elif p_type == XRServer.TRACKER_HEAD:
			pass
		else:
			printerr("Unknown tracker type %s added." % str(p_type))

# Callback to the tracker_removed signal in XRServer.
func _tracker_removed(p_tracker_name: String, p_type: int) -> void:
	if not Engine.is_editor_hint() and is_multiplayer_authority():
		if p_type == XRServer.TRACKER_CONTROLLER:
			if p_tracker_name == "left_hand":
				if _left_hand_aim_controller:
					_left_hand_aim_controller.queue_free()
					remove_child(_left_hand_aim_controller)
					_left_hand_aim_controller = null
				if _left_hand_grip_controller:
					_left_hand_grip_controller.queue_free()
					remove_child(_left_hand_grip_controller)
					_left_hand_grip_controller = null
				if _left_hand_palm_controller:
					_left_hand_palm_controller.queue_free()
					remove_child(_left_hand_palm_controller)
					_left_hand_palm_controller = null
				if _left_hand_skeleton_controller:
					_left_hand_skeleton_controller.queue_free()
					remove_child(_left_hand_skeleton_controller)
					_left_hand_skeleton_controller = null
			elif p_tracker_name == "right_hand":
				if not _right_hand_aim_controller:
					_right_hand_aim_controller.queue_free()
					remove_child(_right_hand_aim_controller)
					_right_hand_aim_controller = null
				if not _right_hand_grip_controller:
					_right_hand_grip_controller.queue_free()
					remove_child(_right_hand_grip_controller)
					_right_hand_grip_controller = null
				if not _right_hand_palm_controller:
					_right_hand_palm_controller.queue_free()
					remove_child(_right_hand_palm_controller)
					_right_hand_palm_controller = null
				if not _right_hand_skeleton_controller:
					_right_hand_skeleton_controller.queue_free()
					remove_child(_right_hand_skeleton_controller)
					_right_hand_skeleton_controller = null
			else:
				var child_name: NodePath = "vive_" + str(p_tracker_name.get_file())
				var child_node: Node = get_node(child_name)
				child_node.queue_free()
				remove_child(child_node)
		elif p_type == XRServer.TRACKER_HAND:
			if p_tracker_name == "/user/hand_tracker/left":
				if _left_hand_tracker:
					_left_hand_tracker.queue_free()
					remove_child(_left_hand_tracker)
					_left_hand_tracker = null
			elif p_tracker_name == "/user/hand_tracker/right":
				if _right_hand_tracker:
					_right_hand_tracker.queue_free()
					remove_child(_right_hand_tracker)
					_right_hand_tracker = null
		elif p_type == XRServer.TRACKER_HEAD:
			pass
		else:
			printerr("Unknown tracker type %s removed." % str(p_type))

# TODO: Look more into this
# I would like to find a less awful way of doing this, but it seems
# that updating the world scale directly can seemingly cause
# precision issues, so I'm moving it to the fixed physics frame.
# That being said, it means we can't really interpolate scale for now, but
# we can look into that later since I think we only have a basic usecase
# for this. Also, FYI: controllers will jitter when doing this.
var _world_scale_centered_new: float = world_scale_centered
var _world_scale_centered_old: float = _world_scale_centered_new
func _update_world_scale_centered() -> void:
	if not Engine.is_editor_hint():
		if _world_scale_centered_old != _world_scale_centered_new:
			# The HMD transform relative to the user's internal playspace.
			var hmd_transform: Transform3D = Transform3D(Basis(), XRServer.get_hmd_transform().origin)
			# The transform if scaled by the previous centered world scale.
			var pre_xr_origin_transform: Transform3D = Transform3D().scaled_local(Vector3(_world_scale_centered_old, _world_scale_centered_old, _world_scale_centered_old))
			# The transform if scaled by the next centered world scale.
			var post_xr_origin_transform: Transform3D = Transform3D().scaled_local(Vector3(_world_scale_centered_new, _world_scale_centered_new, _world_scale_centered_new))
			# The delta offset of the new scaling values.
			var delta: Transform3D = pre_xr_origin_transform.affine_inverse() * post_xr_origin_transform
			# Where the headset would be if scaled by the delta.
			var repositioned_hmd_transform: Transform3D = Transform3D(Basis(), (delta * hmd_transform).origin)
			# The offset difference between the delta repositioned HMD transform and the actual.
			var offset: Vector3 = (repositioned_hmd_transform.affine_inverse() * hmd_transform).origin
			
			# Once we've calculated an offset for the scale we're about to apply,
			# move ourself, the XROrigin, to compensate for the difference.
			translate(Vector3(offset.x, 0.0, offset.z))
			
			# Emit the offset so that other subsystem can compensate for the
			# changes we made to the XROrigin.
			world_scale_center_offset.emit(Vector2(offset.x, offset.z))
			
			# Update the old centered world scale.
			_world_scale_centered_old = _world_scale_centered_new
			
			# Update the actual world scale value.
			world_scale = _world_scale_centered_new
			
func _physics_process(_delta: float) -> void:
	_update_world_scale_centered()
	
func _ready() -> void:
	if not Engine.is_editor_hint():
		_world_scale_centered_old = _world_scale_centered_new
		
		if is_multiplayer_authority():
			# Hands
			var controller_trackers: Dictionary = XRServer.get_trackers(XRServer.TRACKER_ANY)
			for tracker_name in controller_trackers:
				var tracker: XRTracker = controller_trackers[tracker_name]
				_tracker_added(tracker_name, tracker.type)

			# Tracker signals
			assert(XRServer.connect("tracker_added", _tracker_added) == OK)
			assert(XRServer.connect("tracker_removed", _tracker_removed) == OK)
###

## Emitted when world_scale_centered changed.
signal world_scale_center_offset(p_vec2: Vector2)

## Modify this to change the world scale while retaining the camera's
## current horizontal position by shifting the XROrigin around to compensate
## for the difference.
@export_range(0.01, 1000.0) var world_scale_centered: float = 1.0:
	set(p_world_scale_centered):
		if Engine.is_editor_hint():
			world_scale = p_world_scale_centered
		else:
			_world_scale_centered_new = p_world_scale_centered
	get():
		return world_scale
		
## Reference to the XRCamera assigned to this XROrigin.
@export var xr_camera: XRCamera3D = null

## List of scenes which should instantiated on the camera.
@export var head_child_scenes: Array[PackedScene] = []

## List of scenes which should be instantiated on the left hand's default pose.
@export var left_hand_default_child_scenes: Array[PackedScene] = []
## List of scenes which should be instantiated on the left hand's aim pose.
@export var left_hand_aim_child_scenes: Array[PackedScene] = []
## List of scenes which should be instantiated on the left hand's grip pose.
@export var left_hand_grip_child_scenes: Array[PackedScene] = []
## List of scenes which should be instantiated on the left hand's palm pose.
@export var left_hand_palm_child_scenes: Array[PackedScene] = []
## List of scenes which should be instantiated on the left hand's skeleton pose.
@export var left_hand_skeleton_child_scenes: Array[PackedScene] = []

## List of scenes which should be instantiated on the right hand's default pose.
@export var right_hand_default_child_scenes: Array[PackedScene] = []
## List of scenes which should be instantiated on the right hand's aim pose.
@export var right_hand_aim_child_scenes: Array[PackedScene] = []
## List of scenes which should be instantiated on the right hand's grip pose.
@export var right_hand_grip_child_scenes: Array[PackedScene] = []
## List of scenes which should be instantiated on the right hand's palm pose.
@export var right_hand_palm_child_scenes: Array[PackedScene] = []
## List of scenes which should be instantiated on the right hand's skeleton pose.
@export var right_hand_skeleton_child_scenes: Array[PackedScene] = []

## Wrapper method for the XRServer's center_on_hmd command which also
## adjusts XRNode children to compensate for the playspace reset.
## Currently only implements support for XRServer.DONT_RESET_ROTATION and
## keep_height == true
func center_on_hmd(p_rotation_mode: XRServer.RotationMode, p_keep_height: bool) -> void:
	# This whole wrapper functional is kind of a hack:
	# Okay so...calling center_on_hmd doesn't actually update the positions
	# of the controller and camera nodes, meaning that any visual instances
	# attached to them will jitter for a frame, so we need to compensate
	# for all the XR nodes.
	
	# Store the old reference frame.
	var old_reference_frame: Transform3D = XRServer.get_reference_frame()
	old_reference_frame.basis = Basis()
		
	XRServer.center_on_hmd(p_rotation_mode, p_keep_height)
	
	# TODO: implement node compensation for the other modes.
	if p_rotation_mode != XRServer.DONT_RESET_ROTATION:
		return
	
	# Okay so...calling center_on_hmd doesn't actually update the positions
	# of the controller and camera nodes, meaning that any visual instances
	# attached to them will jitter for a frame, so we need to compensate
	# for all the XR nodes.
	# First calculate the delta.
	var new_reference_frame: Transform3D = XRServer.get_reference_frame()
	var delta: Transform3D = Transform3D(
		xr_camera.basis, Vector3()).affine_inverse() * \
		(old_reference_frame.affine_inverse() * new_reference_frame)
	
	# Now apply the delta to all the nodes, and we should be in sync again.
	for node: Node in get_children():
		if node is XRNode3D or node is XRCamera3D:
			node.transform *= Transform3D(Basis(), delta.origin)
