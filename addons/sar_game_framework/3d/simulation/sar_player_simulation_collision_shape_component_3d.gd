@tool
extends Node
class_name SarSimulationComponentCollisionShape3D
## SarSimulationComponentCollisionShape3D is responsible for instantiating and
## destroy a CollisionShape3D node with a specific shape and offset
## onto an entity's PhysicsBody3D node when the simulation activates and
## deactivates.

# Stored reference the collision shape created.
var _collision_shape: CollisionShape3D = null

# When the simulation is ready, go to the simulation interface
# and create the collision shape.
func _ready() -> void:
	if not Engine.is_editor_hint():
		if simulation:
			var entity_interface: SarGameEntityInterfaceVessel3D = simulation.get_game_entity_interface() as SarGameEntityInterfaceVessel3D
			if entity_interface:
				var character_body_3d: CharacterBody3D = entity_interface.get_movement_component().character_body_3d
				if character_body_3d:
					_collision_shape = CollisionShape3D.new()
					_collision_shape.shape = shape
					_collision_shape.position = offset
					_collision_shape.set_name("SimulationCollisionShape3D")
					character_body_3d.add_child(_collision_shape)

# If we're shutting down, clean up what we created.
func _on_simulation_shutdown() -> void:
	if not Engine.is_editor_hint():
		if simulation:
			if _collision_shape:
				_collision_shape.queue_free()
				_collision_shape.get_parent().remove_child(_collision_shape)
				_collision_shape = null

###

## Reference to the root simulation.
@export var simulation: SarSimulationVessel3D = null

## The shape resource we want to instantiate for the CollisionShape3D we're
## going to create.
@export var shape: Shape3D = null

## The offset of the CollisionShape3D we're going to create.
@export var offset: Vector3 = Vector3():
	set(p_offset):
		offset = p_offset
		if _collision_shape:
			_collision_shape.position = offset
