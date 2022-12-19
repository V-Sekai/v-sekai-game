extends "movement_controller.gd"

const godot_math_extensions_const = preload("res://addons/math_util/math_funcs.gd")

const camera_holder_const = preload("camera_holder.gd")
@export_node_path var camera_holder: NodePath = NodePath()

# Settings for controlling movement
@export var walk_speed: float = 1.5
@export var sprint_speed: float = 4.5

@export var acceleration: float = 16.0
@export var deacceleration: float = 16.0

# Index into the color table for multiplayer
var multiplayer_color_id: int = -1

# For interpolation (needs a lot more functionality though, study network
# snapshot interpolation, hermite interpolation, ect.)
var last_movement : PackedVector3Array = [Vector3(), Vector3()] 
var last_rotation : PackedFloat64Array = [0, 0] 

# Updates the purely visual camera bobbing effect for first-person mode
func _update_bobbing(p_velocity_length: float) -> void:
	var camera_holder_node: Node3D = get_node_or_null(camera_holder)
	if camera_holder_node:
		camera_holder_node.update_bobbing(p_velocity_length)

# Calculates the correct rotation for a movement vector relative to the 
# camera.
func _process_rotation(p_movement_vector: Vector2) -> void:
	var camera_holder_node: Node3D = get_node_or_null(camera_holder)
	if !camera_holder_node:
			return
	
	var direction_vector: Vector2 = Vector2()
	if camera_holder_node.view_mode == camera_holder_const.FIRST_PERSON:
		direction_vector = Vector2(0.0, 1.0)
	else:
		direction_vector = p_movement_vector
	
	var direction_distance: float = direction_vector.normalized().length()
	
	if direction_distance > 0.0:
		var camera_pivot_node: Node3D = camera_holder_node.get_node_or_null(
			camera_holder_node.camera_pivot)
		if !camera_pivot_node:
			return
			
		var camera_basis: Basis = camera_pivot_node.global_transform.basis
		
		var direction: Vector3 = \
		(camera_basis[0] * direction_vector.x) - \
		(camera_basis[2] * direction_vector.y).normalized()
		
		var rotation_difference = godot_math_extensions_const.shortest_angle_distance(
			y_rotation,
			Vector2(direction.z, direction.x).angle()
		)
		
		var clamped_rotation_difference: float = 0.0
		clamped_rotation_difference = rotation_difference

		y_rotation = cubic_interpolate_angle_in_time(y_rotation, y_rotation + clamped_rotation_difference, last_rotation[0],
		y_rotation + clamped_rotation_difference, 1.0, last_rotation[1], 0, get_process_delta_time()) 
		
		# Limit rotation range
		while (y_rotation > PI):
			y_rotation -= TAU
		while (y_rotation < -PI):
			y_rotation += TAU
		
		last_rotation[0] = y_rotation
		last_rotation[1] = -get_process_delta_time()

# Calculates kinetic movement for an input vector
func _process_movement(p_delta: float, p_movement_vector: Vector2, p_is_sprinting: bool) -> void:
	var applied_gravity: float = -gravity if !is_on_floor() else 0.0
	
	var applied_gravity_vector: Vector3 = Vector3(
		applied_gravity,
		applied_gravity,
		applied_gravity
	) * up_direction
	
	var speed_modifier: float = sprint_speed if p_is_sprinting else walk_speed
	var movement_length: float = p_movement_vector.normalized().length()
	
	var is_moving: bool = movement_length > 0.0
	
	var camera_holder_node: Node3D = get_node_or_null(camera_holder)
	if !camera_holder_node:
			return
			
	var camera_pivot_node: Node3D = camera_holder_node.get_node(camera_holder_node.camera_pivot)
	
	var target_velocity: Vector3
	if camera_holder_node.view_mode == camera_holder_const.FIRST_PERSON:
		target_velocity = ((camera_pivot_node.global_transform.basis.x * p_movement_vector.x)
		+ (camera_pivot_node.global_transform.basis.z * -p_movement_vector.y)) * speed_modifier
	else:
		target_velocity = Basis().rotated(Vector3.UP, y_rotation).z * \
		p_movement_vector.normalized().length() * \
		speed_modifier
	
	var speed: float = deacceleration
	if(is_moving):
		speed = acceleration
		
	var horizontal_velocity: Vector3 = (
		velocity * (Vector3.ONE - up_direction)
	)
	
	horizontal_velocity = horizontal_velocity.cubic_interpolate_in_time(target_velocity, last_movement[0], target_velocity, 1.0, last_movement[1].x, 0,
	speed * p_delta)
	last_movement[0] = target_velocity
	last_movement[1] = Vector3(-speed * p_delta, -speed * p_delta, -speed * p_delta)
	
	velocity = (
		applied_gravity_vector + \
		(horizontal_velocity * (Vector3.ONE - up_direction))
	)
	
	kinematic_movement(p_delta)
			
# This function is called by snapshot interpolation node to provide the actual update
func network_transform_update(p_origin: Vector3, p_y_rotation: float) -> void:
	transform.origin = p_origin
	y_rotation = p_y_rotation
		
func _physics_process(p_delta: float) -> void:
	if !multiplayer.has_multiplayer_peer() or is_multiplayer_authority():
		# Get the movement vector
		var movement_vector: Vector2 = Vector2(
			Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
			Input.get_action_strength("move_forwards") - Input.get_action_strength("move_backwards")
		) if !get_node("/root/GameManager").is_movement_locked() else Vector2()
		
		# Calculate the player's rotation
		_process_rotation(movement_vector)
		
		# Calculate the player's movement
		_process_movement(p_delta, movement_vector, InputMap.has_action("sprint") and Input.is_action_pressed("sprint"))
		
		# Update the first-person camera bobbing
		_update_bobbing((velocity * (Vector3.ONE - up_direction)).length())
		
	$CharacterModelHolder.transform.basis = Basis().rotated(Vector3.UP, y_rotation)
	
func _ready() -> void:
	super._ready()
	
	collision_layer = 0
	if multiplayer.has_multiplayer_peer() and !is_multiplayer_authority():
		set_collision_layer_value(2, false)
		set_collision_layer_value(3, true)
		# Remove game menu for non-authoritive players
		$IngameGUI.queue_free()
		$IngameGUI.get_parent().remove_child($IngameGUI)
	else:
		set_collision_layer_value(2, true)
		set_collision_layer_value(3, false)
			
	if multiplayer_color_id >= 0:
		var color_material: Material = MultiplayerColorTable.get_material_for_index(multiplayer_color_id)
		assert(color_material)
		
		$CharacterModelHolder.assign_multiplayer_material(color_material)
		if !multiplayer.has_multiplayer_peer() or is_multiplayer_authority():
			$IngameGUI.assign_peer_color(color_material.albedo_color)
	
	$CharacterModelHolder.transform.basis = Basis().rotated(Vector3.UP, y_rotation)
