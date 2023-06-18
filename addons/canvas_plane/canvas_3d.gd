# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# canvas_3d.gd
# SPDX-License-Identifier: MIT

@tool
@icon("icon_canvas_3d.svg")
class_name Canvas3D
extends Node3D

const canvas_shader_const = preload("canvas_shader.gdshader")
const canvas_utils_const = preload("canvas_utils.gd")
const function_pointer_receiver_const = preload("function_pointer_receiver.gd")

var _is_dirty: bool = true

@export var offset_ratio: Vector2 = Vector2(0.5, 0.5):
	set = set_offset_ratio

@export var canvas_scale: Vector2 = Vector2(1.0, 1.0):
	set = set_canvas_scale

enum BillboardMode { BILLBOARD_DISABLED, BILLBOARD_ENABLED, BILLBOARD_FIXED_Y, BILLBOARD_PARTICLES }
@export var billboard_mode: BillboardMode = BillboardMode.BILLBOARD_DISABLED:
	set = _set_billboard_mode

@export var interactable: bool = false:
	set = set_interactable

@export var translucent: bool = false:
	set = set_translucent

@export_flags_3d_physics var collision_mask: int = 0
@export_flags_3d_physics var collision_layer: int = 0

var tree_changed: bool = true
var original_canvas_rid: RID = RID()

# Render
var canvas_size: Vector2 = Vector2()
var spatial_root: Node3D = null
var mesh: Mesh = null
var mesh_instance: MeshInstance3D = null
var material: Material = null
var viewport: SubViewport = null
var control_root: Control = null

# Collision
var pointer_receiver: Area3D = null  # function_pointer_receiver_const
var collision_shape: CollisionShape3D = null

# Interaction
var previous_mouse_position: Vector2 = Vector2()
var mouse_mask: int = 0

##
## func get_spatial_origin_to_canvas_position(p_origin: Vector3) -> Vector2:
## 	var transform_scale: Vector2 = Vector2(
## 		global_transform.basis.get_scale().x, global_transform.basis.get_scale().y
## 	)
##
## 	var inverse_transform: Vector2 = Vector2(1.0, 1.0) / transform_scale
## 	var point: Vector2 = Vector2(p_origin.x, p_origin.y) * inverse_transform * inverse_transform
## 	var point: Vector2 = Vector2(p_origin.x, p_origin.y) * inverse_transform * inverse_transform
##
## 	var ratio: Vector2 = (
## 		Vector2(0.5, 0.5)
## 		+ (point / canvas_scale) / ((Vector2(canvas_width, canvas_height) * canvas_scale) * 0.5)
## 	)
## 	ratio.y = 1.0 - ratio.y  # Flip the Y-axis
##
## 	var canvas_position: Vector2 = ratio * Vector2(canvas_width, canvas_height)
##
## 	return canvas_position
##


func _update_aabb() -> void:
	if mesh and mesh_instance:
		if material is BaseMaterial3D and material.billboard_mode == BaseMaterial3D.BILLBOARD_DISABLED:
			var longest_axis_size: float = mesh.get_aabb().get_longest_axis_size()
			mesh_instance.set_custom_aabb(AABB(mesh.get_aabb().position, Vector3(longest_axis_size, longest_axis_size, longest_axis_size)))
		else:
			mesh_instance.set_custom_aabb(AABB())


func _update() -> void:
	_update_control_root()

	var scaled_canvas_size: Vector2 = canvas_size * canvas_utils_const.UI_PIXELS_TO_METER

	var canvas_offset: Vector2 = Vector2((scaled_canvas_size.x * 0.5) - (scaled_canvas_size.x * offset_ratio.x), -(scaled_canvas_size.y * 0.5) + (scaled_canvas_size.y * offset_ratio.y))

	if mesh:
		mesh.set_size(scaled_canvas_size * canvas_scale)

	if mesh_instance:
		mesh_instance.set_position(Vector3(canvas_offset.x, canvas_offset.y, 0))

	_update_aabb()

	clear_dirty_flag()


func get_control_root() -> Control:
	return control_root


func get_control_viewport() -> SubViewport:
	return viewport


func set_offset_ratio(p_offset_ratio: Vector2) -> void:
	offset_ratio = p_offset_ratio


func set_canvas_scale(p_canvas_scale: Vector2) -> void:
	canvas_scale = p_canvas_scale


func set_interactable(p_interactable: bool) -> void:
	interactable = p_interactable


func set_translucent(p_translucent: bool) -> void:
	translucent = p_translucent
	if material:
		material.flags_transparent = translucent


func _set_billboard_mode(p_billboard_mode: BillboardMode) -> void:
	billboard_mode = p_billboard_mode
	if material:
		material.set_shader_parameter("billboard_mode", p_billboard_mode)
	set_dirty_flag()


