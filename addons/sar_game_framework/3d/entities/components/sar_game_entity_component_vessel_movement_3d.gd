@tool
extends SarGameEntityComponent
class_name SarGameEntityComponentVesselMovement3D

# Set this to customize the integration process
var _custom_integration_method: Callable = Callable()

# Set this to customize the ground testing process
var _custom_is_grounded_method: Callable = Callable()

## Called before applying integration.
func _pre_movement(p_delta: float, p_velocity: Vector3) -> void:
	# Emit the signal to indicate the movement is about to begin.
	pre_movement.emit(p_delta, p_velocity)

## Called after applying integration.
func _post_movement(p_delta: float, p_velocity: Vector3) -> void:
	# Emit the signal to indicate the movement has
	# finished for this frame.
	post_movement.emit(p_delta, p_velocity)

# Called after called _post_movement
func _movement_complete(p_delta: float) -> void:
	movement_complete.emit(p_delta)
	

# Checks to see if the movement_complete signal is actually hooked
# up to a game entity.
func _get_configuration_warnings() -> PackedStringArray:
	var strings: PackedStringArray = super._get_configuration_warnings()

	var is_connected_to_game_entity_3d: bool = false
	var connections: Array = movement_complete.get_connections()
	for conn in connections:
		var callable: Callable = conn["callable"]
		if callable.get_object() is SarGameEntity3D:
			is_connected_to_game_entity_3d = true
			break
		
	if not is_connected_to_game_entity_3d:
		strings.append("movement_complete signal is not connected to a SarGameEntity3D.")
		
	return strings

###

## Emitted before movement integration.
signal pre_movement(p_delta: float, p_velocity: Vector3)

## Emitted after movement integration.
signal post_movement(p_delta: float, p_velocity: Vector3)

## Emitted as an additional signal after the post_movement signal has been emitted since components,
## may attempt to do additional integration after the main movement integration step.
signal movement_complete(p_delta: float)

func assign_custom_integration_method(p_integration: Callable) -> void:
	_custom_integration_method = p_integration
	
func assign_custom_is_grounded_method(p_is_grounded: Callable) -> void:
	_custom_is_grounded_method = p_is_grounded

func get_physics_body() -> PhysicsBody3D:
	return null

func get_up_direction() -> Vector3:
	return Vector3.UP
	
func get_horizontal_plane() -> Vector3:
	return Vector3(1.0, 0.0, 1.0)
	
func get_vertical_plane() -> Vector3:
	return Vector3(0.0, 1.0, 0.0)
	
func get_physics_position() -> Vector3:
	return Vector3()
	
func get_physics_transform() -> Transform3D:
	return Transform3D()
	
func set_velocity(_velocity: Vector3) -> void:
	pass
	
func get_velocity() -> Vector3:
	return Vector3()
	
func set_physics_position(_position: Vector3) -> void:
	pass

func is_grounded() -> bool:
	return false
