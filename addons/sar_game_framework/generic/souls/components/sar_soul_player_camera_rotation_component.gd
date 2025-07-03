@tool
extends Node
class_name SarSoulPlayerCameraRotationComponent

## Component attached to a SarSoul for handling camera rotation via
## defined actions or mouse motion.

const MOUSE_SCALE: float = 0.05

func _is_xr_enabled() -> bool:
	return XRServer.primary_interface != null

func _input(p_event: InputEvent) -> void:
	if not Engine.is_editor_hint() and is_multiplayer_authority():
		var vessel: SarGameEntityVessel3D = soul.get_possessed_vessel()
		if vessel and not _is_xr_enabled():
			var input_component: SarGameEntityComponentVesselInput = (vessel.get_game_entity_interface() as SarGameEntityInterfaceVessel3D).get_input_component()
			if not SarUtils.assert_true(input_component, "SarSoulPlayerCameraRotationComponent: input_component is not available"):
				return
			
			if p_event is InputEventMouseMotion:
				var rotation_velocity: Vector2 = (p_event as InputEventMouseMotion).relative * MOUSE_SCALE
				input_component.set_input_value_for_action("camera_rotation_horizontal", input_component.get_input_value_for_action("camera_rotation_horizontal") + rotation_velocity.x)
				input_component.set_input_value_for_action("camera_rotation_vertical", input_component.get_input_value_for_action("camera_rotation_vertical") + rotation_velocity.y)

func _process(_delta: float) -> void:
	if not Engine.is_editor_hint() and is_multiplayer_authority():
		var vessel: SarGameEntityVessel3D = soul.get_possessed_vessel()
		if vessel:
			var input_component: SarGameEntityComponentVesselInput = (vessel.get_game_entity_interface() as SarGameEntityInterfaceVessel3D).get_input_component()
			if not SarUtils.assert_true(input_component, "SarSoulPlayerCameraRotationComponent: input_component is not available"):
				return

			input_component.set_input_value_for_action("camera_rotation_horizontal", Input.get_axis("rotate_camera_left", "rotate_camera_right"))
			input_component.set_input_value_for_action("camera_rotation_vertical", Input.get_axis("rotate_camera_up", "rotate_camera_down"))

###

## The soul this component is attached to.
@export var soul: SarSoul = null
