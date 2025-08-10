@tool
extends Node
class_name SarSimulationComponentSkeletonIK3D

## This class is designed for creating skeleton modifiers.

var _model_component: SarGameEntityComponentModel3D = null

var _avatar: SarAvatar3D

var _skeleton: Skeleton3D

var left_hand_modifier: XRHandModifier3D
var right_hand_modifier: XRHandModifier3D

@export var model_component: SarGameEntityComponentModel3D:
	set(comp):
		_model_component = comp
		_model_component.model_changed.connect(_on_model_changed)
		if _model_component.get_model_node() != null:
			_on_model_changed(_model_component.get_model_node())
	get:
		return _model_component

func _get_motion_scale() -> float:
	return 1.0

# Override to add more IK functionality
func create_ik_modifiers():
	left_hand_modifier = _skeleton.get_node_or_null(^"LeftHandModifier")
	if left_hand_modifier == null:
		left_hand_modifier = XRHandModifier3D.new()
		left_hand_modifier.name = "LeftHandModifier"
		left_hand_modifier.bone_update = XRHandModifier3D.BONE_UPDATE_ROTATION_ONLY
		left_hand_modifier.hand_tracker = &"/user/hand_tracker/left"
		_skeleton.add_child(left_hand_modifier)
		left_hand_modifier.owner = _skeleton.owner
	right_hand_modifier = _skeleton.get_node_or_null(^"RightHandModifier")
	if right_hand_modifier == null:
		right_hand_modifier = XRHandModifier3D.new()
		right_hand_modifier.name = "RightHandModifier"
		right_hand_modifier.bone_update = XRHandModifier3D.BONE_UPDATE_ROTATION_ONLY
		right_hand_modifier.hand_tracker = &"/user/hand_tracker/right"
		_skeleton.add_child(right_hand_modifier)
		right_hand_modifier.owner = _skeleton.owner

func _on_model_changed(p_new_model: SarModel3D):
	_avatar = p_new_model as SarAvatar3D
	_skeleton = null
	if _avatar != null:
		_skeleton = _avatar.general_skeleton
	if _skeleton != null:
		create_ik_modifiers()
		ik_created.emit()

func _ready() -> void:
	if not Engine.is_editor_hint():
		if not SarUtils.assert_true(simulation, "SarSimulationComponentSkeletonIK3D: simulation is not available"):
			return

	_model_component = simulation.game_entity_interface.get_model_component()
	if not SarUtils.assert_true(_model_component, "SarSimulationComponentSkeletonIK3D: _model_component is not available"):
		return
	if _model_component != null:
		_model_component.model_changed.connect(_on_model_changed)
		if _model_component.get_model_node() != null:
			_on_model_changed(_model_component.get_model_node())

signal ik_created
###

## Reference to the root simulation.
@export var simulation: SarSimulationVessel3D = null

### Reference to the simulation's motor component.
#@export var motor: SarSimulationComponentMotor3D = null
