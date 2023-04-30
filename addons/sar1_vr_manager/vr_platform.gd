@tool
extends RefCounted

const vr_render_tree_class = preload("vr_render_tree.gd")

var trackers: Array = []

var controller_actions_scene_path: String = "res://addons/sar1_vr_manager/openxr/controller_actions.tscn"
var controller_actions_scene: PackedScene = null

var action_sets: PackedStringArray = PackedStringArray([])

var openxr_config: RefCounted = null


func get_platform_name() -> String:
	return "OpenXR"


func create_render_tree() -> Node3D:
	return vr_render_tree_class.new()


static func create_pose(p_controller: XRController3D, p_name: String, p_pose: StringName, p_tracker: StringName) -> Node3D:
	p_controller.set_name("%s_%s" % [p_tracker, p_name])
	p_controller.set_tracker(p_tracker)  # Set the tracker before the pose name.
	p_controller.set_pose_name(p_pose)

	return p_controller


func create_poses_for_controller(p_controller: XRController3D, p_origin: XROrigin3D) -> void:
	if not p_origin:
		printerr("VRPlatform: Origin does not exist!")
	var model_controller: XRController3D = XRController3D.new()
	var model_origin: XRController3D = create_pose(model_controller, "ModelOrigin", "grip", p_controller.tracker)
	p_origin.add_child(model_origin, true)
	var laser_controller: XRController3D = XRController3D.new()
	var laser_origin: XRController3D = create_pose(laser_controller, "LaserOrigin", "aim", p_controller.tracker)
	p_origin.add_child(laser_origin, true)
	p_controller.laser_origin = laser_origin


func destroy_poses_for_controller(p_controller: XRController3D) -> void:
	if p_controller.laser_origin:
		p_controller.laser_origin.queue_free()

	if p_controller.model_origin:
		p_controller.model_origin.queue_free()


func add_controller(p_controller: XRController3D, p_origin: XROrigin3D):
	var hand: int = p_controller.get_tracker_hand()
	if hand == XRPositionalTracker.TRACKER_HAND_UNKNOWN:
		return
	if hand == XRPositionalTracker.TRACKER_HAND_RIGHT or hand == XRPositionalTracker.TRACKER_HAND_LEFT:
		# TODO: fire 2022-12-18 Handle swapping hands.
		create_poses_for_controller(p_controller, p_origin)
	if controller_actions_scene:
		var controller_actions: Node = controller_actions_scene.instantiate()
		if controller_actions:
			controller_actions.get_tracker_hand(hand)
			p_controller.add_child(controller_actions, true)
			if (
				controller_actions.has_signal("on_action_pressed")
				and controller_actions.has_signal("on_action_released")
			):
				if (
					(controller_actions.connect("on_action_pressed", Callable(p_controller, "_on_action_pressed")))
					!= OK
				):
					printerr("Could not connect signal 'on_action_pressed' !")
				if (
					(controller_actions.connect("on_action_released", Callable(p_controller, "_on_action_released")))
					!= OK
				):
					printerr("Could not connect signal 'on_action_released' !")

				p_controller.get_is_action_pressed_funcref = Callable(controller_actions, "is_action_pressed")
				p_controller.get_analog_funcref = controller_actions.get_vector2


func remove_controller(p_controller: XRController3D, _p_origin: XROrigin3D):
	destroy_poses_for_controller(p_controller)


func pre_setup() -> void:
	print("VR platform pre-setup...")


func setup() -> void:
	print("Setting up VR platform...")

	if ResourceLoader.exists(controller_actions_scene_path):
		controller_actions_scene = ResourceLoader.load(controller_actions_scene_path)
