# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_avatar_validator.gd
# SPDX-License-Identifier: MIT

@tool
extends VSKValidator
class_name VSKAvatarValidator

var valid_node_allow_list = {
	"AnimatedSprite3D": AnimatedSprite3D,
	"Area3D": Area3D,
	"AudioStreamPlayer": AudioStreamPlayer,
	"AudioStreamPlayer3D": AudioStreamPlayer3D,
	"BoneAttachment3D": BoneAttachment3D,
	"Camera3D": Camera3D,
	"CharacterBody3D": CharacterBody3D,
	"CollisionObject3D": CollisionObject3D,
	"CollisionShape3D": CollisionShape3D,
	"ConeTwistJoint3D": ConeTwistJoint3D,
	"CPUParticles3D": CPUParticles3D,
	"GridMap": GridMap,
	"GeometryInstance3D": GeometryInstance3D,
	"Generic6DOFJoint3D": Generic6DOFJoint3D,
	"GPUParticles3D": GPUParticles3D,
	"HingeJoint3D": HingeJoint3D,
	"Joint3D": Joint3D,
	"Light3D": Light3D,
	"MeshInstance3D": MeshInstance3D,
	"MultiMeshInstance3D": MultiMeshInstance3D,
	"NavigationAgent3D": NavigationAgent3D,
	"NavigationRegion3D": NavigationRegion3D,
	"Node": Node,
	"Node3D": Node3D,
	"OmniLight3D": OmniLight3D,
	"Path3D": Path3D,
	"PathFollow3D": PathFollow3D,
	"PhysicsBody3D": PhysicsBody3D,
	"PinJoint3D": PinJoint3D,
	"Marker3D": Marker3D,
	"Position3D": Marker3D,
	"RayCast3D": RayCast3D,
	"RigidBody3D": RigidBody3D,
	"RemoteTransform3D": RemoteTransform3D,
	"SliderJoint3D": SliderJoint3D,
	"Skeleton3D": Skeleton3D,
	"SpotLight3D": SpotLight3D,
	"SpringArm3D": SpringArm3D,
	"Sprite3D": Sprite3D,
	"SpriteBase3D": SpriteBase3D,
	"StaticBody3D": StaticBody3D,
	"VisualInstance3D": VisualInstance3D,
	"WorldEnvironment": WorldEnvironment,
}

var valid_resource_allow_list = {
	# "CameraAttributesPractical": CameraAttributesPractical, # Don't allow the old style camera attribute.
	"CameraAttributesPhysical": CameraAttributesPhysical,
	"AnimatedTexture": AnimatedTexture,
	"ArrayMesh": ArrayMesh,
	"AtlasTexture": AtlasTexture,
	"BoxMesh": BoxMesh,
	"BoxShape3D": BoxShape3D,
	"CapsuleMesh": CapsuleMesh,
	"CapsuleShape3D": CapsuleShape3D,
	"ConcavePolygonShape3D": ConcavePolygonShape3D,
	"ConvexPolygonShape3D": ConvexPolygonShape3D,
	"CurveTexture": CurveTexture,
	"CurveXYZTexture": CurveXYZTexture,
	"CylinderMesh": CylinderMesh,
	"CylinderShape3D": CylinderShape3D,
	# "Environment": Environment, # Don't allow custom environments for performance optimization.
	"GradientTexture1D": GradientTexture1D,
	"GradientTexture2D": GradientTexture2D,
	"HeightMapShape3D": HeightMapShape3D,
	"ImageTexture": ImageTexture,
	"Mesh": Mesh,
	"MeshLibrary": MeshLibrary,
	"MeshTexture": MeshTexture,
	"NoiseTexture2D": NoiseTexture2D,
	"ORMMaterial3D": ORMMaterial3D,
	"PackedScene": PackedScene,
	"PanoramaSkyMaterial": PanoramaSkyMaterial,
	"PhysicalSkyMaterial": PhysicalSkyMaterial,
	"ProceduralSkyMaterial": ProceduralSkyMaterial,
	"PhysicsMaterial": PhysicsMaterial,
	"PlaneMesh": PlaneMesh,
	"PointMesh": PointMesh,
	"PrimitiveMesh": PrimitiveMesh,
	"PrismMesh": PrismMesh,
	"Resource": Resource,
	"Shader": Shader,
	"ShaderMaterial": ShaderMaterial,
	"Shape3D": Shape3D,
	"Skin": Skin,
	"Sky": Sky,
	"StandardMaterial3D": StandardMaterial3D,
	"SphereMesh": SphereMesh,
	"SphereShape3D": SphereShape3D,
	"CompressedTexture2D": CompressedTexture2D,
	"PortableCompressedTexture2D": PortableCompressedTexture2D,
	"Cubemap": Cubemap,
	"CubemapArray": CubemapArray,
	"Texture2D": Texture2D,
	"Texture2DArray": Texture2DArray,
	"Texture3D": Texture3D,
	"TextureLayered": TextureLayered,
	"Image": Image,
	"ViewportTexture": ViewportTexture,
	"WorldBoundaryShape3D": WorldBoundaryShape3D
}

