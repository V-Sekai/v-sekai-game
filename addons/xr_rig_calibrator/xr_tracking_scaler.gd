@tool
class_name XRTrackingScaler
extends Node3D

@export var reference_skel: Skeleton3D
@export var target_skel: Skeleton3D
@export var xr_rig_root: Node3D
@export_range(0.01, 100.0, 0.1) var scale_mult: float = 1.0

#@export var avatar_rig_root: Node3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func get_armspan(skel: Skeleton3D) -> float:
	var arm_dist: float = skel.get_bone_global_rest(skel.find_bone("LeftHand")).origin.distance_to(skel.get_bone_global_rest(skel.find_bone("RightHand")).origin)
	if arm_dist < 0.01:
		arm_dist = 0.01
	return arm_dist

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	if reference_skel == null or target_skel == null or xr_rig_root == null:
		return
	var target_armspan := target_skel.global_basis.get_scale().length() / sqrt(3) * get_armspan(target_skel)
	var reference_armspan := get_armspan(reference_skel)
	var armspan_scale_factor: float = clampf(scale_mult * (target_armspan / reference_armspan), 0.01, 100.0)
	xr_rig_root.global_basis = xr_rig_root.global_basis.orthonormalized() * Basis.from_scale(global_basis.get_scale()) * armspan_scale_factor

	
	
	
