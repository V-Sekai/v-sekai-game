@tool
extends Node3D

const vignette_tunneling_const = preload("./vignette_tunneling.gd")
const vignette_cage_const = preload("./vignette_cage.gd")

var vignette_tunneling: MeshInstance3D
var vignette_cage: MeshInstance3D

@export_node_path("XROrigin3D") var xr_origin: NodePath = NodePath("../..")
@export_node_path("XRCamera3D") var xr_camera: NodePath = NodePath("..")
@onready var xr_origin_node: XROrigin3D = get_node(xr_origin)
@onready var xr_camera_node: XRCamera3D = get_node(xr_camera)

@export var enable_tunnel: bool = true
@export var enable_cage: bool = false

@export var cage_color: Color = Color.BLACK
@export var fade_fov: float = 30
@export_range(0.0, 1.0) var preview_vignette: float = 0
@export var running_average_interval: float = 0.1
@export var fadeout_time: float = 0.1
@export var fadeout_delay: float = 0.1

@export var vignette_move_thresh: Vector2 = Vector2(0.0, 2.0)
@export var move_vignette_fov_deg: float = 20.0
@export var vignette_rotate_thresh_deg: Vector2 = Vector2(0.0, 1.0)
@export var rotate_vignette_fov_deg: float = 20.0
const iris_fov_limit = 30.0  # Can't go smaller than this.


func _init():
	vignette_tunneling = vignette_tunneling_const.new()
	vignette_cage = vignette_cage_const.new()


# Called when the node enters the scene tree for the first time.
func _ready():
	vignette_cage.name = "VignetteCage"
	vignette_cage.visible = false
	vignette_tunneling.name = "VignetteTunneling"
	vignette_tunneling.visible = false
	add_child(vignette_cage)
	add_child(vignette_tunneling)
	vignette_cage.owner = self
	vignette_tunneling.owner = self
	if false:  # Debug child nodes in Scene hierarchy:
		self.scene_file_path = "res://test.tscn"
		self.owner.set_editable_instance(self, true)


var running_origin_xforms: Array[Transform3D] = []
var running_camera_xforms: Array[Transform3D] = []
var running_timestamps: Array[float] = []
var virtual_timestamp: float = 0
var current_fadeout_move_amount: float = 0
var current_fadeout_move_delay: float = 0
var current_fadeout_rotate_amount: float = 0
var current_fadeout_rotate_delay: float = 0


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float):
	current_fadeout_move_delay -= delta
	if current_fadeout_move_delay <= 0:
		current_fadeout_move_amount = max(0.0, current_fadeout_move_amount - delta / fadeout_time)
	current_fadeout_rotate_delay -= delta
	if current_fadeout_rotate_delay <= 0:
		current_fadeout_rotate_amount = max(0.0, current_fadeout_rotate_amount - delta / fadeout_time)

	virtual_timestamp += delta
	var count_to_remove: int = 0
	for rt in running_timestamps:
		if rt < virtual_timestamp - running_average_interval:
			count_to_remove += 1
	count_to_remove = min(count_to_remove, len(running_timestamps) - 2)
	if count_to_remove > 0 and len(running_timestamps) - count_to_remove > 0:
		count_to_remove = len(running_timestamps) - count_to_remove
		running_timestamps.resize(count_to_remove)
		running_origin_xforms.resize(count_to_remove)
		running_camera_xforms.resize(count_to_remove)

	running_timestamps.insert(0, virtual_timestamp)
	running_origin_xforms.insert(0, xr_origin_node.global_transform)
	running_camera_xforms.insert(0, xr_camera_node.transform)

	if len(running_timestamps) > 1:
		var camera_origin_diff: Vector3 = running_camera_xforms[0].origin - running_camera_xforms[-1].origin
		var camera_basis_diff: Basis = running_camera_xforms[-1].basis.inverse() * running_camera_xforms[0].basis
		camera_origin_diff.y = 0
		var origin_origin_diff: Vector3 = xr_origin_node.transform.basis * (running_origin_xforms[0].origin - running_origin_xforms[-1].origin)
		var origin_basis_diff: Basis = running_origin_xforms[-1].basis.inverse() * running_origin_xforms[0].basis
		origin_origin_diff.y = 0

		var speed: float = max(0.0, origin_origin_diff.length() - camera_origin_diff.length())
		var camera_ang_speed: float = 0
		if not camera_basis_diff.is_equal_approx(Quaternion.IDENTITY):
			camera_ang_speed = Quaternion.IDENTITY.angle_to(camera_basis_diff.get_rotation_quaternion())
		var origin_ang_speed: float = 0
		if not origin_basis_diff.is_equal_approx(Quaternion.IDENTITY):
			origin_ang_speed = Quaternion.IDENTITY.angle_to(origin_basis_diff.get_rotation_quaternion())
		var ang_speed_deg: float = max(0.0, origin_ang_speed - camera_ang_speed) * 180.0 / PI
		#print(Plane(origin_origin_diff.length(), camera_origin_diff.length(), origin_ang_speed, camera_ang_speed))
		#print(str(ang_speed_deg)+","+str( speed))

		var move_vignette_amount: float = max(preview_vignette, smoothstep(vignette_move_thresh.x, vignette_move_thresh.y, speed))
		if move_vignette_amount >= current_fadeout_move_amount:
			current_fadeout_move_delay = fadeout_delay
			current_fadeout_move_amount = move_vignette_amount
		move_vignette_amount = max(current_fadeout_move_amount, move_vignette_amount)

		var rotate_vignette_amount: float = smoothstep(vignette_rotate_thresh_deg.x, vignette_rotate_thresh_deg.y, ang_speed_deg)
		if rotate_vignette_amount >= current_fadeout_rotate_amount:
			current_fadeout_rotate_delay = fadeout_delay
			current_fadeout_rotate_amount = rotate_vignette_amount
		rotate_vignette_amount = max(current_fadeout_rotate_amount, rotate_vignette_amount)

		var vignette_alpha: float = clamp(max(move_vignette_amount, rotate_vignette_amount) * 5.0, 0.0, 1.0)
		var new_tunnel_visible: bool = vignette_alpha > 0.001 and enable_tunnel and (xr_camera_node.get_viewport().use_xr or preview_vignette > 0)
		if new_tunnel_visible != vignette_tunneling.visible:
			vignette_tunneling.visible = new_tunnel_visible
		var new_cage_visible: bool = vignette_alpha > 0.001 and enable_cage and (xr_camera_node.get_viewport().use_xr or preview_vignette > 0)
		if new_cage_visible != vignette_cage.visible:
			vignette_cage.visible = new_cage_visible

		var calculated_move_fov: float = lerpf(0, move_vignette_fov_deg, move_vignette_amount)
		var calculated_rotate_fov: float = lerpf(0, rotate_vignette_fov_deg, rotate_vignette_amount)
		var calculated_fov = max(iris_fov_limit, xr_camera_node.fov - max(calculated_move_fov, calculated_rotate_fov))
		var calculated_alpha: float = vignette_alpha

		vignette_tunneling.current_fov = calculated_fov
		vignette_tunneling.vignette_alpha = calculated_alpha
		vignette_tunneling.current_fade_fov = fade_fov

		vignette_cage.current_fov = calculated_fov
		vignette_cage.vignette_alpha = calculated_alpha
		vignette_cage.cage_color = cage_color
		vignette_cage.current_fade_fov = fade_fov
		vignette_cage.update_transforms(xr_origin_node, xr_camera_node)
