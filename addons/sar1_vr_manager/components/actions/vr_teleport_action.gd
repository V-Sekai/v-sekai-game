# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vr_teleport_action.gd
# SPDX-License-Identifier: MIT

extends "res://addons/sar1_vr_manager/components/actions/vr_action.gd"

@export var enabled = true:
	set = set_enabled,
	get = get_enabled

const AXIS_MAXIMUM = 0.5

@export var can_teleport_color: Color = Color(0.0, 1.0, 0.0, 1.0)
@export var cant_teleport_color: Color = Color(1.0, 0.0, 0.0, 1.0)
@export var no_collision_color: Color = Color(45.0 / 255.0, 80.0 / 255.0, 220.0 / 255.0, 1.0)
@export var player_height = 1.63:
	set = set_player_height,
	get = get_player_height

@export var player_radius = 0.4:
	set = set_player_radius,
	get = get_player_radius

@export var strength = 2.5
@export var collision_mask: int = 1
@export var margin: float = 0.001

@export var camera: NodePath = NodePath()

@onready var ws = XRServer.world_scale
var origin_node = null
var camera_node = null
var is_on_floor = true
var is_teleporting = false
var teleport_rotation = 0.0
var floor_normal = Vector3(0.0, 1.0, 0.0)
var last_target_transform = Transform3D()
var collision_shape: Shape3D = null
var step_size = 0.5

var locomotion: Node3D = null

@onready var teleport_node: MeshInstance3D = $Teleport
@onready var teleport_material: ShaderMaterial = teleport_node.get_active_material(0)

@onready var target_node: MeshInstance3D = $Target
@onready var target_material: BaseMaterial3D = target_node.get_active_material(0)

@onready var capsule = get_node("Target/Player_figure/Capsule")

#############
# Callbacks #
#############
var can_teleport_funcref


func set_can_teleport_funcref(p_instance: Object, p_function: String) -> void:
	can_teleport_funcref = Callable(p_instance, p_function)


signal teleported(p_transform)


func set_enabled(new_value):
	enabled = new_value
	if enabled:
		set_physics_process(true)


func get_enabled():
	return enabled


func get_player_height():
	return player_height


func set_player_height(p_height):
	player_height = p_height

	if collision_shape:
		collision_shape.height = player_height - (2.0 * player_radius)

	if capsule:
		capsule.mesh.height = player_height - (2.0 * player_radius)
		capsule.position = Vector3(0.0, player_height / 2.0, 0.0)


func get_player_radius():
	return player_radius


func set_player_radius(p_radius):
	player_radius = p_radius

	if collision_shape:
		collision_shape.height = player_height - (2.0 * player_radius)
		collision_shape.radius = player_radius

	if capsule:
		capsule.mesh.height = player_height - (2.0 * player_radius)
		capsule.mesh.radius = player_radius


func _ready():
	super._ready()
	origin_node = find_parent_controller().get_node("..")

	$Teleport.visible = false
	$Target.visible = false

	$Teleport.mesh.size = Vector2(0.05 * ws, 1.0)
	$Target.mesh.size = Vector2(ws, ws)
	$Target/Player_figure.scale = Vector3(ws, ws, ws)

	if camera:
		camera_node = get_node(camera)
	else:
		camera_node = origin_node.get_node("ARVRCamera")

	collision_shape = CapsuleShape3D.new()

	set_player_height(player_height)
	set_player_radius(player_radius)

	locomotion = VRManager.xr_origin.get_component_by_name("LocomotionComponent")


