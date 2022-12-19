extends Node3D

var is_controllable: bool = false

const MOUSE_SENSITIVITY: float = 0.001
var mouse_velocity: Vector2 = Vector2()

enum {
	FIRST_PERSON,
	THIRD_PERSON
}

@export_node_path(Node3D) var camera_pivot: NodePath = NodePath()
@export_node_path(SpringArm3D) var camera_spring_arm: NodePath = NodePath()
@export_node_path(Node3D) var camera_bobbing: NodePath = NodePath()
@export_node_path(Node3D) var third_person_model: NodePath = NodePath()

@export_enum("First-Person", "Third-Person") var view_mode: int = THIRD_PERSON:
	set(p_view_mode):
		view_mode = p_view_mode

@export_flags_3d_physics var collision_mask: int = 0

# Camera height
@export var camera_height_first_person: float = 1.45
@export var camera_height_third_person: float = 1.3

# Smoothing
@export var camera_smooth_time: float = 0.1

# Pitch
@export_range(0.0, 90.0) var pitch_min_limit: float = -40.0
@export_range(0.0, 90.0) var pitch_max_limit: float = 40.0

# Distance
@export var distance_min: float = 1.0
@export var distance_max: float = 2.5

var distance: float = 1.5
var interpolated_distance: float = 1.5
var distance_velocity: float = 0.0

# Bobbing
@export var minimum_sprint_velocity: float = 3.0
@export var bobbing_v_amount: float = 0.01
@export var bobbing_h_amount: float = 0.0
@export var walk_bobbing_rate: float = 10.0
@export var sprint_bobbing_rate: float = 22.0

func zoom_in():
	distance -= 0.1
	if(distance < distance_min):
		distance = distance_min
	
func zoom_out():
	distance += 0.1
	if(distance > distance_max):
		distance = distance_max
		
func update_bobbing(p_velocity_length: float) -> void:
	var camera_bobbing_node: Node3D = get_node(
		camera_bobbing)
		
	# Only apply bobbing when in first-person mode
	match view_mode:
		FIRST_PERSON:
			camera_bobbing_node.bobbing_v_amount = bobbing_v_amount * p_velocity_length
			camera_bobbing_node.bobbing_h_amount = bobbing_h_amount * p_velocity_length
		THIRD_PERSON:
			camera_bobbing_node.bobbing_v_amount = 0.0
			camera_bobbing_node.bobbing_h_amount = 0.0
		
	if p_velocity_length > 0.0:
		if p_velocity_length > minimum_sprint_velocity:
			camera_bobbing_node.bobbing_speed = sprint_bobbing_rate * clamp(0.0, 1.0, p_velocity_length)
		else:
			camera_bobbing_node.bobbing_speed = walk_bobbing_rate * clamp(0.0, 1.0, p_velocity_length)
	else:
		camera_bobbing_node.step_timer = 0.0
		
func _update_model_visibility(p_view_mode: int) -> void:
	var third_person_model_node: Node3D = get_node(third_person_model)
	match p_view_mode:
		FIRST_PERSON:
			third_person_model_node.hide()
		THIRD_PERSON:
			third_person_model_node.show()
		
func _update_distance(p_delta: float) -> void:
	var distance_result: Dictionary = get_node("/root/GodotMathExtension").smooth_damp_scaler(
		interpolated_distance,
		distance,
		distance_velocity,
		0.5,
		INF,
		p_delta)
	
	distance_velocity = distance_result["velocity"]
	interpolated_distance = distance_result["interpolation"]
	
	match view_mode:
		THIRD_PERSON:
			get_node(camera_spring_arm).spring_length = interpolated_distance
		FIRST_PERSON:
			get_node(camera_spring_arm).spring_length = 0.0
			
func _update_transform() -> void:
	var camera_spring_arm_node: SpringArm3D = get_node(camera_spring_arm)
	var camera_pivot_node: Node3D = get_node(camera_pivot)
	
	match view_mode:
		THIRD_PERSON:
			camera_pivot_node.transform.origin = Vector3(0.0, camera_height_first_person, 0.0)
			camera_spring_arm_node.collision_mask = collision_mask
			
			camera_spring_arm_node.rotation.x = clamp(
				camera_spring_arm_node.rotation.x, deg_to_rad(pitch_min_limit), deg_to_rad(pitch_max_limit))
		FIRST_PERSON:
			camera_pivot_node.transform.origin = Vector3(0.0, camera_height_third_person, 0.0)
			camera_spring_arm_node.collision_mask = 0
			
			camera_spring_arm_node.rotation.x = clamp(
				camera_spring_arm_node.rotation.x, deg_to_rad(-90), deg_to_rad(90))
	
	_update_model_visibility(view_mode)
			
func set_y_rotation(p_rotation: float) -> void:
	get_node(camera_spring_arm).transform.basis = Basis().rotated(Vector3.UP, p_rotation)
			
func _input(p_event: InputEvent) -> void:
	if is_controllable and !get_node("/root/GameManager").is_movement_locked():
		if InputMap.has_action("zoom_in") and p_event.is_action_pressed("zoom_in"):
			zoom_in()
		elif InputMap.has_action("zoom_out") and p_event.is_action_pressed("zoom_out"):
			zoom_out()
		elif InputMap.has_action("toggle_camera_mode") and p_event.is_action_pressed("toggle_camera_mode"):
			view_mode = THIRD_PERSON if view_mode == FIRST_PERSON else FIRST_PERSON
		elif p_event is InputEventMouseMotion:
			mouse_velocity += p_event.relative

func _ready() -> void:
	if !multiplayer.has_multiplayer_peer() or is_multiplayer_authority():
		if !get_node("/root/GameManager").ingame_menu_visible:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		is_controllable = true
	else:
		queue_free()

func _physics_process(p_delta: float) -> void:
	var camera_spring_arm_node: SpringArm3D = get_node(camera_spring_arm)
	var camera_pivot_node: Node3D = get_node(camera_pivot)
	
	camera_pivot_node.rotate_y(-mouse_velocity.x * MOUSE_SENSITIVITY)
	camera_spring_arm_node.rotate_x(-mouse_velocity.y * MOUSE_SENSITIVITY)
	
	_update_transform()
	mouse_velocity = Vector2(0.0, 0.0)

	_update_distance(p_delta)
