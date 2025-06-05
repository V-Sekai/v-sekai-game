@tool
extends SarSimulationComponentAnimator3D
class_name VSKSimulationComponentAnimator3D

## Class inheriting SarSimulationComponentAnimator3D with the additional
## ability to offset the player's avatar to match their look offset
## when played in first-person flat mode.

func _tweak_third_person_avatar_position(p_avatar: SarAvatar3D) -> void:
	# Modify avatar's position to align the look offset to the center point.
	p_avatar.position = Vector3()
	if not _is_xr_enabled():
		var look_offset: Node3D = p_avatar.get_node_or_null("%LookOffset")
		if look_offset:
			var diff: Transform3D = p_avatar.get_parent().global_transform.affine_inverse() * look_offset.global_transform
			p_avatar.position.x -= diff.origin.x
			p_avatar.position.z -= diff.origin.z
			
func _get_motion_scale() -> float:
	var avatar_component: SarGameEntityComponentAvatar3D = simulation.game_entity_interface.get_model_component() as SarGameEntityComponentAvatar3D
	if avatar_component:
		return super._get_motion_scale() * avatar_component.get_motion_scale()
		
	return super._get_motion_scale()

func _process(p_delta: float) -> void:
	super._process(p_delta)
	
	if not Engine.is_editor_hint():
		var model_component: SarGameEntityComponentModel3D = simulation.game_entity_interface.get_model_component()
		if model_component:
			var avatar: SarAvatar3D = model_component.get_model_node() as SarAvatar3D
			if avatar:
				_tweak_third_person_avatar_position(avatar)
