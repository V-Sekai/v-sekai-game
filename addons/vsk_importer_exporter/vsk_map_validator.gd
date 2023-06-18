# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_map_validator.gd
# SPDX-License-Identifier: MIT

@tool
extends "res://addons/vsk_importer_exporter/vsk_validator.gd"

const canvas_3d_anchor = preload("res://addons/canvas_plane/canvas_3d_anchor.gd")
const canvas_3d_script = preload("res://addons/canvas_plane/canvas_3d.gd")
const map_validator_const = preload("res://addons/vsk_importer_exporter/vsk_map_validator.gd")

# FIXME: dictionary cannot be const????
var valid_node_whitelist = {
	"AnimatedSprite3D": AnimatedSprite3D,
	"AnimationPlayer": AnimationPlayer,
	"AnimationTree": AnimationTree,
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
	"DirectionalLight3D": DirectionalLight3D,
	"GridMap": GridMap,
	"GeometryInstance3D": GeometryInstance3D,
	"Generic6DOFJoint3D": Generic6DOFJoint3D,
	"GPUParticles3D": GPUParticles3D,
	"HingeJoint3D": HingeJoint3D,
	"Joint3D": Joint3D,
	"Light3D": Light3D,
	"LightmapGI": LightmapGI,
	"Label3D": Label3D,
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
	"ReflectionProbe": ReflectionProbe,
	"RigidBody3D": RigidBody3D,
	"RemoteTransform3D": RemoteTransform3D,
	"SliderJoint3D": SliderJoint3D,
	"Skeleton3D": Skeleton3D,
	"SpotLight3D": SpotLight3D,
	"SpringArm3D": SpringArm3D,
	"Sprite3D": Sprite3D,
	"SpriteBase3D": SpriteBase3D,
	"StaticBody3D": StaticBody3D,
	"VehicleWheel3D": VehicleWheel3D,
	"VisibleOnScreenEnabler3D": VisibleOnScreenEnabler3D,
	"VisibleOnScreenNotifier3D": VisibleOnScreenNotifier3D,
	"VisualInstance3D": VisualInstance3D,
	"VoxelGI": VoxelGI,
	"WorldEnvironment": WorldEnvironment,
	"OccluderInstance3D": OccluderInstance3D,
	"SubViewport": SubViewport,
}

var valid_canvas_node_whitelist = {
	"Node": Node,
	"HBoxContainer": HBoxContainer,
	"VBoxContainer": VBoxContainer,
	"Control": Control,
	"Container": Container,
	"AspectRatioContainer": AspectRatioContainer,
	"TabContainer": TabContainer,
	"Label": Label,
	"RichTextLabel": RichTextLabel,
	"BaseButton": BaseButton,
	"Button": Button,
	"CheckBox": CheckBox,
}