func _process(_delta):
	var controller = find_parent_controller()

	if !origin_node:
		return

	if !camera_node:
		return

	var can_teleport: bool = false
	if can_teleport_funcref.is_valid():
		can_teleport = can_teleport_funcref.call()

	var new_ws = XRServer.world_scale
	if ws != new_ws:
		ws = new_ws
		$Teleport.mesh.size = Vector2(0.05 * ws, 1.0)
		$Target.mesh.size = Vector2(ws, ws)
		$Target/Player_figure.scale = Vector3(ws, ws, ws)

	if !enabled or !can_teleport:
		is_teleporting = false
		$Teleport.visible = false
		$Target.visible = false

		set_physics_process(false)
		return

	if !locomotion:
		return

	# "teleport" is not implemented yet.
	var teleport_pressed: bool = controller.is_button_pressed("teleport") or controller.is_button_pressed("secondary_click")

	if controller and locomotion.movement_controller == controller and (VRManager.vr_user_preferences.movement_type == VRManager.vr_user_preferences.movement_type_enum.MOVEMENT_TYPE_TELEPORT) and teleport_pressed:
		if !is_teleporting:
			is_teleporting = true
			$Teleport.visible = true
			$Target.visible = true
			teleport_rotation = 0.0

		var space = get_world_3d().space
		var state = PhysicsServer3D.space_get_direct_state(space)
		var query = PhysicsShapeQueryParameters3D.new()

		query.collision_mask = collision_mask
		query.margin = margin
		query.shape_rid = collision_shape.get_rid()

		var shape_transform = Transform3D(Basis(Vector3(1.0, 0.0, 0.0), PI * 0.5), Vector3(0.0, player_height / 2.0, 0.0))

		var teleport_global_transform = $Teleport.global_transform
		var target_global_origin = teleport_global_transform.origin
		var down = Vector3(0.0, -1.0 / ws, 0.0)

		var cast_length = 0.0
		var fine_tune = 1.0
		var hit_something = false
		for _i in range(1, 26):
			var new_cast_length = cast_length + (step_size / fine_tune)
			var global_target = Vector3(0.0, 0.0, -new_cast_length)

			var t = global_target.z / strength
			var t2 = t * t

			global_target = teleport_global_transform * (global_target)

			global_target += down * t2

			query.transform = Transform3D(Basis(), global_target) * shape_transform
			var cast_result = state.collide_shape(query, 10)
			if cast_result.is_empty():
				cast_length = new_cast_length
				target_global_origin = global_target
			elif fine_tune <= 16.0:
				fine_tune *= 2.0
			else:
				var collided_at = target_global_origin
				if global_target.y > target_global_origin.y:
					is_on_floor = false
				else:
					var up = Vector3(0.0, 1.0, 0.0)
					var end_pos = target_global_origin - (up * 0.1)
					var parameters: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.new()
					parameters.from = target_global_origin
					parameters.to = end_pos
					var intersects = state.intersect_ray(parameters)
					if intersects.is_empty():
						is_on_floor = false
					else:
						floor_normal = intersects["normal"]
						var dot = floor_normal.dot(up)
						if dot > 0.9:
							is_on_floor = true
						else:
							is_on_floor = false

						collided_at = intersects["position"]

				cast_length += (collided_at - target_global_origin).length()
				target_global_origin = collided_at
				hit_something = true
				break

		teleport_material.set_shader_parameter("scale_t", 1.0 / strength)
		teleport_material.set_shader_parameter("ws", ws)
		teleport_material.set_shader_parameter("length", cast_length)
		if hit_something:
			var color = can_teleport_color
			var normal = Vector3(0.0, 1.0, 0.0)
			if is_on_floor:
				# if we're on the floor we'll reorientate our target to match.
				normal = floor_normal
				can_teleport = true
			else:
				can_teleport = false
				color = cant_teleport_color

			#teleport_rotation += (p_delta * controller.get_joystick_axis(0) * -4.0)

			var target_basis = Basis()
			target_basis.z = (Vector3(teleport_global_transform.basis.z.x, 0.0, teleport_global_transform.basis.z.z).normalized())
			target_basis.y = normal
			target_basis.x = target_basis.y.cross(target_basis.z)
			target_basis.z = target_basis.x.cross(target_basis.y)

			target_basis = target_basis.rotated(normal, teleport_rotation)
			last_target_transform.basis = target_basis
			last_target_transform.origin = target_global_origin + Vector3(0.0, 0.02, 0.0)
			$Target.global_transform = last_target_transform

			teleport_material.set_shader_parameter("mix_color", color)
			target_material.albedo_color = color
			$Target.visible = can_teleport
		else:
			can_teleport = false
			$Target.visible = false
			teleport_material.set_shader_parameter("mix_color", no_collision_color)
	elif is_teleporting:
		if can_teleport:
			var new_transform = last_target_transform
			new_transform.basis.y = Vector3(0.0, 1.0, 0.0)
			new_transform.basis.x = new_transform.basis.y.cross(new_transform.basis.z).normalized()
			new_transform.basis.z = new_transform.basis.x.cross(new_transform.basis.y).normalized()

			var cam_transform = camera_node.transform
			var user_feet_transform = Transform3D()
			user_feet_transform.origin = cam_transform.origin
			user_feet_transform.origin.y = 0  # the feet are on the ground, but have the same X,Z as the camera

			user_feet_transform.basis.y = Vector3(0.0, 1.0, 0.0)
			user_feet_transform.basis.x = (user_feet_transform.basis.y.cross(cam_transform.basis.z).normalized())
			user_feet_transform.basis.z = (user_feet_transform.basis.x.cross(user_feet_transform.basis.y).normalized())

			teleported.emit(new_transform * user_feet_transform.inverse())

		is_teleporting = false
		$Teleport.visible = false
		$Target.visible = false
