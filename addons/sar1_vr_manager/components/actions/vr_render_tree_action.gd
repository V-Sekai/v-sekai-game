extends "res://addons/sar1_vr_manager/components/actions/vr_action.gd"  # vr_action.gd

var render_tree: Node3D = null


func _update_visibility() -> void:
	if render_tree:
		if VRManager.xr_active:
			render_tree.show()
		else:
			render_tree.hide()


func set_render_tree(p_render_tree) -> void:
	render_tree = p_render_tree
	_update_visibility()


func _process(_delta: float) -> void:
	if render_tree:
		render_tree.update_render_tree()


func _update_scale(p_scale) -> void:
	if render_tree:
		render_tree.set_scale(Vector3(p_scale, p_scale, p_scale))


func _xr_mode_changed() -> void:
	_update_visibility()


func _ready() -> void:
	super._ready()
	if not tracker:
		return
	if not render_tree:
		return
	tracker.call_deferred("add_child", render_tree, true)

	if VRManager.xr_origin:
		_update_scale(VRManager.xr_origin.get_world_scale())

	assert(VRManager.world_origin_scale_changed.connect(self._update_scale) == OK)
	assert(VRManager.xr_mode_changed.connect(self._xr_mode_changed) == OK)
