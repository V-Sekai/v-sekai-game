extends Node3D

const SPEED = 10.0

func _ready() -> void:
	VRManager.vr_user_preferences.vr_mode_enabled = true
	VRManager.initialise_vr_interface()

	get_viewport().use_xr = true
	get_viewport().size = VRManager.xr_interface.get_render_targetsize()

	$ARVROrigin.set_process_internal(false)

func _vr_process(p_delta: float) -> void:
	$ARVROrigin.translate(Vector3(1.0, 0.0, 0.0) * SPEED * p_delta)
	$ARVROrigin._cache_world_origin_transform()
	$ARVROrigin._update_tracked_camera()

func _process(p_delta: float) -> void:
	_vr_process(p_delta)