func _setup_canvas_item() -> void:
	if !control_root.resized.is_connected(self._resized):
		if control_root.resized.connect(self._resized) != OK:
			printerr("Failed to connect control_root.resized signal.")
			return

	original_canvas_rid = control_root.get_canvas()
	RenderingServer.canvas_item_set_parent(control_root.get_canvas_item(), viewport.find_world_2d().get_canvas())


func _set_mesh_material(p_material: Material) -> void:
	if mesh:
		if mesh is PrimitiveMesh:
			mesh.set_material(p_material)
		else:
			mesh.surface_set_material(0, p_material)


func _find_control_root() -> void:
	if tree_changed:
		var new_control_root: Control = canvas_utils_const.find_child_control(self)
		if new_control_root != control_root:
			# Clear up the old control root
			if control_root:
				if control_root.resized.is_connected(self._resized):
					control_root.resized.disconnect(self._resized)
					RenderingServer.canvas_item_set_parent(control_root.get_canvas_item(), original_canvas_rid)

			# Assign the new control rool and give
			control_root = new_control_root
			if control_root:
				_setup_canvas_item()

		tree_changed = false


func _update_control_root() -> void:
	if Engine.is_editor_hint():
		_find_control_root()

	if control_root:
		canvas_size = control_root.size
	else:
		canvas_size = Vector2()

	viewport.size = canvas_size


func set_dirty_flag() -> void:
	#print("set_dirty_flag")
	if !_is_dirty:
		_is_dirty = true
		call_deferred("_update")


func clear_dirty_flag() -> void:
	#print("clear_dirty_flag")
	_is_dirty = false


func _tree_changed() -> void:
	#print("_tree_changed")
	tree_changed = true
	set_dirty_flag()


func _resized() -> void:
	#print("_resized")
	set_dirty_flag()


func _exit_tree():
	if Engine.is_editor_hint():
		if get_tree().tree_changed.is_connected(self._tree_changed):
			get_tree().tree_changed.disconnect(self._tree_changed)
		if control_root:
			if control_root.resized.is_connected(self._resized):
				control_root.resized.disconnect(self._resized)


func _enter_tree():
	if control_root and viewport:
		call_deferred("_setup_canvas_item")


func _ready() -> void:
	spatial_root = Node3D.new()
	spatial_root.set_name("SpatialRoot")
	add_child(spatial_root, true)

	mesh = PlaneMesh.new()
	mesh.orientation = PlaneMesh.FACE_Z

	mesh_instance = MeshInstance3D.new()
	mesh_instance.set_mesh(mesh)
	mesh_instance.set_scale(Vector3(1.0, 1.0, 1.0))
	mesh_instance.set_name("MeshInstance3D")
	mesh_instance.set_skeleton_path(NodePath())

	spatial_root.add_child(mesh_instance, true)
	mesh_instance.set_owner(spatial_root)
	spatial_root.set_owner(null)

	# Collision
	pointer_receiver = function_pointer_receiver_const.new()
	pointer_receiver.set_name("PointerReceiver")

	# FIXME: No on_pointer_release or on_pointer_pressed here. Do we copy from canvas_plane.gd?
	# if pointer_receiver.pointer_pressed.connect(self.on_pointer_pressed) != OK:
	#	printerr("Failed to connect pointer_receiver.pointer_pressed signal.")
	#	return

	# if pointer_receiver.pointer_release.connect(self.on_pointer_release) != OK:
	#	printerr("Failed to connect pointer_receiver.pointer_release signal.")
	#	return

	pointer_receiver.collision_mask = collision_mask
	pointer_receiver.collision_layer = collision_layer
	spatial_root.add_child(pointer_receiver, true)

	collision_shape = CollisionShape3D.new()
	collision_shape.set_name("CollisionShape3D")
	pointer_receiver.add_child(collision_shape, true)

	viewport = SubViewport.new()
	viewport.size = Vector2(0, 0)
	# viewport.hdr = false
	viewport.transparent_bg = true
	# viewport.disable_3d = true
	# viewport.keep_3d_linear = true
	# viewport.usage = SubViewport.USAGE_2D_NO_SAMPLING
	viewport.audio_listener_enable_2d = false
	viewport.audio_listener_enable_3d = false
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.set_name("SubViewport")
	if Engine.is_editor_hint():
		RenderingServer.viewport_attach_canvas(get_viewport().get_viewport_rid(), viewport.find_world_2d().get_canvas())
	else:
		_find_control_root()

	spatial_root.add_child(viewport, true)

	# Generate the unique material
	material = ShaderMaterial.new()
	material.shader = canvas_shader_const
	material.set_shader_parameter("billboard_mode", billboard_mode)

	_update()
	_set_mesh_material(material)

	# Texture
	var texture: ViewportTexture = viewport.get_texture()
	# var flags: int = Texture2D.FLAGS_DEFAULT
	# texture.set_flags(flags)
	material.set_shader_parameter("texture_albedo", texture)

	if Engine.is_editor_hint():
		if get_tree().tree_changed.connect(self._tree_changed) != OK:
			printerr("Could not connect tree_changed")