var valid_external_path_allow_list = {
	"res://vsk_default/textures/groups_logo_no_bg.png": true,
	"res://addons/vsk_menu/main_menu/title_screen.tscn": true,
	"res://addons/vsk_avatar/vsk_avatar_definition.gd": true,
	"res://addons/vsk_avatar/vsk_avatar_definition_runtime.gd": true,
	"res://addons/vsk_avatar/avatar_physics.gd": true,
	"res://addons/vsk_avatar/physics/avatar_collidergroup.gd": true,
	"res://addons/vsk_avatar/physics/avatar_springbone.gd": true,
	"res://addons/vsk_importer_exporter/vsk_uro_pipeline.gd": true,
	"res://addons/vsk_importer_exporter/vsk_pipeline.gd": true,
	"res://vsk_default/audio/sfx/basketball_drop.wav": true,
}

const valid_scene_allow_list = []
#const valid_root_script_allow_list = [VSKAvatar3D]
const valid_children_script_allow_list: Array = []
const valid_resource_script_allow_list: Array = []


static func check_if_script_type_is_valid(_script: Script, _node_class: String) -> bool:
	# FIXME: dictionary cannot be const????
	#var script_type_table = {
	#	avatar_physics_const: ["Marker3D", "Node3D"],
	#	avatar_definition_const: ["Marker3D", "Node3D"],
	#	avatar_definition_runtime_const: ["Marker3D", "Node3D"],
	#	vsk_pipeline_const: ["Node"]
	#}
	#if typeof(script_type_table.get(p_script)) != TYPE_NIL:
	#	var valid_classes: Array = script_type_table.get(p_script)
	#	for class_str in valid_classes:
	#		if class_str == p_node_class:
	#			return true

	return false


func is_script_valid_for_root(p_script: Script, _node_class: String):
	if p_script == null:
		return true

	#if valid_root_script_allow_list.find(p_script) != -1:
	#	return vsk_avatar_validator_const.check_if_script_type_is_valid(p_script, p_node_class)

	return false


func is_script_valid_for_children(p_script: Script, p_node_class: String):
	if p_script == null:
		return true

	if valid_children_script_allow_list.find(p_script) != -1:
		return check_if_script_type_is_valid(p_script, p_node_class)

	return false


func is_script_valid_for_resource(p_script: Script):
	if p_script == null:
		return true

	if valid_resource_script_allow_list.find(p_script) != -1:
		return true
	else:
		return false


func is_node_type_valid(p_node: Node, p_child_of_canvas: bool) -> bool:
	if is_node_type_string_valid(p_node.get_class(), p_child_of_canvas):
		if !is_editor_only(p_node):
			return true
	return false


func is_node_type_string_valid(p_class_str: String, p_child_of_canvas: bool) -> bool:
	if p_child_of_canvas:
		return false
	else:
		return valid_node_allow_list.has(p_class_str)


func is_resource_type_valid(p_resource: Resource) -> bool:
	if valid_resource_allow_list.has(p_resource.get_class()):
		return true
	return false


func get_name() -> String:
	return "AvatarValidator"
