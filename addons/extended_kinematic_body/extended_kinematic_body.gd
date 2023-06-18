# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# extended_kinematic_body.gd
# SPDX-License-Identifier: MIT

extends CharacterBody3D

var virtual_step_offset: float = 0.0

@export var up: Vector3 = Vector3(0.0, 1.0, 0.0)
@export var step_height: float = 0.2
@export var anti_bump_factor: float = 0.75
@export var slope_stop_min_velocity: float = 0.05
@export var slope_max_angle: float = deg_to_rad(45)
@export var infinite_interia: bool = false

var is_grounded: bool = false

@onready var exclusion_array: Array = [self]


static func get_sphere_query_parameters(p_transform, p_radius, p_mask, p_exclude) -> PhysicsShapeQueryParameters3D:
	var query: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
	query.set_transform(p_transform)
	var shape: SphereShape3D = SphereShape3D.new()
	shape.set_radius(p_radius)
	shape.set_mask(p_mask)
	shape.set_exclude(p_exclude)

	return query


static func get_capsule_query_parameters(p_transform, p_height, p_radius, p_mask, p_exclude) -> PhysicsShapeQueryParameters3D:
	var query: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
	query.set_transform(p_transform)
	var shape: CapsuleShape3D = CapsuleShape3D.new()
	shape.set_height(p_height)
	shape.set_radius(p_radius)
	shape.set_mask(p_mask)
	shape.set_exclude(p_exclude)

	return query


static func test_slope(p_normal, p_up, p_slope_max_angle) -> float:
	var dot_product: float = p_normal.dot(p_up)
	return !(dot_product >= 0.0 and dot_product < p_slope_max_angle)


func get_virtual_step_offset() -> float:
	return virtual_step_offset


func _is_valid_kinematic_collision(p_collision: KinematicCollision3D) -> bool:
	if p_collision == null:
		return false
	else:
		if !p_collision.get_remainder().length() > 0.00001:
			return false

	return true


func _step_down(p_dss: PhysicsDirectSpaceState3D) -> void:
	# Process step down / fall
	virtual_step_offset = 0.0
	var collided: bool = test_move(global_transform, -(up * step_height))
	if collided:
		var kinematic_collision: KinematicCollision3D = move_and_collide(-(up * anti_bump_factor))
		if kinematic_collision == null or !_is_valid_kinematic_collision(kinematic_collision):
			kinematic_collision = move_and_collide(-(up * (step_height - anti_bump_factor)))
			if kinematic_collision != null and _is_valid_kinematic_collision(kinematic_collision):
				virtual_step_offset = kinematic_collision.get_travel().length() + anti_bump_factor
			else:
				virtual_step_offset = step_height

		if !kinematic_collision:
			is_grounded = false
		else:
			if !test_slope(kinematic_collision.get_normal(), up, slope_max_angle):
				var param: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.new()
				param.from = kinematic_collision.get_position() + (up * step_height)
				param.to = kinematic_collision.get_position() - (up * step_height)
				param.exclude = exclusion_array
				param.collision_mask = collision_mask
				# Is the collision slope relative to world space?
				var ray_result: Dictionary = p_dss.intersect_ray(param)
				if ray_result.is_empty() or !test_slope(ray_result.normal, up, slope_max_angle):
					is_grounded = false

				var valid_floor_param: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.new()
				valid_floor_param.from = global_transform.origin
				valid_floor_param.to = global_transform.origin - (up * step_height * 2.0)
				valid_floor_param.exclude = exclusion_array
				valid_floor_param.collision_mask = collision_mask
				# Is there valid floor beneath me?
				ray_result = p_dss.intersect_ray(valid_floor_param)
				if ray_result.is_empty() or !test_slope(ray_result.normal, up, slope_max_angle):
					is_grounded = false
	else:
		is_grounded = false


