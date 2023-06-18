@tool
extends MeshInstance3D

var vignette_cage_mat_inst: ShaderMaterial

@export var cage_color: Color = Color.WHITE:
	set(x):
		cage_color = x
		vignette_cage_mat_inst.set_shader_parameter(&"cage_color", cage_color)

@export_range(0.0, 1.0) var vignette_alpha: float = 1.0:
	set(x):
		vignette_alpha = x
		vignette_cage_mat_inst.set_shader_parameter(&"vignette_alpha", vignette_alpha)

@export_range(0.0, 30.0, 0.1) var current_fade_fov: float = 6.5:
	set(x):
		current_fade_fov = x
		vignette_cage_mat_inst.set_shader_parameter(&"current_fade_fov", current_fade_fov)

@export_exp_easing("attenuation") var current_fov: float = 100.0:
	set(x):
		current_fov = clamp(x, 0.0, 160.0)
		vignette_cage_mat_inst.set_shader_parameter(&"current_fov", current_fov)


func _init():
	var cage_mesh_const: Mesh = load("res://addons/xr_vignette/cage.obj") as Mesh
	var vignette_cage_mat_const: ShaderMaterial = load("res://addons/xr_vignette/vignette_cage_mat.tres") as ShaderMaterial

	vignette_cage_mat_inst = vignette_cage_mat_const.duplicate() as ShaderMaterial
	mesh = cage_mesh_const
	transform = Transform3D.IDENTITY
	material_override = vignette_cage_mat_inst
	top_level = true


func update_transforms(xr_origin_node: Node3D, xr_camera_node: Node3D):
	self.top_level = true
	var pos_vector = xr_camera_node.global_transform.origin.round() - (xr_camera_node.transform.origin - xr_camera_node.transform.origin.floor())
	pos_vector.y = xr_camera_node.global_transform.origin.y
	self.transform = Transform3D(xr_origin_node.global_transform.basis, pos_vector)
	vignette_cage_mat_inst.set_shader_parameter(&"floor_offset", xr_camera_node.transform.origin.y)  #  - pos_vector.y)
