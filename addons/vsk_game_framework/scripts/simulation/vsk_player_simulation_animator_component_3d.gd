@tool
extends SarSimulationComponentAnimator3D
class_name VSKSimulationComponentAnimator3D

## Class inheriting SarSimulationComponentAnimator3D with the additional
## ability to offset the player's avatar to match their look offset
## when played in first-person flat mode.

func _tweak_third_person_avatar_position(p_avatar: SarAvatar3D) -> void:
	# Modify avatar's position to align the look offset to the center point.
	p_avatar.position = Vector3()
	
	# Note: this now uses local space rather than global space but could
	# still be unstable.
	# I can't notice a specific problem myself, but it might be affected by
	# using IK tracking in flat mode.
	if not _is_xr_enabled():
		var look_offset: Node3D = p_avatar.get_node_or_null("%LookOffset")
		if look_offset:
			# Traverse from look_offset up to p_avatar to get combined local offset.
			var current: Node3D = look_offset
			var combined_transform: Transform3D = Transform3D()
			while not current and current != p_avatar:
				combined_transform = current.transform * combined_transform
				current = current.get_parent()
			
			# Only apply if we successfully reached p_avatar in hierarchy.
			if current == p_avatar:
				# Convert offset to parent's coordinate space.
				var local_offset: Vector3 = p_avatar.transform * combined_transform.origin
				p_avatar.position.x -= local_offset.x
				p_avatar.position.z -= local_offset.z
			
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
