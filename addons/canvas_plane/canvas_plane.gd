# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# canvas_plane.gd
# SPDX-License-Identifier: MIT

@tool
@icon("icon_canvas_3d.svg")
class_name CanvasPlane
extends Node3D

const function_pointer_receiver_const = preload("function_pointer_receiver.gd")

@export_range(0.0, 1.0) var canvas_anchor_x: float = 0.0:
	set = set_canvas_anchor_x

@export_range(0.0, 1.0) var canvas_anchor_y: float = 0.0:
	set = set_canvas_anchor_y

# Defaults to 16:9
@export var canvas_width: float = DisplayServer.window_get_size(0).x:
	set = set_canvas_width

@export var canvas_height: float = DisplayServer.window_get_size(0).y:
	set = set_canvas_height

@export var canvas_scale: float = 0.01:
	set = set_canvas_scale

@export var interactable: bool = false:
	set = set_interactable

@export var translucent: bool = false:
	set = set_translucent

@export_flags_3d_physics var collision_mask: int = 2
@export_flags_3d_physics var collision_layer: int = 2

# Render
var spatial_root: Node3D = null
var mesh: Mesh = null
var mesh_instance: MeshInstance3D = null
var material: Material = null
var viewport: SubViewport = null
var control_root: Control = null

# Collision
var pointer_receiver: Area3D = null
var collision_shape: CollisionShape3D = CollisionShape3D.new()

# Interaction
var previous_mouse_position: Vector2 = Vector2()
var mouse_mask: int = 0


func global_to_viewport(p_origin: Vector3) -> Vector2:
	print(p_origin)
	print(global_transform)
	print(canvas_width)
	print(canvas_height)
	print(canvas_scale)	
	var transform_scale: Vector2 = Vector2(global_transform.basis.get_scale().x, global_transform.basis.get_scale().y)
	var inverse_transform: Vector2 = Vector2(1.0, 1.0) / transform_scale
	var point: Vector2 = Vector2(p_origin.x, p_origin.y) * inverse_transform * inverse_transform
	var ratio: Vector2 = Vector2(0.5, 0.5) + (point / canvas_scale) / ((Vector2(canvas_width, canvas_height) * canvas_scale) * 0.5)
	ratio.y = 1.0 - ratio.y  # Flip the Y-axis
	var canvas_position: Vector2 = ratio * Vector2(canvas_width, canvas_height)
	print(canvas_position)
	return canvas_position


func _update() -> void:
	var canvas_width_offset: float = (canvas_width * 0.5 * 0.5) - (canvas_width * 0.5 * canvas_anchor_x)
	var canvas_height_offset: float = -(canvas_height * 0.5 * 0.5) + (canvas_height * 0.5 * canvas_anchor_y)

	if mesh:
		mesh.set_size(Vector2(canvas_width, canvas_height) * 0.5)

	if mesh_instance:
		mesh_instance.set_position(Vector3(canvas_width_offset, canvas_height_offset, 0))

	if pointer_receiver == null:
		pointer_receiver = function_pointer_receiver_const.new()
		spatial_root.add_child(pointer_receiver)
	pointer_receiver.set_position(Vector3(canvas_width_offset, canvas_height_offset, 0))
	if collision_shape:
		if interactable:
			var box_shape = BoxShape3D.new()
			box_shape.set_size(Vector3(canvas_width * 0.5, canvas_height * 0.5, 0.0))
			collision_shape.set_shape(box_shape)

			pointer_receiver.add_child(collision_shape)
			pointer_receiver.set_name("PointerReceiver")
			pointer_receiver.collision_mask = collision_mask
			pointer_receiver.collision_layer = collision_layer

			if pointer_receiver.pointer_pressed.connect(Callable(self, "on_pointer_pressed")) != OK:
				printerr("Failed to connect pointer_receiver.pointer_pressed signal.")

			if pointer_receiver.pointer_release.connect(Callable(self, "on_pointer_release")) != OK:
				printerr("Failed to connect pointer_receiver.pointer_release signal.")

			if pointer_receiver.pointer_moved.connect(Callable(self, "on_pointer_moved")) != OK:
				printerr("Failed to connect pointer_receiver.pointer_moved signal.")
		else:
			collision_shape.set_shape(null)

	if spatial_root:
		spatial_root.set_scale(Vector3(canvas_scale, canvas_scale, canvas_scale))


func get_control_root() -> Control:
	return control_root


func get_control_viewport() -> SubViewport:
	return viewport


func set_canvas_anchor_x(p_anchor: float) -> void:
	canvas_anchor_x = p_anchor
	set_process(true)