# FIXME: dictionary cannot be const????
var valid_resource_whitelist = {
	"AnimatedTexture": AnimatedTexture,
	"Animation": Animation,
	"AnimationLibrary": AnimationLibrary,
	"AnimationNodeAdd2": AnimationNodeAdd2,
	"AnimationNodeAdd3": AnimationNodeAdd3,
	"AnimationNodeAnimation": AnimationNodeAnimation,
	"AnimationNodeBlend2": AnimationNodeBlend2,
	"AnimationNodeBlend3": AnimationNodeBlend3,
	"AnimationNodeBlendSpace1D": AnimationNodeBlendSpace1D,
	"AnimationNodeBlendSpace2D": AnimationNodeBlendSpace2D,
	"AnimationNodeBlendTree": AnimationNodeBlendTree,
	"AnimationNodeOneShot": AnimationNodeOneShot,
	"AnimationNodeOutput": AnimationNodeOutput,
	"AnimationNodeStateMachine": AnimationNodeStateMachine,
	"AnimationNodeStateMachineTransition": AnimationNodeStateMachineTransition,
	"AnimationNodeTimeScale": AnimationNodeTimeScale,
	"AnimationNodeTimeSeek": AnimationNodeTimeSeek,
	"AnimationNodeTransition": AnimationNodeTransition,
	"ArrayMesh": ArrayMesh,
	"AtlasTexture": AtlasTexture,
	"AudioStreamSample": AudioStreamWAV,  # compatibility. delete me.
	"AudioStreamWAV": AudioStreamWAV,
	"AudioStreamOggVorbis": AudioStreamOggVorbis,
	"BoxMesh": BoxMesh,
	"BoxShape3D": BoxShape3D,
	"CameraAttributesPhysical": CameraAttributesPhysical,
	"CameraAttributesPractical": CameraAttributesPractical,
	"CapsuleMesh": CapsuleMesh,
	"CapsuleShape3D": CapsuleShape3D,
	"ConcavePolygonShape3D": ConcavePolygonShape3D,
	"ConvexPolygonShape3D": ConvexPolygonShape3D,
	"Curve": Curve,
	"Curve2D": Curve2D,
	"Curve3D": Curve3D,
	"CurveTexture": CurveTexture,
	"CurveXYZTexture": CurveXYZTexture,
	"CylinderMesh": CylinderMesh,
	"CylinderShape3D": CylinderShape3D,
	"Environment": Environment,
	"GradientTexture1D": GradientTexture1D,
	"GradientTexture2D": GradientTexture2D,
	"HeightMapShape3D": HeightMapShape3D,
	"ImageTexture": ImageTexture,
	"LightmapGIData": LightmapGIData,
	"Mesh": Mesh,
	"MeshLibrary": MeshLibrary,
	"MeshTexture": MeshTexture,
	"NavigationMesh": NavigationMesh,
	"NoiseTexture2D": NoiseTexture2D,
	"ORMMaterial3D": ORMMaterial3D,
	"PackedScene": PackedScene,
	"PhysicalSkyMaterial": PhysicalSkyMaterial,
	"PanoramaSkyMaterial": PanoramaSkyMaterial,
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
	"StyleBoxEmpty": StyleBoxEmpty,
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
	"VoxelGIData": VoxelGIData,
	"WorldBoundaryShape3D": WorldBoundaryShape3D,
	"Occluder3D": Occluder3D,
	"QuadMesh": QuadMesh,
	"World2D": World2D,
}

var valid_external_path_whitelist = {
	"res://addons/entity_manager/entity.gd": true,
	"res://addons/vsk_entities/vsk_interactable_prop.tscn": true,
	"res://addons/network_manager/network_spawn.gd": true,
	"res://addons/vsk_importer_exporter/vsk_uro_pipeline.gd": true,
	"res://addons/vsk_importer_exporter/vsk_pipeline.gd": true,
	"res://addons/vsk_map/vsk_map_definition.gd": true,
	"res://addons/vsk_map/vsk_map_definition_runtime.gd": true,
	"res://vsk_default/audio/sfx/basketball_drop.wav": true,
	"res://vsk_default/import/beachball/Scene_-_Root.tres": true,
	"res://vsk_default/import/basketball_reexport/Scene_-_Root.tres": true,
	"res://addons/vsk_map/vsk_map_entity_instance_record.gd": true,
	"res://addons/canvas_plane/canvas_3d_anchor.gd": true,
	"res://addons/canvas_plane/canvas_3d.gd": true,
	"res://addons/network_manager/network_identity.gd": true,
	"res://addons/vsk_entities/extensions/test_entity_rpc_table.gd": true,
	"res://addons/network_manager/network_logic.gd": true,
	"res://addons/vsk_entities/extensions/test_entity_simulation_logic.gd": true,
	"res://addons/entity_manager/transform_notification.gd": true,
	"res://addons/entity_manager/hierarchy_component.gd": true,
	"res://addons/vsk_entities/extensions/prop_simulation_logic.gd": true,
	"res://addons/network_manager/network_hierarchy.gd": true,
	"res://addons/network_manager/network_transform.gd": true,
	"res://addons/network_manager/network_model.gd": true,
	"res://addons/network_manager/network_physics.gd": true,
	"res://addons/smoothing/smoothing.gd": true,
}

################
# Map Entities #
################

var entity_script: Script = load("res://addons/entity_manager/entity.gd")
const valid_entity_whitelist = ["res://addons/vsk_entities/vsk_interactable_prop.tscn"]