func extended_move(p_motion: Vector3, _p_slide_attempts: int) -> Vector3:
	if get_world_3d() == null:
		return Vector3(0.0, 0.0, 0.0)
	var dss: PhysicsDirectSpaceState3D = PhysicsServer3D.space_get_direct_state(get_world_3d().get_space())
	var motion: Vector3 = Vector3(0.0, 0.0, 0.0)
	if dss:
		var shape_owners = get_shape_owners()
		if shape_owners.size() == 1:
			var shape_count: int = shape_owner_get_shape_count(shape_owners[0])
			if shape_count == 1:
				var shape: Shape3D = shape_owner_get_shape(shape_owners[0], 0)
				if shape is CapsuleShape3D:
					if is_grounded:
						# Raise off the ground
						var step_up_kinematic_result: KinematicCollision3D = move_and_collide(up * step_height)
						# Do actual motion
						# FIXME: They changed move_and_slide to have 0 arguments????
						velocity = p_motion
						move_and_slide()
						motion = velocity
						#motion = move_and_slide(
						#	p_motion,
						#	up,
						#	slope_stop_min_velocity,
						#	p_slide_attempts,
						#	slope_max_angle,
						#	infinite_interia
						#)

						# Return to ground
						var step_down_kinematic_result: KinematicCollision3D = null

						if step_up_kinematic_result == null:
							virtual_step_offset = -step_height
							step_down_kinematic_result = move_and_collide(up * -step_height)
						else:
							virtual_step_offset = -step_up_kinematic_result.get_travel().length()
							step_down_kinematic_result = move_and_collide((up * -step_height) + step_up_kinematic_result.get_remainder())

						if step_down_kinematic_result != null and _is_valid_kinematic_collision(step_down_kinematic_result):
							virtual_step_offset += step_down_kinematic_result.get_travel().length()
							motion = (up * -step_height)

							var result_param: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.new()
							result_param.from = step_down_kinematic_result.get_position() + (up * step_height)
							result_param.to = step_down_kinematic_result.get_position() - (up * anti_bump_factor)
							result_param.exclude = exclusion_array
							result_param.collision_mask = collision_mask

							# Use raycast from just above the kinematic result to determine the world normal of the collided surface
							var ray_result = dss.intersect_ray(result_param)

							# Use it to verify whether it is a slope
							if ray_result.is_empty() or !test_slope(ray_result.normal, up, slope_max_angle):
								var slope_limit_fix: int = 2
								while slope_limit_fix > 0:
									if step_down_kinematic_result != null and _is_valid_kinematic_collision(step_down_kinematic_result):
										var step_down_normal: Vector3 = step_down_kinematic_result.get_normal()

										# If you are now on a valid surface, break the loop
										if test_slope(step_down_normal, up, slope_max_angle):
											break
										else:
											#move_and_collide(
											#motion) # Is this needed?

											# Use the step down normal to slide down to the ground
											motion = motion.slide(step_down_normal)
											var slide_down_result: KinematicCollision3D = move_and_collide(motion)

											# Accumulate this back into the visual step offset
											if slide_down_result != null and _is_valid_kinematic_collision(slide_down_result):
												virtual_step_offset += slide_down_result.get_travel().length()
											else:
												virtual_step_offset = 0.0
									else:
										break
									slope_limit_fix -= 1
							else:
								if move_and_collide(motion) == null:
									is_grounded = false
						else:
							_step_down(dss)
					else:
						# FIXME: They changed move_and_slide to have 0 arguments????
						velocity = p_motion
						move_and_slide()
						motion = velocity
						#motion = move_and_slide(
						#	p_motion, up, 0.0, p_slide_attempts, 1.0, infinite_interia
						#)
						if is_on_floor():
							is_grounded = true
							_step_down(dss)
				else:
					printerr("extended_kinematic_body collider must be a capsule")
		else:
			printerr("extended_kinematic_body can only have 1 collider")

	return motion


func _physics_process(_delta):
	var collided: bool = test_move(global_transform, -(up * anti_bump_factor))
	if collided:
		var motion_collision: KinematicCollision3D = move_and_collide(up * -anti_bump_factor)
		if motion_collision:
			is_grounded = true