func set_canvas_anchor_y(p_anchor: float) -> void:
	canvas_anchor_y = p_anchor
	set_process(true)


func set_canvas_width(p_width: float) -> void:
	canvas_width = p_width
	set_process(true)


func set_canvas_height(p_height: float) -> void:
	canvas_height = p_height
	set_process(true)


func set_canvas_scale(p_scale: float) -> void:
	canvas_scale = p_scale
	set_process(true)


func set_interactable(p_interactable: bool) -> void:
	interactable = p_interactable
	set_process(true)


func set_translucent(p_translucent: bool) -> void:
	translucent = p_translucent
	if material:
		material.flags_transparent = translucent


func _set_mesh_material(p_material: Material) -> void:
	if mesh:
		if mesh is PrimitiveMesh:
			mesh.set_material(p_material)
		else:
			mesh.surface_set_material(0, p_material)


func on_pointer_moved(from: Vector3, to: Vector3):
	var local_from: Vector2 = global_to_viewport(from)
	var local_to: Vector2 = global_to_viewport(to)

	# Let's mimic a mouse
	var event = InputEventMouseMotion.new()
	event.set_global_position(local_to)
	event.set_relative(local_to - local_from) # should this be scaled/warped?
	event.set_button_mask(mouse_mask)
	event.set_pressure(0.5)

	if viewport:
		viewport.push_input(event)
	previous_mouse_position = local_to


func on_pointer_pressed(at: Vector3, p_doubleclick: bool):
	var local_at: Vector2 = global_to_viewport(at)

	# Let's mimic a mouse
	mouse_mask = 1
	var event = InputEventMouseButton.new()
	event.set_button_index(1)
	event.set_pressed(true)
	event.set_global_position(local_at)
	event.set_button_mask(mouse_mask)
	event.set_double_click(p_doubleclick)

	if viewport:
		viewport.push_unhandled_input(event)
	previous_mouse_position = local_at


func on_pointer_release(at: Vector3, p_doubleclick: bool):
	var local_at: Vector2 = global_to_viewport(at)

	# Let's mimic a mouse
	mouse_mask = 0
	var event = InputEventMouseButton.new()
	event.set_button_index(1)
	event.set_pressed(false)
	event.set_global_position(local_at)
	event.set_button_mask(mouse_mask)
	event.set_double_click(p_doubleclick)

	if viewport:
		viewport.push_unhandled_input(event)
	previous_mouse_position = local_at

func _process(_delta: float) -> void:
	_update()
	set_process(false)


func _init():
	spatial_root = Node3D.new()
	viewport = SubViewport.new()
	control_root = Control.new()


func _setup_viewport() -> void:
	spatial_root.set_name("SpatialRoot")
	add_child(spatial_root, true)

	viewport.size = Vector2(canvas_width, canvas_height)
	# viewport.hdr = false
	viewport.transparent_bg = true
	# viewport.disable_3d = true
	# viewport.keep_3d_linear = true
	# viewport.usage = SubViewport.USAGE_2D_NO_SAMPLING
	viewport.audio_listener_enable_2d = false
	viewport.audio_listener_enable_3d = false
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.set_name("SubViewport")
	spatial_root.add_child(viewport, true)

	control_root.set_name("ControlRoot")
	control_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	viewport.add_child(control_root, true)

	if not Engine.is_editor_hint():
		for child in get_children():
			if child.owner != null:
				child.get_parent().remove_child(child)
				control_root.add_child(child, true)


func _ready() -> void:
	_setup_viewport()

	mesh = PlaneMesh.new()

	mesh_instance = MeshInstance3D.new()
	mesh_instance.set_mesh(mesh)
	mesh_instance.rotate_x(-PI / 2)
	mesh_instance.set_scale(Vector3(1.0, -1.0, -1.0))
	mesh_instance.set_name("MeshInstance3D")
	mesh_instance.set_skeleton_path(NodePath())
	mesh_instance.set_cast_shadows_setting(GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
	spatial_root.add_child(mesh_instance, true)

	# Generate the unique material
	material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.set_flag(BaseMaterial3D.FLAG_ALBEDO_TEXTURE_FORCE_SRGB, true)

	# Texture
	# var flags: int = 0
	var texture: Texture2D = viewport.get_texture()
	# FIXME: No way to set FILTER and MIPMAPS on viewport textures
	#flags |= Texture2D.FLAG_FILTER
	#flags |= Texture2D.FLAG_MIPMAPS
	#texture.set_flags(flags)
	if not Engine.is_editor_hint():
		material.albedo_texture = texture

	_update()
	_set_mesh_material(material)