const valid_resource_script_whitelist = [
	"res://addons/mirror/mirror.gd",
]


static func check_if_script_type_is_valid(p_script: Script, p_node_class: String) -> bool:
	var network_spawn_const = load("res://addons/network_manager/network_spawn.gd")

	var map_definition_runtime = load("res://addons/vsk_map/vsk_map_definition_runtime.gd")
	var map_definition = load("res://addons/vsk_map/vsk_map_definition.gd")
	var vsk_uro_pipeline = load("res://addons/vsk_importer_exporter/vsk_uro_pipeline.gd")

	var entity_identity = load("res://addons/network_manager/network_identity.gd")
	var entity_network_logic = load("res://addons/network_manager/network_logic.gd")
	var entity_transform_notification = load("res://addons/entity_manager/transform_notification.gd")
	var entity_entity = load("res://addons/entity_manager/entity.gd")

	var hierarchy_component = load("res://addons/entity_manager/hierarchy_component.gd")
	var network_hierarchy = load("res://addons/network_manager/network_hierarchy.gd")
	var network_transform = load("res://addons/network_manager/network_transform.gd")
	var network_model = load("res://addons/network_manager/network_model.gd")
	var network_physics = load("res://addons/network_manager/network_physics.gd")
	var smoothing = load("res://addons/smoothing/smoothing.gd")

	var script_type_table = {
		network_spawn_const: ["Position3D", "Marker3D", "Node3D"],
		map_definition: ["Position3D", "Marker3D", "Node3D"],
		map_definition_runtime: ["Position3D", "Marker3D", "Node3D"],
		vsk_uro_pipeline: ["Node"],
		canvas_3d_anchor: ["Node3D"],
		canvas_3d_script: ["Node3D"],
		entity_identity: ["Node"],
		entity_network_logic: ["Node"],
		entity_transform_notification: ["Node3D"],
		entity_entity: ["Node3D"],
		hierarchy_component: ["Node"],
		network_hierarchy: ["Node"],
		network_transform: ["Node"],
		network_model: ["Node"],
		network_physics: ["Node"],
		smoothing: ["Node3D"],
	}
	if script_type_table.get(p_script) != null:
		var valid_classes: Array = script_type_table.get(p_script)
		for class_str in valid_classes:
			if class_str == p_node_class:
				return true

	push_warning("Validator: Script failed check " + str(p_script) + "/" + str(p_script.resource_path) + " node_class " + p_node_class)
	return false


func is_script_valid_for_root(p_script: Script, p_node_class: String):
	if p_script == null:
		return true

	var map_definition = load("res://addons/vsk_map/vsk_map_definition.gd")
	var map_definition_runtime = load("res://addons/vsk_map/vsk_map_definition_runtime.gd")
	var valid_root_script_whitelist = [map_definition, map_definition_runtime]
	if valid_root_script_whitelist.find(p_script) != -1:
		return map_validator_const.check_if_script_type_is_valid(p_script, p_node_class)

	push_warning("Validator: Unknown root script " + str(p_script) + "/" + str(p_script.resource_path) + " node_class " + p_node_class)
	return false


func is_script_valid_for_children(p_script: Script, p_node_class: String):
	if p_script == null:
		return true
	var network_spawn_const = load("res://addons/network_manager/network_spawn.gd")
	var vsk_uro_pipeline = load("res://addons/vsk_importer_exporter/vsk_uro_pipeline.gd")

	var entity_identity = load("res://addons/network_manager/network_identity.gd")
	var entity_rpc_table = load("res://addons/vsk_entities/extensions/test_entity_rpc_table.gd")
	var entity_network_logic = load("res://addons/network_manager/network_logic.gd")
	var entity_test_simulation = load("res://addons/vsk_entities/extensions/test_entity_simulation_logic.gd")
	var entity_transform_notification = load("res://addons/entity_manager/transform_notification.gd")
	var entity_entity = load("res://addons/entity_manager/entity.gd")

	var hierarchy_component = load("res://addons/entity_manager/hierarchy_component.gd")
	var prop_simulation_logic = load("res://addons/vsk_entities/extensions/prop_simulation_logic.gd")
	var network_hierarchy = load("res://addons/network_manager/network_hierarchy.gd")
	var network_transform = load("res://addons/network_manager/network_transform.gd")
	var network_model = load("res://addons/network_manager/network_model.gd")
	var network_physics = load("res://addons/network_manager/network_physics.gd")
	var smoothing = load("res://addons/smoothing/smoothing.gd")

	var valid_children_script_whitelist = [
		network_spawn_const,
		vsk_uro_pipeline,
		canvas_3d_script,
		canvas_3d_anchor,
		entity_identity,
		entity_rpc_table,
		entity_network_logic,
		entity_test_simulation,
		entity_transform_notification,
		entity_entity,
		hierarchy_component,
		prop_simulation_logic,
		network_hierarchy,
		network_transform,
		network_model,
		network_physics,
		smoothing,
	]
	if valid_children_script_whitelist.find(p_script) != -1:
		return map_validator_const.check_if_script_type_is_valid(p_script, p_node_class)

	push_warning("Validator: Unknown children script " + str(p_script) + "/" + str(p_script.resource_path) + " node_class " + p_node_class)
	return false


