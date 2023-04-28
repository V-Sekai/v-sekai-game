@tool
extends MeshInstance3D

var iris_color_mat_inst: ShaderMaterial
var iris_depth_mat_inst: ShaderMaterial

@export_range(3.0, 10.0, 0.01, "or_lesser", "or_greater") var iris_distance: float = 5.0:
	set(x):
		iris_distance = x
		iris_color_mat_inst.set_shader_parameter(&"iris_distance", iris_distance)
		iris_depth_mat_inst.set_shader_parameter(&"iris_distance", iris_distance)

@export_range(0.0, 1.0) var vignette_alpha: float = 1.0:
	set(x):
		vignette_alpha = x
		iris_color_mat_inst.set_shader_parameter(&"vignette_alpha", vignette_alpha)

@export_range(0.0, 30.0, 0.1) var current_fade_fov: float = 6.5:
	set(x):
		current_fade_fov = x
		iris_color_mat_inst.set_shader_parameter(&"current_fade_fov", current_fade_fov)
		iris_depth_mat_inst.set_shader_parameter(&"current_fade_fov", current_fade_fov)

@export_exp_easing("attenuation") var current_fov: float = 100.0:
	set(x):
		current_fov = clamp(x, 0.0, 160.0)
		iris_color_mat_inst.set_shader_parameter(&"current_fov", current_fov)
		iris_depth_mat_inst.set_shader_parameter(&"current_fov", current_fov)


func _init():
	var iris_mesh_const: Mesh = load("res://addons/xr_vignette/iris_extruded.obj") as Mesh
	var iris_color_mat_const: ShaderMaterial = load("res://addons/xr_vignette/iris_gradient_mat.tres") as ShaderMaterial
	var iris_depth_mat_const: ShaderMaterial = load("res://addons/xr_vignette/iris_depth_mat.tres") as ShaderMaterial

	iris_color_mat_inst = iris_color_mat_const.duplicate() as ShaderMaterial
	iris_depth_mat_inst = iris_depth_mat_const.duplicate() as ShaderMaterial
	mesh = iris_mesh_const
	transform = Transform3D.IDENTITY
	material_override = iris_color_mat_inst