func is_script_valid_for_resource(p_script: Script):
	if p_script == null:
		return true

	if valid_resource_script_whitelist.find(p_script) != -1:
		return true
	else:
		push_warning("Validator: Unknown resource script %s" % [str(p_script) + "/" + str(p_script.resource_path)])
		return false


func is_node_type_valid(p_node: Node, p_child_of_canvas: bool) -> bool:
	if is_node_type_string_valid(p_node.get_class(), p_child_of_canvas):
		if !map_validator_const.is_editor_only(p_node):
			return true

	push_warning("Validator: Unknown node type " + str(p_node.get_class()) + " (canvas " + str(p_child_of_canvas) + ")")
	return false


func is_node_type_string_valid(p_class_str: String, p_child_of_canvas: bool) -> bool:
	if p_child_of_canvas:
		return valid_canvas_node_whitelist.has(p_class_str)
	else:
		return valid_node_whitelist.has(p_class_str)

	push_warning("Validator: Unknown node type string " + p_class_str + " (canvas " + str(p_child_of_canvas) + ")")
	return false


func is_resource_type_valid(p_resource: Resource) -> bool:
	if valid_resource_whitelist.has(p_resource.get_class()):
		return true

	push_warning("Validator: Unknown resource type " + str(p_resource.get_class()))
	return false


func is_path_an_entity(p_packed_scene_path: String) -> bool:
	if valid_entity_whitelist.find(p_packed_scene_path) != -1:
		return true
	else:
		return false


func is_valid_entity_script(p_script: Script) -> bool:
	if p_script == entity_script:
		return true

	push_warning("Validator: Unknown entity script " + str(p_script) + "/" + str(p_script.resource_path) + " not " + str(entity_script) + "/" + str(entity_script.resource_path))
	return false


func is_valid_canvas_3d(p_script: Script, p_node_class: String) -> bool:
	if p_script == canvas_3d_script and p_node_class == "Node3D":
		return true

	return false


func is_valid_canvas_3d_anchor(p_script: Script, p_node_class: String) -> bool:
	if p_script == canvas_3d_anchor and p_node_class == "Node3D":
		return true

	return false


func validate_value_track(p_subnames: String, p_node_class: String):
	match p_node_class:
		"MeshInstance3D":
			return map_validator_const.check_basic_node_3d_value_targets(p_subnames)
		"Node3D":
			return map_validator_const.check_basic_node_3d_value_targets(p_subnames)
		"DirectionalLight":
			return map_validator_const.check_basic_node_3d_value_targets(p_subnames)
		"OmniLight":
			return map_validator_const.check_basic_node_3d_value_targets(p_subnames)
		"SpotLight":
			return map_validator_const.check_basic_node_3d_value_targets(p_subnames)
		"Camera3D":
			return map_validator_const.check_basic_node_3d_value_targets(p_subnames)
		"GPUParticles3D":
			return map_validator_const.check_basic_node_3d_value_targets(p_subnames)
		"CPUParticles":
			return map_validator_const.check_basic_node_3d_value_targets(p_subnames)
		_:
			return false


func get_name() -> String:
	return "MapValidator"
